import AVFoundation
import BackgroundTasks
import CasterrCore
import NowPlaying
import Observation
import os

/// Owns the app's long-lived objects and reacts to audio-session and lifecycle events.
@MainActor @Observable
final class AppModel {
    let library: Library
    let feeds: FeedService
    let player: Player
    let downloader: Downloader
    /// Bumped after every change to stored data, so views know to reload.
    private(set) var revision = 0
    @ObservationIgnored private var nowPlaying: MediaSession<NowPlayingBridge>?
    @ObservationIgnored private var eventTasks: [Task<Void, Never>] = []
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    static let refreshTaskID = "casterr.refresh"
    private static let log = Logger(subsystem: "com.oribarilan.Casterr", category: "refresh")

    init(inMemory: Bool = false) throws {
        library = try Library.open(inMemory: inMemory)
        feeds = FeedService(library: library)
        let store = try DownloadStore.standard()
        player = Player(library: library, engine: AVPlayerEngine(), localFile: { key, audioURL in
            store.localFile(for: key, audioURL: audioURL)
        })
        downloader = Downloader(store: store)
        if ProcessInfo.processInfo.arguments.contains("-fastClock") {
            // UI tests: one second passes as one day, so Inbox expiry can be tested.
            let start = Date.now
            Task { [library] in await library.useClock { start + Date.now.timeIntervalSince(start) * 86_400 } }
        }
        startNowPlaying()
        observeAudioSession()
        observeDownloadsAndPlayer()
    }

    func appBecameActive() async {
        await refresh()
    }

    func refresh() async {
        try? await feeds.refreshAll()
        revision += 1
        await syncDownloads()
    }

    /// Runs when iOS grants a background refresh.
    func backgroundRefresh() async {
        Self.log.info("Background refresh started")
        await scheduleBackgroundRefresh()
        await refresh()
    }

    /// Asks iOS for a background refresh in an hour or later. iOS decides when.
    func scheduleBackgroundRefresh() async {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskID)
        request.earliestBeginDate = .now.addingTimeInterval(3600)
        do {
            try await BGTaskScheduler.shared.submitTaskRequest(request)
        } catch {
            Self.log.error("Couldn't schedule a background refresh: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Makes the files match the top of the Queue. Syncs run one at a time, so a download never starts twice.
    func syncDownloads() async {
        let previous = syncTask
        let task = Task {
            await previous?.value
            await performSync()
        }
        syncTask = task
        await task.value
    }

    private func performSync() async {
        let queue = (try? await library.queue()) ?? []
        let keep = (try? await library.downloadCount()) ?? 0
        let running = await downloader.running()
        let plan = DownloadPlan.make(queue: queue, keep: keep, files: downloader.store.stems(), running: Set(running.keys))
        for key in plan.cancel { running[key]?.cancel() }
        for stem in plan.delete { downloader.store.delete(stem: stem) }
        for key in plan.start {
            if let episode = try? await library.episode(key) { downloader.start(key, from: episode.audioURL) }
        }
        if !plan.delete.isEmpty { revision += 1 }
    }

    func isDownloaded(_ episode: EpisodeInfo) -> Bool {
        downloader.store.localFile(for: episode.key, audioURL: episode.audioURL) != nil
    }

    /// Runs a change and tells views to reload. Returns the error message, if any.
    @discardableResult
    func change(_ work: () async throws -> Void) async -> String? {
        defer { Task { await syncDownloads() } }
        defer { revision += 1 }
        do {
            try await work()
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    /// Episodes for the keys, in order. Keys without feed data are left out.
    func episodes(_ keys: [EpisodeKey]) async -> [EpisodeInfo] {
        var episodes: [EpisodeInfo] = []
        for key in keys {
            if let episode = try? await library.episode(key) { episodes.append(episode) }
        }
        return episodes
    }

    func moves(of keys: [EpisodeKey]) async -> [EpisodeKey: LastMove] {
        var moves: [EpisodeKey: LastMove] = [:]
        for key in keys {
            moves[key] = try? await library.lastMove(of: key)
        }
        return moves
    }

    func appWentToBackground() async {
        await scheduleBackgroundRefresh()
        try? await player.saveProgress()
    }

    /// Reloads views when a download lands, and syncs when the Player's episode changes,
    /// because a finished episode leaves the Queue and its file goes.
    private func observeDownloadsAndPlayer() {
        let player = player
        eventTasks += [
            Task { [weak self] in
                for await _ in NotificationCenter.default.notifications(named: Downloader.didSave) {
                    self?.revision += 1
                }
            },
            Task { [weak self] in
                for await _ in Observations({ player.episode?.key }) {
                    await self?.syncDownloads()
                }
            },
        ]
    }

    private func startNowPlaying() {
        let session = MediaSession(NowPlayingBridge(player: player))
        nowPlaying = session
        Task { try? await session.requestToBecomeSystemPrimary() }
    }

    /// Pauses for calls and other interruptions, resumes when the system says to,
    /// and pauses when headphones disconnect.
    private func observeAudioSession() {
        let center = NotificationCenter.default
        let player = player
        eventTasks = [
            Task {
                for await note in center.notifications(named: AVAudioSession.didBecomeInactiveNotification) {
                    let context = note.userInfo?[AVAudioSession.deactivationContextKey] as? AVAudioSession.DeactivationContext
                    if context?.source == .system { try? await player.pause() }
                }
            },
            Task {
                for await note in center.notifications(named: AVAudioSession.resumptionRecommendationNotification) {
                    let context = note.userInfo?[AVAudioSession.resumptionContextKey] as? AVAudioSession.ResumptionContext
                    if context?.recommendation == .shouldResume { try? await player.resume() }
                }
            },
            Task {
                for await note in center.notifications(named: AVAudioSession.routeChangeNotification) {
                    guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                          AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { continue }
                    try? await player.pause()
                }
            },
        ]
    }
}
