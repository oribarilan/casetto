import Foundation
import Observation

/// The audio path. The app uses an AVPlayer implementation; tests use a fake.
@MainActor
public protocol AudioEngine: AnyObject {
    /// Called with (position, duration) as playback advances.
    var onTime: ((TimeInterval, TimeInterval?) -> Void)? { get set }
    var onEnd: (() -> Void)? { get set }
    var onFailure: ((any Error) -> Void)? { get set }
    /// Called with the loaded URL and the chapters embedded in its audio file, when it has any.
    var onChapters: ((URL, [Chapter]) -> Void)? { get set }

    func load(_ url: URL, at position: TimeInterval)
    func play(rate: Double)
    func pause()
    func seek(to position: TimeInterval)
    /// What the engine heard between two media times, oldest first. Empty when it has nothing.
    func loudness(from start: TimeInterval, to end: TimeInterval) -> [Loudness]
    /// Evens out loud and quiet voices from now on, including in episodes loaded later.
    func setVoiceBoost(_ isOn: Bool)
}

public enum SleepTimer: Equatable, Sendable {
    case duration(Duration)
    case endOfEpisode
}

/// Plays Queue item 1, saves progress, applies the played rule, and runs the sleep timer.
@MainActor @Observable
public final class Player {
    public static let skipForwardSeconds: TimeInterval = 30
    public static let skipBackSeconds: TimeInterval = 15
    static let progressSaveInterval: TimeInterval = 5

    public private(set) var episode: EpisodeInfo?
    public private(set) var show: ShowInfo?
    public private(set) var isPlaying = false
    public private(set) var position: TimeInterval = 0
    public private(set) var duration: TimeInterval?
    public private(set) var speed: PlaybackSpeed = .normal
    /// From the audio file, or else from the show notes. Empty when the episode has none.
    public private(set) var chapters: [Chapter] = []
    public private(set) var voiceBoost = false
    public private(set) var sleepTimer: SleepTimer?
    /// When a duration timer pauses playback. Nil with no timer or the end-of-episode timer.
    public private(set) var sleepTimerEndsAt: Date?
    public private(set) var errorMessage: String?
    /// When the last Queue episode played to its end with nothing after it. Not set when the
    /// end-of-episode sleep timer stopped playback.
    public private(set) var queueRanOutAt: Date?

    private let library: Library
    private let engine: any AudioEngine
    private let sleep: @Sendable (Duration) async throws -> Void
    private let localFile: (EpisodeKey, URL) -> URL?
    private var lastSavedPosition: TimeInterval = 0
    /// What the engine loaded: the downloaded file, or else the stream.
    public private(set) var loadedURL: URL?
    private var sleepTask: Task<Void, Never>?
    /// Set by a pause; a seek or another episode clears it, which turns off Back a Beat.
    private var pausedInPlace = false

    public init(
        library: Library,
        engine: any AudioEngine,
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
        localFile: @escaping (EpisodeKey, URL) -> URL? = { _, _ in nil }
    ) {
        self.library = library
        self.engine = engine
        self.sleep = sleep
        self.localFile = localFile
        engine.onTime = { [weak self] position, duration in self?.timeChanged(position, duration) }
        engine.onEnd = { [weak self] in Task { await self?.episodeEnded() } }
        engine.onFailure = { [weak self] error in self?.failed(error) }
        engine.onChapters = { [weak self] url, chapters in
            guard let self, url == self.loadedURL, !chapters.isEmpty else { return }
            self.chapters = chapters
        }
    }

    // MARK: Commands

    /// Moves the episode to the top of the Queue and plays it from its saved position.
    public func play(_ key: EpisodeKey) async throws {
        try await saveProgress()
        try await library.moveToTop(key)
        try await start(key)
    }

    /// Resumes, or starts Queue item 1 when nothing is loaded.
    public func resume() async throws {
        if episode != nil {
            if pausedInPlace { backABeat() }
            engine.play(rate: speed.value)
            isPlaying = true
        } else if let first = try await library.playableQueue().first {
            try await start(first)
        }
    }

    public func pause() async throws {
        engine.pause()
        isPlaying = false
        pausedInPlace = episode != nil
        try await saveProgress()
    }

    public func togglePlayPause() async throws {
        if isPlaying { try await pause() } else { try await resume() }
    }

    public var chapterProgress: ChapterProgress {
        ChapterProgress(chapters: chapters, position: position, duration: duration)
    }

    public var currentChapter: Chapter? {
        chapterProgress.current.map { chapters[$0] }
    }

    /// Stops and forgets the episode if it's the one loaded, for when it's deleted. Nothing else starts.
    public func unload(_ key: EpisodeKey) {
        guard episode?.key == key else { return }
        engine.pause()
        isPlaying = false
        pausedInPlace = false
        episode = nil
        show = nil
        chapters = []
        position = 0
        duration = nil
        loadedURL = nil
    }

    /// Moves to the chapter's start and keeps playing or paused.
    public func jump(to chapter: Chapter) {
        seek(to: chapter.start)
    }

    public func skipForward() { seek(to: position + Self.skipForwardSeconds) }
    public func skipBack() { seek(to: position - Self.skipBackSeconds) }

    public func seek(to target: TimeInterval) {
        let upper = duration ?? .greatestFiniteMagnitude
        position = min(max(target, 0), upper)
        pausedInPlace = false
        engine.seek(to: position)
    }

    private func backABeat() {
        let readings = engine.loudness(from: position - BackABeat.farthest, to: position - BackABeat.nearest)
        let point = BackABeat.resumePoint(pausedAt: position, readings: readings)
        if point != position { seek(to: point) }
        pausedInPlace = false
    }

    public func setSpeed(_ newSpeed: PlaybackSpeed) {
        speed = newSpeed
        if isPlaying { engine.play(rate: speed.value) }
    }

    /// Re-reads the effective speed after the global speed or a show override changed.
    public func reloadSpeed() async throws {
        guard let episode else { return }
        setSpeed(try await library.effectiveSpeed(for: episode.showKey))
    }

    /// Re-reads the effective voice boost after the global setting or a show's choice changed.
    public func reloadVoiceBoost() async throws {
        guard let episode else { return }
        setVoiceBoost(try await library.effectiveVoiceBoost(for: episode.showKey))
    }

    private func setVoiceBoost(_ isOn: Bool) {
        voiceBoost = isOn
        engine.setVoiceBoost(isOn)
    }

    /// Saves the current position. The app also calls this on interruption and when going to the background.
    public func saveProgress() async throws {
        guard let episode else { return }
        try await library.setProgress(episode.key, to: position)
        lastSavedPosition = position
    }

    public func setSleepTimer(_ timer: SleepTimer?) {
        sleepTask?.cancel()
        sleepTask = nil
        sleepTimer = timer
        sleepTimerEndsAt = nil
        guard case .duration(let length) = timer else { return }
        sleepTimerEndsAt = .now + TimeInterval(length.components.seconds)
        sleepTask = Task { [sleep] in
            do { try await sleep(length) } catch { return }
            try? await self.sleepTimerFired()
        }
    }

    // MARK: Engine events

    private func start(_ key: EpisodeKey) async throws {
        guard let info = try await library.episode(key) else { return }
        try await library.recordPlayStart(key)
        episode = info
        show = try await library.show(info.showKey)
        errorMessage = nil
        pausedInPlace = false
        position = try await library.progress(of: key)
        lastSavedPosition = position
        duration = info.duration
        speed = try await library.effectiveSpeed(for: info.showKey)
        chapters = ShowNotesChapters.parse(info.summary ?? "", duration: info.duration)
        setVoiceBoost(try await library.effectiveVoiceBoost(for: info.showKey))
        let url = localFile(info.key, info.audioURL) ?? info.audioURL
        loadedURL = url
        engine.load(url, at: position)
        engine.play(rate: speed.value)
        isPlaying = true
    }

    private func timeChanged(_ newPosition: TimeInterval, _ newDuration: TimeInterval?) {
        position = newPosition
        if let newDuration { duration = newDuration }
        if abs(position - lastSavedPosition) >= Self.progressSaveInterval {
            Task { try? await saveProgress() }
        }
    }

    func episodeEnded() async {
        guard let finished = episode else { return }
        isPlaying = false
        if let duration { position = duration }
        try? await saveProgress()
        // Reaching the end always counts as played, even when the duration was never known.
        try? await library.markPlayed(finished.key)
        episode = nil
        if sleepTimer == .endOfEpisode {
            sleepTimer = nil
            return
        }
        if let next = try? await library.playableQueue().first {
            try? await start(next)
        } else {
            queueRanOutAt = .now
        }
    }

    private func sleepTimerFired() async throws {
        sleepTimer = nil
        sleepTimerEndsAt = nil
        sleepTask = nil
        try await pause()
    }

    private func failed(_ error: any Error) {
        isPlaying = false
        let offline = (error as? URLError)?.code == .notConnectedToInternet
        errorMessage = offline
            ? "You're offline, and this one isn't downloaded yet."
            : "This episode wouldn't play. Its audio may have moved."
    }
}
