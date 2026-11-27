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
    /// `exact` lands on the target itself, slower on long streams; otherwise the engine may land nearby.
    func seek(to position: TimeInterval, exact: Bool)
    /// What the engine heard between two media times, oldest first. Empty when it has nothing.
    func loudness(from start: TimeInterval, to end: TimeInterval) -> [Loudness]
    /// Evens out loud and quiet voices from now on, including in episodes loaded later.
    func setVoiceBoost(_ isOn: Bool)
}

public enum SleepTimer: Equatable, Sendable {
    case duration(Duration)
    /// Pauses when the next chapter starts, or at the episode's end in the last chapter.
    case endOfChapter
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
    /// Where the chapter timer pauses: the next chapter's start. Nil in the last chapter, which ends with the episode.
    private var chapterTimerEnd: TimeInterval?
    /// Where playing audio paused, kept for Back a Beat. Set only by a pause of playing audio, so a second pause
    /// changes nothing and a late time report can't move it; a seek or another episode clears it.
    private var pausePoint: TimeInterval?

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
            self.anchorChapterTimer()
        }
    }

    // MARK: Commands

    /// Moves the episode to the top of the Queue and plays it from its saved position.
    public func play(_ key: EpisodeKey) async throws {
        try await saveProgress()
        try await library.moveToTop(key)
        try await start(key)
    }

    /// Loads the episode paused at its saved position, as the listener left it, without playing it. Loading isn't
    /// a play: the first press of play is, and Back a Beat stays off because nothing paused here.
    public func load(_ key: EpisodeKey) async throws {
        try await prepare(key)
        isPlaying = false
    }

    /// Resumes, or starts Queue item 1 when nothing is loaded.
    public func resume() async throws {
        if let episode {
            try await library.recordPlayStart(episode.key)
            if let pausePoint { backABeat(from: pausePoint) }
            engine.play(rate: speed.value)
            isPlaying = true
        } else if let first = try await library.playableQueue().first {
            try await start(first)
        }
    }

    public func pause() async throws {
        let wasPlaying = isPlaying
        engine.pause()
        isPlaying = false
        if wasPlaying, episode != nil { pausePoint = position }
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
        pausePoint = nil
        episode = nil
        show = nil
        chapters = []
        position = 0
        duration = nil
        loadedURL = nil
    }

    /// Moves to the chapter's start, exactly (a quick seek can land seconds into it), and keeps playing or paused.
    public func jump(to chapter: Chapter) {
        seek(to: chapter.start, exact: true)
    }

    public func skipForward() { seek(to: position + Self.skipForwardSeconds) }
    public func skipBack() { seek(to: position - Self.skipBackSeconds) }

    public func seek(to target: TimeInterval, exact: Bool = false) {
        let upper = duration ?? .greatestFiniteMagnitude
        position = min(max(target, 0), upper)
        pausePoint = nil
        engine.seek(to: position, exact: exact)
        // After a seek, "this chapter" is the one playback landed in.
        anchorChapterTimer()
    }

    private func backABeat(from pausedAt: TimeInterval) {
        let readings = engine.loudness(from: pausedAt - BackABeat.lookBack, to: pausedAt)
        let point = BackABeat.resumePoint(pausedAt: pausedAt, readings: readings)
        if point != pausedAt { seek(to: point, exact: true) }
        pausePoint = nil
    }

    /// How loud the audio is over the last quarter second, and over the same quarter second a tenth of a second
    /// earlier, each 0 to 1 against the loudest moment of the last 3 seconds. Quarter seconds follow words rather
    /// than every syllable; the slight lag makes the mini player's two bars ripple instead of moving as one.
    /// Both are 0 while paused.
    public func levels() -> (now: Double, before: Double) {
        guard isPlaying else { return (0, 0) }
        let readings = engine.loudness(from: position - 5, to: position + 5)
        guard let latest = readings.last?.time,
            let peak = readings.filter({ $0.time > latest - 3 }).map(\.level).max(), peak > 0
        else { return (0, 0) }
        func mean(_ from: TimeInterval, _ to: TimeInterval) -> Double {
            let slice = readings.filter { $0.time > latest - from && $0.time <= latest - to }.map(\.level)
            return slice.isEmpty ? 0 : Double(min(1, slice.reduce(0, +) / Float(slice.count) / peak))
        }
        return (mean(0.25, -1), mean(0.35, 0.1))
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
        anchorChapterTimer()
        guard case .duration(let length) = timer else { return }
        sleepTimerEndsAt = .now + TimeInterval(length.components.seconds)
        sleepTask = Task { [sleep] in
            do { try await sleep(length) } catch { return }
            try? await self.sleepTimerFired()
        }
    }

    private func anchorChapterTimer() {
        chapterTimerEnd = sleepTimer == .endOfChapter ? chapters.first { $0.start > position }?.start : nil
    }

    // MARK: Engine events

    private func start(_ key: EpisodeKey) async throws {
        guard try await prepare(key) else { return }
        try await library.recordPlayStart(key)
        engine.play(rate: speed.value)
        isPlaying = true
    }

    /// Loads the episode at its saved position with its show's speed, chapters, and voice boost, ready to play.
    @discardableResult
    private func prepare(_ key: EpisodeKey) async throws -> Bool {
        guard let info = try await library.episode(key) else { return false }
        episode = info
        show = try await library.show(info.showKey)
        errorMessage = nil
        pausePoint = nil
        position = try await library.progress(of: key)
        lastSavedPosition = position
        duration = info.duration
        speed = try await library.effectiveSpeed(for: info.showKey)
        chapters = ShowNotesChapters.parse(info.summary ?? "", duration: info.duration)
        setVoiceBoost(try await library.effectiveVoiceBoost(for: info.showKey))
        let url = localFile(info.key, info.audioURL) ?? info.audioURL
        loadedURL = url
        engine.load(url, at: position)
        return true
    }

    private func timeChanged(_ newPosition: TimeInterval, _ newDuration: TimeInterval?) {
        position = newPosition
        if let newDuration { duration = newDuration }
        if let end = chapterTimerEnd, position >= end {
            chapterTimerEnd = nil
            Task { try? await sleepTimerFired() }
        }
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
        if sleepTimer == .endOfEpisode || sleepTimer == .endOfChapter {
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
        errorMessage =
            offline
            ? "You're offline, and this one isn't downloaded yet."
            : "This episode wouldn't play. Its audio may have moved."
    }
}
