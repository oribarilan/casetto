import AVFoundation
import BackgroundTasks
import CasterrCore
import Network
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
    let savedCharts = SavedCharts()
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
    /// How much of a refresh is done, from 0 to 1, while one runs. Nil otherwise.
    private(set) var refreshProgress: Double?
    /// Each running download's share done; nil inside when its size is unknown.
    private(set) var downloadProgress: [EpisodeKey: Double?] = [:]
    /// The Queue episodes to keep downloaded, from the last download sync.
    private(set) var wantedDownloads: Set<EpisodeKey> = []
    /// The phone is on a network downloads may use: Wi-Fi or wired, not expensive, not in Low Data Mode.
    private(set) var downloadsAllowed = true
    /// The phone has a network that downloads may not use on their own: cellular, Personal Hotspot, or Low Data Mode.
    private(set) var onLimitedNetwork = false
    /// The episode the listener just asked to download on cellular, waiting for its size to tell them.
    @ObservationIgnored private var cellularToastPending: EpisodeKey?
    @ObservationIgnored private let network = NWPathMonitor()
    /// The releases What's New lists while its sheet is open.
    var whatsNew: [Changelog.Release]?
    /// The bundled CHANGELOG.md.
    static let changelog = Changelog(Bundle.main.url(forResource: "CHANGELOG", withExtension: "md")
        .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "")
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    /// The bookmark the toast confirms.
    var lastBookmark: RecentBookmark?
    /// A bookmark the toast asked to open in the Bookmarks tab.
    var openingBookmark: OpenBookmark?
    // One counter per area, bumped after a change to it. Each is its own property, so a screen that reads
    // one counter isn't redrawn when another moves. Screens read them through `revision(_:)`.
    private(set) var followsRevision = 0
    private(set) var episodesRevision = 0
    private(set) var feedsRevision = 0
    private(set) var bookmarksRevision = 0
    private(set) var settingsRevision = 0
    private(set) var downloadsRevision = 0
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
        observeDownloadProgress()
        observeDownloadsAndPlayer()
    }

    func appBecameActive() async {
        await sharedInbox.pickUp()
        await refresh()
    }

    /// Refreshes, then, when `announce` is on and something moved, Cassy sums it up. Tapping her opens the Inbox.
    func refresh(announce: Bool = true) async {
        refreshing = true
        refreshProgress = 0
        defer {
            refreshing = false
            refreshProgress = nil
        }
        let summary = try? await feeds.refreshAll { done, total in
            Task { @MainActor [weak self] in
                guard let self, let current = refreshProgress else { return }
                // Reports can arrive out of order; the line only moves forward.
                refreshProgress = max(current, total == 0 ? 1 : Double(done) / Double(total))
            }
        }
        try? await library.mergeDuplicates()
        bump([.feeds, .episodes, .follows])
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
        wantedDownloads = Set(queue.prefix(max(keep, 0)))
        for key in plan.cancel { running[key]?.cancel() }
        for stem in plan.delete { downloader.store.delete(stem: stem) }
        for key in plan.start {
            if let episode = try? await library.episode(key) { downloader.start(key, from: episode.audioURL) }
        }
        if !plan.delete.isEmpty { bump(.downloads) }
    }

    /// Saves the current moment. Playback is untouched. False when nothing is loaded or saving failed.
    @discardableResult
    func bookmark() async -> Bool {
        guard let episode = player.episode,
              let id = try? await library.addBookmark(episode, showTitle: player.show?.title ?? "", at: player.position)
        else { return false }
        lastBookmark = RecentBookmark(id: id, position: player.position)
        bump(.bookmarks)
        return true
    }

    /// Runs the action chosen in Settings for a headphone or car button. A bookmark chimes, since the screen may be off.
    func button(_ press: NowPlayingBridge.Press) async {
        guard player.episode != nil, let actions = try? await library.buttonActions() else { return }
        switch press == .double ? actions.double : actions.triple {
        case .skipForward: player.skipForward()
        case .skipBack: player.skipBack()
        case .bookmark: if await bookmark() { Chime.play() }
        }
    }

    /// Reads the first Queue episode and how far into it the listener is.
    func loadUpNext() async {
        guard let key = try? await library.playableQueue().first, let episode = try? await library.episode(key) else {
            upNext = nil
            return
        }
        // A started episode is loaded, paused where the listener left it, so the bar is the mini player.
        if ((try? await library.progress(of: key)) ?? 0) > 0 {
            upNext = nil
            if player.episode == nil { try? await player.load(key) }
            return
        }
        let show = try? await library.show(episode.showKey)
        upNext = UpNext(episode: episode, showTitle: show?.title ?? "", artworkURL: show?.artworkURL)
    }

    /// On the first launch after an update, Cassy offers What's New for every version since the last one seen.
    /// A first install stays quiet, and so do UI tests unless they pass the last version.
    func greetUpdate(hasSeenOnboarding: Bool) {
        let defaults = UserDefaults.standard
        let last = defaults.string(forKey: "lastSeenVersion")
        defaults.set(Self.version, forKey: "lastSeenVersion")
        guard last != Self.version else { return }
        let uiTesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")
        if last == nil, !hasSeenOnboarding || uiTesting { return }
        let releases = last.map { Self.changelog.releases(after: $0) } ?? Array(Self.changelog.releases.prefix(1))
        guard !releases.isEmpty else { return }
        cassyToast = CassyMessage(job: .success, text: "I learned some new tricks.", actionTitle: "See") { [weak self] in
            self?.whatsNew = releases
        }
    }

    /// What the episode's row says about its download, the same on every screen.
    func downloadState(_ episode: EpisodeInfo) -> DownloadState? {
        DownloadState.of(downloaded: isDownloaded(episode), progress: downloadProgress[episode.key],
                         wanted: wantedDownloads.contains(episode.key), downloadsAllowed: downloadsAllowed,
                         loaded: player.episode?.key == episode.key)
    }

    /// The episode should download, isn't, and the phone has a network only the listener may let it use.
    func canDownloadOnCellular(_ episode: EpisodeInfo) -> Bool {
        onLimitedNetwork && wantedDownloads.contains(episode.key)
            && downloadProgress[episode.key] == nil && !isDownloaded(episode)
    }

    /// Downloads one episode on the current network, and shows it downloading at once.
    /// Cassy says how much data it takes once the download knows its size.
    func downloadOnCellular(_ episode: EpisodeInfo) {
        downloadProgress[episode.key] = .some(0)
        cellularToastPending = episode.key
        Task { await downloader.startOnCellular(episode.key, from: episode.audioURL) }
    }

    /// Follows running downloads in whole percents, so rows redraw at most about a hundred times per download,
    /// and the network, the way the download session judges it.
    private func observeDownloadProgress() {
        downloader.onProgress = { [weak self] key, share, size in
            Task { @MainActor in
                guard let self else { return }
                guard let share else {
                    self.downloadProgress[key] = nil
                    if self.cellularToastPending == key { self.cellularToastPending = nil }
                    return
                }
                if self.cellularToastPending == key {
                    self.cellularToastPending = nil
                    self.cassyToast = CassyMessage(job: .success, text: Self.cellularToast(size: size))
                }
                let current = self.downloadProgress[key]
                let percent = { (value: Double??) in value.flatMap { $0 }.map { Int($0 * 100) } }
                if current == nil || percent(current) != percent(share) {
                    self.downloadProgress[key] = share
                }
            }
        }
        network.pathUpdateHandler = { [weak self] path in
            let allowed = path.status == .satisfied && !path.isExpensive && !path.isConstrained
            let limited = path.status == .satisfied && !allowed
            Task { @MainActor in
                self?.downloadsAllowed = allowed
                self?.onLimitedNetwork = limited
            }
        }
        network.start(queue: DispatchQueue(label: "casterr.network"))
    }

    /// "Downloading on cellular, about 62 MB.", or without the size when the server sent none.
    static func cellularToast(size: Int64?) -> String {
        guard let size else { return "Downloading on cellular." }
        return "Downloading on cellular, about \(max(1, Int((Double(size) / 1_000_000).rounded()))) MB."
    }

    /// Reads the downloads counter, so a view that asks redraws when a download lands or goes.
    func isDownloaded(_ episode: EpisodeInfo) -> Bool {
        _ = downloadsRevision
        return downloader.store.localFile(for: episode.key, audioURL: episode.audioURL) != nil
    }

    /// Runs a change and tells the screens that show `areas` to reload. Returns the error message, if any.
    @discardableResult
    func change(_ areas: DataArea = .all, _ work: () async throws -> Void) async -> String? {
        // Which episodes download follows the Queue and the Keep downloaded setting.
        defer { if !areas.isDisjoint(with: [.episodes, .feeds, .settings]) { Task { await syncDownloads() } } }
        defer { bump(areas) }
        do {
            try await work()
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    /// The counters of `areas`, as a screen's reload id. Reads only those counters, so the others moving
    /// neither redraws nor reloads the screen.
    func revision(_ areas: DataArea) -> [Int] {
        var counters: [Int] = []
        if areas.contains(.follows) { counters.append(followsRevision) }
        if areas.contains(.episodes) { counters.append(episodesRevision) }
        if areas.contains(.feeds) { counters.append(feedsRevision) }
        if areas.contains(.bookmarks) { counters.append(bookmarksRevision) }
        if areas.contains(.settings) { counters.append(settingsRevision) }
        if areas.contains(.downloads) { counters.append(downloadsRevision) }
        return counters
    }

    private func bump(_ areas: DataArea) {
        if areas.contains(.follows) { followsRevision += 1 }
        if areas.contains(.episodes) { episodesRevision += 1 }
        if areas.contains(.feeds) { feedsRevision += 1 }
        if areas.contains(.bookmarks) { bookmarksRevision += 1 }
        if areas.contains(.settings) { settingsRevision += 1 }
        if areas.contains(.downloads) { downloadsRevision += 1 }
        // The bar under the tabs shows the top of the Queue.
        if !areas.isDisjoint(with: [.episodes, .feeds]) { Task { await loadUpNext() } }
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

    /// Seconds heard of each started episode.
    func progress(of keys: [EpisodeKey]) async -> [EpisodeKey: TimeInterval] {
        var progress: [EpisodeKey: TimeInterval] = [:]
        for key in keys {
            if let seconds = try? await library.progress(of: key), seconds > 0 { progress[key] = seconds }
        }
        return progress
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
                    self?.bump(.downloads)
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
        let session = MediaSession(NowPlayingBridge(player: player) { [weak self] press in
            await self?.button(press)
        })
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

/// A bookmark to show in the Bookmarks tab, with the keyboard in its note when `editNote`.
struct OpenBookmark: Equatable {
    let id: UUID
    let editNote: Bool
}

/// The first Queue episode while nothing is loaded and it was never started.
struct UpNext: Equatable {
    let episode: EpisodeInfo
    let showTitle: String
    let artworkURL: URL?
    let caption = "Up next · from your Queue"
}
