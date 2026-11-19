import Foundation
import Observation

/// The audio path. The app uses an AVPlayer implementation; tests use a fake.
@MainActor
public protocol AudioEngine: AnyObject {
    /// Called with (position, duration) as playback advances.
    var onTime: ((TimeInterval, TimeInterval?) -> Void)? { get set }
    var onEnd: (() -> Void)? { get set }
    var onFailure: ((any Error) -> Void)? { get set }

    func load(_ url: URL, at position: TimeInterval)
    func play(rate: Double)
    func pause()
    func seek(to position: TimeInterval)
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
    public private(set) var sleepTimer: SleepTimer?
    public private(set) var errorMessage: String?

    private let library: Library
    private let engine: any AudioEngine
    private let sleep: @Sendable (Duration) async throws -> Void
    private let localFile: (EpisodeKey, URL) -> URL?
    private var lastSavedPosition: TimeInterval = 0
    private var sleepTask: Task<Void, Never>?

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
            engine.play(rate: speed.value)
            isPlaying = true
        } else if let first = try await library.queue().first {
            try await start(first)
        }
    }

    public func pause() async throws {
        engine.pause()
        isPlaying = false
        try await saveProgress()
    }

    public func togglePlayPause() async throws {
        if isPlaying { try await pause() } else { try await resume() }
    }

    public func skipForward() { seek(to: position + Self.skipForwardSeconds) }
    public func skipBack() { seek(to: position - Self.skipBackSeconds) }

    public func seek(to target: TimeInterval) {
        let upper = duration ?? .greatestFiniteMagnitude
        position = min(max(target, 0), upper)
        engine.seek(to: position)
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
        guard case .duration(let length) = timer else { return }
        sleepTask = Task { [sleep] in
            do { try await sleep(length) } catch { return }
            try? await self.sleepTimerFired()
        }
    }

    // MARK: Engine events

    private func start(_ key: EpisodeKey) async throws {
        guard let info = try await library.episode(key) else { return }
        episode = info
        show = try await library.show(info.showKey)
        errorMessage = nil
        position = try await library.progress(of: key)
        lastSavedPosition = position
        duration = info.duration
        speed = try await library.effectiveSpeed(for: info.showKey)
        engine.load(localFile(info.key, info.audioURL) ?? info.audioURL, at: position)
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
        if let next = try? await library.queue().first {
            try? await start(next)
        }
    }

    private func sleepTimerFired() async throws {
        sleepTimer = nil
        sleepTask = nil
        try await pause()
    }

    private func failed(_ error: any Error) {
        isPlaying = false
        let offline = (error as? URLError)?.code == .notConnectedToInternet
        errorMessage = offline
            ? "You're offline. This episode can't be streamed."
            : "This episode couldn't be played."
    }
}
