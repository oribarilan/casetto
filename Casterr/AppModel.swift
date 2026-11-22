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
    /// Files shared to Casterr. Nil only if Application Support can't be created.
    let sharedStore: SharedStore?
    @ObservationIgnored private(set) lazy var sharedInbox = SharedInbox(model: self, store: sharedStore)
    let directory = AppleDirectory()
    var tab: AppTab = .queue
    /// Each tab's navigation lives here, so it survives the tab content being rebuilt
    /// (iOS rebuilds it when the bottom bar appears) and a toast can open the Inbox.
    var queuePath: [Route] = []
    var showsPath: [Route] = []
    var bookmarksPath: [Route] = []
    /// Cassy's current toast.
    var cassyToast: CassyMessage?
    /// True while feeds refresh, so the Queue can show Cassy loading.
    private(set) var refreshing = false
    /// The bookmark the toast confirms.
    var lastBookmark: RecentBookmark?
    /// Bumped after every change to stored data, so views know to reload.
    private(set) var revision = 0 {
        didSet { Task { await loadUpNext() } }
    }
    /// The first Queue episode, for the bar shown while nothing is playing.
    private(set) var upNext: UpNext?
    @ObservationIgnored private var nowPlaying: MediaSession<NowPlayingBridge>?
    @ObservationIgnored private var eventTasks: [Task<Void, Never>] = []
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    /// The one model for the phone and the car screen. UI tests launch with an empty in-memory library.
    static let shared = try! AppModel(inMemory: ProcessInfo.processInfo.arguments.contains("-uiTesting"))
    static let refreshTaskID = "casterr.refresh"
    private static let log = Logger(subsystem: "sh.oribi.Casterr", category: "refresh")

    init(inMemory: Bool = false) throws {
        library = try Library.open(inMemory: inMemory)
        feeds = FeedService(library: library)
        let store = try DownloadStore.standard()
        let shared = try? SharedStore.standard()
        sharedStore = shared
        player = Player(library: library, engine: AVPlayerEngine(), localFile: { key, audioURL in
            shared?.file(for: audioURL) ?? store.localFile(for: key, audioURL: audioURL)
        })
        downloader = Downloader(store: store)
        if ProcessInfo.processInfo.arguments.contains("-fastClock") {
            // UI tests: one second passes as one day, so Inbox expiry can be tested.
            let start = Date.now
            Task { [library] in await library.useClock { start + Date.now.timeIntervalSince(start) * 86_400 } }
        }
        if ProcessInfo.processInfo.arguments.contains("-ruleThresholdOne") {
            // UI tests: one expiry is enough for the Ignored card.
            Task { [library] in await library.useRuleThresholds(.init(autoQueue: 1, ignored: 1)) }
        }
        startNowPlaying()
        observeAudioSession()
        observeDownloadsAndPlayer()
    }

    func appBecameActive() async {
        await sharedInbox.pickUp()
        await refresh()
    }

    /// Refreshes, then, when `announce` is on and something moved, Cassy sums it up. Tapping her opens the Inbox.
    func refresh(announce: Bool = true) async {
        refreshing = true
        defer { refreshing = false }
        let summary = try? await feeds.refreshAll()
        try? await library.mergeDuplicates()
        revision += 1
        if announce, let line = summary?.sentence {
            cassyToast = CassyMessage(job: .success, text: line) { [weak self] in
                self?.tab = .queue
                self?.queuePath = [.inbox]
            }
        }
        await syncDownloads()
    }

    /// Runs when iOS grants a background refresh.
    func backgroundRefresh() async {
        Self.log.info("Background refresh started")
        await scheduleBackgroundRefresh()
        await refresh(announce: false)
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
        // Shared files are already on the device.
        let queue = ((try? await library.playableQueue()) ?? []).filter { $0.rawValue.hasPrefix(ShowKey.shared.rawValue + "|") == false }
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

    /// Saves the current moment. Playback is untouched.
    func bookmark() async {
        guard let episode = player.episode,
              let id = try? await library.addBookmark(episode, showTitle: player.show?.title ?? "", at: player.position)
        else { return }
        lastBookmark = RecentBookmark(id: id, position: player.position)
        revision += 1
    }

    /// Reads the first Queue episode and how far into it the listener is.
    func loadUpNext() async {
        guard let key = try? await library.playableQueue().first, let episode = try? await library.episode(key) else {
            upNext = nil
            return
        }
        let show = try? await library.show(episode.showKey)
        let progress = (try? await library.progress(of: key)) ?? 0
        upNext = UpNext(episode: episode, showTitle: show?.title ?? "", artworkURL: show?.artworkURL, progress: progress)
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

    /// Reloads views when a download lands, syncs when the Player's episode changes, offers more when the Queue runs out,
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
                    await self?.loadUpNext()
                }
            },
            // Playback failed or the episode can't stream offline: Cassy says so in her toast.
            Task { [weak self] in
                for await message in Observations({ player.errorMessage }) {
                    if let message { self?.cassyToast = CassyMessage(job: .error, text: message) }
                }
            },
            // The Queue ran out: Cassy offers to look for more.
            Task { [weak self] in
                for await ranOut in Observations({ player.queueRanOutAt }) where ranOut != nil {
                    self?.cassyToast = CassyMessage(job: .asleep, text: "That's the lot. Want me to check for new episodes?",
                                                    actionTitle: "Check Now") { [weak self] in await self?.refresh() }
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

struct RecentBookmark: Equatable {
    let id: UUID
    let position: TimeInterval
}

/// The first Queue episode while nothing is playing: new, or partly played.
struct UpNext: Equatable {
    let episode: EpisodeInfo
    let showTitle: String
    let artworkURL: URL?
    let progress: TimeInterval

    /// "Up next · from your Queue" for a new episode, "Continue · 25 min left" for a started one.
    var caption: String {
        guard progress > 0 else { return "Up next · from your Queue" }
        guard let duration = episode.duration, duration > progress else { return "Continue" }
        return "Continue · \(max(1, Int((duration - progress) / 60))) min left"
    }
}
