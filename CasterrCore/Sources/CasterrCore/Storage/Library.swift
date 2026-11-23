import Foundation
import SwiftData

public struct SubscriptionInfo: Equatable, Sendable {
    public var showKey: ShowKey
    public var feedURL: URL
    public var speedOverride: PlaybackSpeed?
    public var level: TriageLevel = .inbox
    /// Nil follows the global setting.
    public var expiryOverride: InboxExpiry?
    /// A favorite, separate from `level`.
    public var starred = false
}

/// What an episode row shows about the listener's state of one episode.
public struct EpisodeSnapshot: Equatable, Sendable {
    public var place: Place?
    public var move: LastMove?
    public var progress: TimeInterval
}

public struct ShowInfo: Equatable, Sendable {
    public var key: ShowKey
    public var title: String
    public var author: String?
    public var artworkURL: URL?
    public var summary: String?
    public var lastRefreshSuccess: Date?

    /// The feed's description without HTML tags or entities, with runs of whitespace collapsed.
    public var plainSummary: String? {
        guard let summary else { return nil }
        var text = HTMLText.decodingEntities(summary.replacing(/<[^>]+>/, with: " "))
        text = text.replacing(/\s+/, with: " ").trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }
    public var lastRefreshError: String?
    /// The show's page from its feed.
    public var webPage: URL?
    /// The show's current feed address: it follows the feed when it moves.
    public var feedURL: URL?
}

public struct ShowArt: Equatable, Sendable {
    public var title: String
    public var artworkURL: URL?
    /// The show's current feed address, for share links.
    public var feedURL: URL?

    public init(title: String, artworkURL: URL?, feedURL: URL? = nil) {
        self.feedURL = feedURL
        self.title = title
        self.artworkURL = artworkURL
    }
}

public struct BookmarkInfo: Equatable, Sendable {
    public var id: UUID
    public var episodeKey: EpisodeKey
    public var position: TimeInterval
    /// Empty means no note.
    public var note: String
    public var createdAt: Date
    public var showTitle: String
    public var episodeTitle: String
    public var audioURL: URL?
}

public struct EpisodeInfo: Equatable, Sendable {
    public var key: EpisodeKey
    public var showKey: ShowKey
    public var title: String
    public var audioURL: URL
    public var publishDate: Date?
    public var duration: TimeInterval?
    public var summary: String?
    /// The episode's own page from its feed.
    public var webPage: URL?
}

/// The app's only access to storage. It owns one long-lived context and hands out value types only.
@ModelActor
public actor Library {
    private var clock: @Sendable () -> Date = { Date.now }
    private var ruleThresholds = RuleCard.Thresholds()

    /// Replaces the clock that move times and expiry use. For tests.
    public func useClock(_ clock: @escaping @Sendable () -> Date) {
        self.clock = clock
    }

    func now() -> Date { clock() }

    /// Replaces the rule card thresholds. For tests.
    public func useRuleThresholds(_ thresholds: RuleCard.Thresholds) {
        ruleThresholds = thresholds
    }

    /// Opens the feed cache and user data as two stores in one container. The feed cache never syncs.
    /// User data syncs through iCloud when the app has an iCloud container, and stays local otherwise.
    public static func open(inMemory: Bool = false) throws -> Library {
        try open(configurations: [
            ModelConfiguration("FeedCache", schema: Schemas.feedCache, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none),
            ModelConfiguration("UserData", schema: Schemas.userData, isStoredInMemoryOnly: inMemory,
                               cloudKitDatabase: inMemory ? .none : .automatic),
        ])
    }

    /// Opens local stores in `directory`. Two libraries opened on one folder share their data,
    /// which is how tests stand in for two devices writing before a sync.
    static func open(directory: URL) throws -> Library {
        try open(configurations: [
            ModelConfiguration("FeedCache", schema: Schemas.feedCache, url: directory.appending(path: "FeedCache.store"),
                               cloudKitDatabase: .none),
            ModelConfiguration("UserData", schema: Schemas.userData, url: directory.appending(path: "UserData.store"),
                               cloudKitDatabase: .none),
        ])
    }

    private static func open(configurations: [ModelConfiguration]) throws -> Library {
        let schema = Schema([ShowRecord.self, EpisodeRecord.self, Subscription.self, EpisodeState.self, UserSettings.self,
                             Bookmark.self])
        return Library(modelContainer: try ModelContainer(for: schema, configurations: configurations))
    }

    // MARK: Subscriptions

    /// Returns false, and changes nothing, when the show is already followed.
    /// Call after saving the feed, so the first triage places the show's newest episode.
    /// Without saved episodes, the first triage places nothing.
    @discardableResult
    public func addSubscription(_ showKey: ShowKey, feedURL: URL) throws -> Bool {
        guard try subscription(showKey) == nil else { return false }
        let record = Subscription(showKey: showKey.rawValue, feedURL: feedURL)
        let dates = try episodeRecords(of: showKey).compactMap(\.publishDate)
        if let newest = dates.max() {
            record.triageAfter = dates.filter { $0 < newest }.max() ?? .distantPast
        }
        modelContext.insert(record)
        try modelContext.save()
        return true
    }

    public func subscriptions() throws -> [SubscriptionInfo] {
        try modelContext.fetch(FetchDescriptor<Subscription>(sortBy: [SortDescriptor(\.subscribedAt)]))
            .compactMap { record in
                guard let feedURL = record.feedURL else { return nil }
                return SubscriptionInfo(
                    showKey: ShowKey(rawValue: record.showKey),
                    feedURL: feedURL,
                    speedOverride: record.speedOverride.map(PlaybackSpeed.init),
                    level: TriageLevel(rawValue: record.level) ?? .inbox,
                    expiryOverride: record.expiryDaysOverride.map(InboxExpiry.init(storedDays:)),
                    starred: record.starred
                )
            }
    }

    public func isSubscribed(_ showKey: ShowKey) throws -> Bool {
        try subscription(showKey) != nil
    }

    /// Queued episodes of the show stay in the Queue. Its Inbox episodes move to the archive.
    public func removeSubscription(_ showKey: ShowKey) throws {
        guard let record = try subscription(showKey) else { return }
        modelContext.delete(record)
        for state in try states(in: .inbox) where EpisodeKey(rawValue: state.episodeKey).belongs(to: showKey) {
            try relocate(state, to: .archive(.unsubscribed), reason: .listener)
        }
        try modelContext.save()
    }

    /// Follows a feed move. The show key never changes.
    public func updateFeedURL(_ showKey: ShowKey, to url: URL) throws {
        try subscription(showKey)?.feedURL = url
        try modelContext.save()
    }

    /// Nil when the show follows the global speed.
    public func speedOverride(_ showKey: ShowKey) throws -> PlaybackSpeed? {
        try subscription(showKey)?.speedOverride.map(PlaybackSpeed.init)
    }

    public func setSpeedOverride(_ showKey: ShowKey, to speed: PlaybackSpeed?) throws {
        try subscription(showKey)?.speedOverride = speed?.value
        try modelContext.save()
    }

    /// Nil when the show follows the global voice boost setting.
    public func voiceBoostOverride(_ showKey: ShowKey) throws -> Bool? {
        try subscription(showKey)?.voiceBoostOverride
    }

    public func setVoiceBoostOverride(_ showKey: ShowKey, to isOn: Bool?) throws {
        try subscription(showKey)?.voiceBoostOverride = isOn
        try modelContext.save()
    }

    public func setLevel(_ showKey: ShowKey, to level: TriageLevel) throws {
        try subscription(showKey)?.level = level.rawValue
        try modelContext.save()
    }

    /// Starring a show whose new episodes go to the Inbox sends them to the Queue; other levels stay.
    /// Unstarring removes only the star.
    public func setStarred(_ showKey: ShowKey, _ starred: Bool) throws {
        guard let subscription = try subscription(showKey) else { return }
        subscription.starred = starred
        if starred, subscription.level == TriageLevel.inbox.rawValue {
            subscription.level = TriageLevel.autoQueue.rawValue
        }
        try modelContext.save()
    }

    /// Nil follows the global setting.
    public func setExpiryOverride(_ showKey: ShowKey, to expiry: InboxExpiry?) throws {
        try subscription(showKey)?.expiryDaysOverride = expiry?.storedDays
        try modelContext.save()
    }

    private func subscription(_ showKey: ShowKey) throws -> Subscription? {
        let key = showKey.rawValue
        return try modelContext.fetch(FetchDescriptor<Subscription>(predicate: #Predicate { $0.showKey == key })).first
    }

    // MARK: Triage

    /// Places the show's new episodes by its level, oldest first. New means published after
    /// the subscription's triage date and never placed. Undated episodes are never new.
    /// The first triage of a subscription from before triage existed places nothing.
    @discardableResult
    public func triage(_ showKey: ShowKey) throws -> RefreshSummary {
        guard let subscription = try subscription(showKey) else { return RefreshSummary() }
        let records = try episodeRecords(of: showKey)
        guard let after = subscription.triageAfter else {
            subscription.triageAfter = records.compactMap(\.publishDate).max() ?? clock()
            try modelContext.save()
            return RefreshSummary()
        }
        let destination = (TriageLevel(rawValue: subscription.level) ?? .inbox).destination
        let fresh = records
            .compactMap { record in record.publishDate.map { (key: EpisodeKey(rawValue: record.key), date: $0) } }
            .filter { $0.date > after }
            .sorted { $0.date < $1.date }
        var summary = RefreshSummary()
        for episode in fresh where try state(episode.key) == nil {
            try relocate(state(episode.key, creating: true)!, to: destination.place, reason: destination.reason)
            switch destination.place {
            case .inbox: summary.arrived += 1
            case .queue: summary.queued += 1
            case .archive: summary.skipped += 1
            }
        }
        try modelContext.save()
        return summary
    }

    // MARK: Rule cards

    /// Cards for Inbox-level shows whose card isn't hidden, in subscription order.
    public func ruleCards() throws -> [RuleCard] {
        let now = clock()
        let states = Dictionary(
            try modelContext.fetch(FetchDescriptor<EpisodeState>()).map { ($0.episodeKey, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        var cards: [RuleCard] = []
        for subscription in try modelContext.fetch(FetchDescriptor<Subscription>(sortBy: [SortDescriptor(\.subscribedAt)]))
        where subscription.level == TriageLevel.inbox.rawValue {
            let show = ShowKey(rawValue: subscription.showKey)
            var episodes: [RuleCard.Episode] = []
            for record in try episodeRecords(of: show) {
                guard let published = record.publishDate else { continue }
                let state = states[record.key]
                episodes.append(RuleCard.Episode(
                    published: published, firstPlayedAt: state?.firstPlayedAt,
                    place: try state.flatMap { try Place(storedPlace: $0.place, archiveReason: $0.archiveReason) }
                ))
            }
            guard let kind = RuleCard.evaluate(episodes: episodes, now: now, thresholds: ruleThresholds) else { continue }
            let hiddenUntil = kind == .autoQueue ? subscription.autoQueueCardHiddenUntil : subscription.ignoredCardHiddenUntil
            if hiddenUntil.map({ $0 > now }) ?? false { continue }
            cards.append(RuleCard(show: show, kind: kind))
        }
        return cards
    }

    /// Not now hides the card for 30 days; never hides it for good.
    public func hideRuleCard(_ card: RuleCard, forever: Bool) throws {
        guard let subscription = try subscription(card.show) else { return }
        let until = forever ? Date.distantFuture : clock().addingTimeInterval(RuleCard.hideForNotNow)
        switch card.kind {
        case .autoQueue: subscription.autoQueueCardHiddenUntil = until
        case .ignored: subscription.ignoredCardHiddenUntil = until
        }
        try modelContext.save()
    }

    // MARK: Inbox

    /// Newest first.
    public func inbox() throws -> [EpisodeKey] {
        var dated: [(key: EpisodeKey, date: Date)] = []
        for state in try states(in: .inbox) {
            let key = EpisodeKey(rawValue: state.episodeKey)
            dated.append((key, try episodeRecord(key)?.publishDate ?? .distantPast))
        }
        return dated.sorted { $0.date > $1.date }.map(\.key)
    }

    public func inboxCount() throws -> Int {
        try states(in: .inbox).count
    }

    public func dismiss(_ key: EpisodeKey) throws {
        try relocate(state(key, creating: true)!, to: .archive(.dismissed), reason: .listener)
        try modelContext.save()
    }

    /// Whole days until each Inbox episode leaves, rounded up. Episodes whose period is never are left out.
    public func inboxDaysLeft() throws -> [EpisodeKey: Int] {
        let global = InboxExpiry(storedDays: try settings().expiryDays)
        let overrides = try modelContext.fetch(FetchDescriptor<Subscription>()).compactMap { record in
            record.expiryDaysOverride.map { (show: ShowKey(rawValue: record.showKey), expiry: InboxExpiry(storedDays: $0)) }
        }
        let now = clock()
        var left: [EpisodeKey: Int] = [:]
        for state in try states(in: .inbox) {
            let key = EpisodeKey(rawValue: state.episodeKey)
            let expiry = overrides.first { key.belongs(to: $0.show) }?.expiry ?? global
            guard case .days(let days) = expiry, let enteredAt = state.movedAt else { continue }
            let remaining = Double(days) * 86_400 - now.timeIntervalSince(enteredAt)
            left[key] = max(0, Int((remaining / 86_400).rounded(.up)))
        }
        return left
    }

    /// Moves Inbox episodes that waited their show's period, or the global one, to the archive.
    /// Returns how many expired.
    @discardableResult
    public func expireInbox() throws -> Int {
        let global = InboxExpiry(storedDays: try settings().expiryDays)
        let overrides = try modelContext.fetch(FetchDescriptor<Subscription>()).compactMap { record in
            record.expiryDaysOverride.map { (show: ShowKey(rawValue: record.showKey), expiry: InboxExpiry(storedDays: $0)) }
        }
        let now = clock()
        var expired = 0
        for state in try states(in: .inbox) {
            let key = EpisodeKey(rawValue: state.episodeKey)
            let expiry = overrides.first { key.belongs(to: $0.show) }?.expiry ?? global
            guard case .days(let days) = expiry, let enteredAt = state.movedAt,
                  expiry.hasExpired(enteredAt: enteredAt, now: now) else { continue }
            try relocate(state, to: .archive(.expired), reason: .expired(days: days))
            expired += 1
        }
        try modelContext.save()
        return expired
    }

    // MARK: Latest move

    /// Each episode's place, latest move, and progress, read in one fetch, for long lists like a show page.
    /// Episodes the listener never touched are left out.
    public func snapshots(of keys: [EpisodeKey]) throws -> [EpisodeKey: EpisodeSnapshot] {
        let wanted = Set(keys.map(\.rawValue))
        var snapshots: [EpisodeKey: EpisodeSnapshot] = [:]
        for state in try modelContext.fetch(FetchDescriptor<EpisodeState>()) where wanted.contains(state.episodeKey) {
            snapshots[EpisodeKey(rawValue: state.episodeKey)] = EpisodeSnapshot(
                place: try? Place(storedPlace: state.place, archiveReason: state.archiveReason),
                move: state.moveReason.flatMap(MoveReason.init(stored:)).map(LastMove.init(reason:)),
                progress: state.progressSeconds
            )
        }
        return snapshots
    }

    public func lastMove(of key: EpisodeKey) throws -> LastMove? {
        guard let state = try state(key), let raw = state.moveReason, let reason = MoveReason(stored: raw) else { return nil }
        return LastMove(reason: reason)
    }

    // MARK: Queue

    /// Episode keys in play order. The first is Now Playing.
    public func queue() throws -> [EpisodeKey] {
        try states(in: .queue).map { EpisodeKey(rawValue: $0.episodeKey) }
    }

    /// The Queue as this device can show and play it: a shared file or an unfollowed show's episode
    /// queued on another device has no record here, so it's skipped and the others keep their order.
    public func playableQueue() throws -> [EpisodeKey] {
        let known = try knownEpisodeKeys()
        return try queue().filter { known.contains($0.rawValue) }
    }

    /// Moves a queued episode to `index` in the playable Queue, where hidden episodes don't count.
    public func movePlayable(_ key: EpisodeKey, to index: Int) throws {
        let others = try playableQueue().filter { $0 != key }
        let full = try queue().filter { $0 != key }
        let target: Int
        if index < others.count {
            target = full.firstIndex(of: others[max(index, 0)]) ?? 0
        } else {
            target = others.last.flatMap { full.firstIndex(of: $0) }.map { $0 + 1 } ?? full.count
        }
        try move(key, to: target)
    }

    /// Keys of the episodes in the feed cache: the ones this device can show and play.
    private func knownEpisodeKeys() throws -> Set<String> {
        Set(try modelContext.fetch(FetchDescriptor<EpisodeRecord>()).map(\.key))
    }

    /// Adds to the end. An episode already in the Queue keeps its position.
    public func addToQueue(_ key: EpisodeKey) throws {
        let state = try state(key, creating: true)!
        guard state.place != Place.queue.stored.place else { return }
        try relocate(state, to: .queue, reason: .listener)
        try modelContext.save()
    }

    /// Moves a queued episode to `index` (0 is Now Playing). Others keep their relative order.
    public func move(_ key: EpisodeKey, to index: Int) throws {
        var queued = try states(in: .queue)
        guard let from = queued.firstIndex(where: { $0.episodeKey == key.rawValue }) else { return }
        let state = queued.remove(at: from)
        queued.insert(state, at: min(max(index, 0), queued.count))
        renumber(queued)
        try modelContext.save()
    }

    /// Puts the episode first, adding it to the Queue if needed. Used when playback starts.
    public func moveToTop(_ key: EpisodeKey) throws {
        try relocate(state(key, creating: true)!, to: .queue, reason: .listener)
        try move(key, to: 0)
    }

    /// Removed like a dismissed Inbox episode, so its show page says "Removed". It keeps its progress.
    public func removeFromQueue(_ key: EpisodeKey) throws {
        guard let state = try state(key), state.place == Place.queue.stored.place else { return }
        try relocate(state, to: .archive(.dismissed), reason: .listener)
        try modelContext.save()
    }

    /// Play-next episodes go after Now Playing and after earlier play-next episodes.
    /// Right after Now Playing, the first episode this device has, and after earlier Play next episodes.
    private func playNextIndex(in queued: [EpisodeState]) throws -> Int {
        let known = try knownEpisodeKeys()
        guard let nowPlaying = queued.firstIndex(where: { known.contains($0.episodeKey) }) else { return queued.count }
        var index = nowPlaying + 1
        while index < queued.count, queued[index].moveReason == MoveReason.playNext.stored {
            index += 1
        }
        return index
    }

    private func renumber(_ states: [EpisodeState]) {
        for (index, state) in states.enumerated() where state.queuePosition != index + 1 {
            state.queuePosition = index + 1
        }
    }

    // MARK: Episode state

    public func place(of key: EpisodeKey) throws -> Place? {
        guard let state = try state(key) else { return nil }
        return try Place(storedPlace: state.place, archiveReason: state.archiveReason)
    }

    public func progress(of key: EpisodeKey) throws -> TimeInterval {
        try state(key)?.progressSeconds ?? 0
    }

    func firstPlayedAt(of key: EpisodeKey) throws -> Date? {
        try state(key)?.firstPlayedAt
    }

    /// Records the first time playback started. Later starts change nothing.
    public func recordPlayStart(_ key: EpisodeKey) throws {
        let state = try state(key, creating: true)!
        guard state.firstPlayedAt == nil else { return }
        state.firstPlayedAt = clock()
        try modelContext.save()
    }

    public func setProgress(_ key: EpisodeKey, to seconds: TimeInterval) throws {
        try state(key, creating: true)!.progressSeconds = max(seconds, 0)
        try modelContext.save()
    }

    /// Moves the episode to the archive. If it was queued, it leaves the Queue.
    public func markPlayed(_ key: EpisodeKey) throws {
        try relocate(state(key, creating: true)!, to: .archive(.played), reason: .listener)
        try modelContext.save()
    }

    /// Resets progress. An archived episode ends up with no place; a queued one stays queued.
    public func markUnplayed(_ key: EpisodeKey) throws {
        guard let state = try state(key) else { return }
        if state.place == Place.archive(.played).stored.place {
            try relocate(state, to: nil, reason: .listener)
        }
        state.progressSeconds = 0
        try modelContext.save()
    }

    /// Changes the episode's place, records the move, and keeps the Queue numbered 1 to N.
    /// Moving an episode to the place it's in only records the move.
    private func relocate(_ state: EpisodeState, to place: Place?, reason: MoveReason) throws {
        let wasQueued = state.place == Place.queue.stored.place
        var queued = try states(in: .queue)
        if place == .queue, !wasQueued {
            queued.insert(state, at: reason == .playNext ? try playNextIndex(in: queued) : queued.count)
        } else if place != .queue, wasQueued {
            queued.removeAll { $0 === state }
        }
        state.place = place?.stored.place
        state.archiveReason = place?.stored.archiveReason
        state.moveReason = reason.stored
        state.movedAt = clock()
        if place != .queue { state.queuePosition = nil }
        renumber(queued)
    }

    /// Queue states come back in play order.
    private func states(in place: Place) throws -> [EpisodeState] {
        let raw = place.stored.place
        return try modelContext.fetch(FetchDescriptor<EpisodeState>(
            predicate: #Predicate { $0.place == raw },
            sortBy: [SortDescriptor(\.queuePosition)]
        ))
    }

    private func state(_ key: EpisodeKey, creating: Bool = false) throws -> EpisodeState? {
        let raw = key.rawValue
        if let existing = try modelContext.fetch(FetchDescriptor<EpisodeState>(predicate: #Predicate { $0.episodeKey == raw })).first {
            return existing
        }
        guard creating else { return nil }
        let state = EpisodeState(episodeKey: raw)
        modelContext.insert(state)
        return state
    }

    // MARK: Settings

    public func globalSpeed() throws -> PlaybackSpeed {
        PlaybackSpeed(try settings().speed)
    }

    public func setGlobalSpeed(_ speed: PlaybackSpeed) throws {
        try changeSettings { $0.speed = speed.value }
    }

    public func effectiveSpeed(for showKey: ShowKey) throws -> PlaybackSpeed {
        PlaybackSpeed.effective(
            global: try globalSpeed(),
            override: try speedOverride(showKey)
        )
    }

    public func globalVoiceBoost() throws -> Bool {
        try settings().voiceBoost
    }

    public func setGlobalVoiceBoost(_ isOn: Bool) throws {
        try changeSettings { $0.voiceBoost = isOn }
    }

    public func effectiveVoiceBoost(for showKey: ShowKey) throws -> Bool {
        try voiceBoostOverride(showKey) ?? globalVoiceBoost()
    }

    public func globalExpiry() throws -> InboxExpiry {
        InboxExpiry(storedDays: try settings().expiryDays)
    }

    public func setGlobalExpiry(_ expiry: InboxExpiry) throws {
        try changeSettings { $0.expiryDays = expiry.storedDays }
    }

    public func downloadCount() throws -> Int {
        try settings().downloadCount
    }

    public func setDownloadCount(_ count: Int) throws {
        try changeSettings { $0.downloadCount = max(count, 0) }
    }

    /// Every settings change stamps `updatedAt`, so a merge keeps the listener's settings over a new device's defaults.
    private func changeSettings(_ change: (UserSettings) -> Void) throws {
        let settings = try settings()
        change(settings)
        settings.updatedAt = clock()
        try modelContext.save()
    }

    private func settings() throws -> UserSettings {
        if let existing = try modelContext.fetch(FetchDescriptor<UserSettings>()).first {
            return existing
        }
        let settings = UserSettings()
        modelContext.insert(settings)
        return settings
    }

    // MARK: Sync

    /// Merges records that two devices created for the same thing before they synced.
    /// Per episode the latest move wins and keeps the earliest first play; per show the earliest
    /// subscription wins; the most recently changed settings win. The Queue is renumbered 1 to N.
    public func mergeDuplicates() throws {
        let allStates = try modelContext.fetch(FetchDescriptor<EpisodeState>())
        for group in Dictionary(grouping: allStates, by: \.episodeKey).values where group.count > 1 {
            let keeper = group.max { ($0.movedAt ?? .distantPast) < ($1.movedAt ?? .distantPast) }!
            keeper.firstPlayedAt = group.compactMap(\.firstPlayedAt).min()
            for state in group where state !== keeper { modelContext.delete(state) }
        }
        let subscriptions = try modelContext.fetch(FetchDescriptor<Subscription>())
        for group in Dictionary(grouping: subscriptions, by: \.showKey).values where group.count > 1 {
            let keeper = group.min { $0.subscribedAt < $1.subscribedAt }!
            for subscription in group where subscription !== keeper { modelContext.delete(subscription) }
        }
        let allSettings = try modelContext.fetch(FetchDescriptor<UserSettings>())
        if let keeper = allSettings.max(by: { $0.updatedAt < $1.updatedAt }) {
            for settings in allSettings where settings !== keeper { modelContext.delete(settings) }
        }
        if modelContext.hasChanges { try modelContext.save() }

        // Ties in position go to the later move.
        let queued = try states(in: .queue).sorted { a, b in
            let (pa, pb) = (a.queuePosition ?? .max, b.queuePosition ?? .max)
            return pa != pb ? pa < pb : (a.movedAt ?? .distantPast) > (b.movedAt ?? .distantPast)
        }
        renumber(queued)
        if modelContext.hasChanges { try modelContext.save() }
    }

    // MARK: Bookmarks

    @discardableResult
    public func addBookmark(_ episode: EpisodeInfo, showTitle: String, at position: TimeInterval) throws -> UUID {
        let bookmark = Bookmark(
            episodeKey: episode.key.rawValue, position: max(position, 0), showTitle: showTitle,
            episodeTitle: episode.title, audioURL: episode.audioURL, createdAt: clock()
        )
        modelContext.insert(bookmark)
        try modelContext.save()
        return bookmark.id
    }

    public func setNote(_ note: String, for id: UUID) throws {
        try bookmark(id)?.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        try modelContext.save()
    }

    public func deleteBookmark(_ id: UUID) throws {
        guard let bookmark = try bookmark(id) else { return }
        modelContext.delete(bookmark)
        try modelContext.save()
    }

    /// Newest first. A non-empty `text` keeps bookmarks whose note, episode title, or show title contains it, ignoring case.
    public func bookmarks(matching text: String = "") throws -> [BookmarkInfo] {
        let term = text.trimmingCharacters(in: .whitespaces)
        return try modelContext.fetch(FetchDescriptor<Bookmark>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            .filter { term.isEmpty || [$0.note, $0.episodeTitle, $0.showTitle].contains { $0.localizedStandardContains(term) } }
            .map { BookmarkInfo(
                id: $0.id, episodeKey: EpisodeKey(rawValue: $0.episodeKey), position: $0.position, note: $0.note,
                createdAt: $0.createdAt, showTitle: $0.showTitle, episodeTitle: $0.episodeTitle, audioURL: $0.audioURL
            ) }
    }

    private func bookmark(_ id: UUID) throws -> Bookmark? {
        try modelContext.fetch(FetchDescriptor<Bookmark>(predicate: #Predicate { $0.id == id })).first
    }

    // MARK: Feed cache

    /// Inserts or updates the show and its episodes, matched by key.
    public func saveFeed(_ feed: ParsedShow, for showKey: ShowKey) throws {
        let raw = showKey.rawValue
        let show = try modelContext.fetch(FetchDescriptor<ShowRecord>(predicate: #Predicate { $0.key == raw })).first
            ?? { let new = ShowRecord(key: raw, title: feed.title); modelContext.insert(new); return new }()
        show.title = feed.title
        show.author = feed.author
        show.artworkURL = feed.artworkURL
        show.summary = feed.description
        show.webPage = feed.webPage
        show.lastRefreshSuccess = .now
        show.lastRefreshError = nil

        var existing = Dictionary(
            try modelContext.fetch(FetchDescriptor<EpisodeRecord>(predicate: #Predicate { $0.showKey == raw }))
                .map { ($0.key, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        for parsed in feed.episodes {
            let key = EpisodeKey(show: showKey, guid: parsed.guid, audioURL: parsed.audioURL).rawValue
            let record = existing[key] ?? {
                let new = EpisodeRecord(key: key, showKey: raw, title: parsed.title, audioURL: parsed.audioURL)
                modelContext.insert(new)
                existing[key] = new
                return new
            }()
            record.title = parsed.title
            record.audioURL = parsed.audioURL
            record.publishDate = parsed.publishDate
            record.duration = parsed.duration
            record.summary = parsed.description
            record.webPage = parsed.webPage
        }
        try modelContext.save()
    }

    public func recordRefreshFailure(_ showKey: ShowKey, error: String) throws {
        let raw = showKey.rawValue
        try modelContext.fetch(FetchDescriptor<ShowRecord>(predicate: #Predicate { $0.key == raw })).first?
            .lastRefreshError = error
        try modelContext.save()
    }

    /// Every show's title and artwork address, in one fetch, for drawing art in lists.
    public func showArt() throws -> [ShowKey: ShowArt] {
        let feeds = try currentFeeds()
        return Dictionary(try modelContext.fetch(FetchDescriptor<ShowRecord>()).map {
            let key = ShowKey(rawValue: $0.key)
            return (key, ShowArt(title: $0.title, artworkURL: $0.artworkURL, feedURL: feeds[key] ?? $0.feedURL))
        }, uniquingKeysWith: { first, _ in first })
    }

    /// Each followed show's current feed address.
    private func currentFeeds() throws -> [ShowKey: URL] {
        Dictionary(try modelContext.fetch(FetchDescriptor<Subscription>()).compactMap { record in
            record.feedURL.map { (ShowKey(rawValue: record.showKey), $0) }
        }, uniquingKeysWith: { first, _ in first })
    }

    public func show(_ showKey: ShowKey) throws -> ShowInfo? {
        let raw = showKey.rawValue
        return try modelContext.fetch(FetchDescriptor<ShowRecord>(predicate: #Predicate { $0.key == raw })).first
            .map { ShowInfo(
                key: showKey, title: $0.title, author: $0.author, artworkURL: $0.artworkURL, summary: $0.summary,
                lastRefreshSuccess: $0.lastRefreshSuccess, lastRefreshError: $0.lastRefreshError, webPage: $0.webPage,
                feedURL: try subscription(showKey)?.feedURL ?? $0.feedURL
            ) }
    }

    /// Newest first; episodes without a date come last.
    public func episodes(of showKey: ShowKey) throws -> [EpisodeInfo] {
        try episodeRecords(of: showKey)
            .sorted { ($0.publishDate ?? .distantPast) > ($1.publishDate ?? .distantPast) }
            .map(info)
    }

    // MARK: Shared with Casterr

    public static let sharedShowTitle = "Shared with Casterr"

    /// Adds a file shared to Casterr to the built-in show and plays it next, like Play next.
    /// `id` makes the key unique; `audioURL` is the file's stable address, not its path.
    @discardableResult
    public func addSharedEpisode(id: String, title: String, duration: TimeInterval?, audioURL: URL) throws -> EpisodeKey {
        let showRaw = ShowKey.shared.rawValue
        if try modelContext.fetch(FetchDescriptor<ShowRecord>(predicate: #Predicate { $0.key == showRaw })).isEmpty {
            modelContext.insert(ShowRecord(key: showRaw, title: Self.sharedShowTitle))
        }
        let key = EpisodeKey(show: .shared, guid: "shared-\(id)", audioURL: audioURL)
        let record = EpisodeRecord(key: key.rawValue, showKey: showRaw, title: title, audioURL: audioURL)
        record.publishDate = clock()
        record.duration = duration
        modelContext.insert(record)
        try relocate(state(key, creating: true)!, to: .queue, reason: .playNext)
        try modelContext.save()
        return key
    }

    /// An episode of any cached show with this GUID: lets a shared link reuse an episode the listener already has,
    /// even when Apple's feed address differs from the one they follow.
    public func episodeKey(withGUID guid: String) throws -> EpisodeKey? {
        let suffix = "|guid:\(guid.trimmingCharacters(in: .whitespacesAndNewlines))"
        return try modelContext.fetch(FetchDescriptor<EpisodeRecord>()).first { $0.key.hasSuffix(suffix) }
            .map { EpisodeKey(rawValue: $0.key) }
    }

    /// Plays the episode next, like Play next, moving it there if it's already queued.
    public func playNext(_ key: EpisodeKey) throws {
        if let state = try state(key), state.place == Place.queue.stored.place {
            try relocate(state, to: nil, reason: .listener)
        }
        try relocate(state(key, creating: true)!, to: .queue, reason: .playNext)
        try modelContext.save()
    }

    /// The listener's own Play Next: the same spot, but no "Play next" label.
    public func playNextByListener(_ key: EpisodeKey) throws {
        try playNext(key)
        try state(key)?.moveReason = MoveReason.listener.stored
        try modelContext.save()
    }

    /// Remembers where an unfollowed show's feed came from, so Subscribe works later.
    public func setFeedURL(_ url: URL, for showKey: ShowKey) throws {
        let raw = showKey.rawValue
        try modelContext.fetch(FetchDescriptor<ShowRecord>(predicate: #Predicate { $0.key == raw })).first?.feedURL = url
        try modelContext.save()
    }

    public func cachedFeedURL(of showKey: ShowKey) throws -> URL? {
        let raw = showKey.rawValue
        return try modelContext.fetch(FetchDescriptor<ShowRecord>(predicate: #Predicate { $0.key == raw })).first?.feedURL
    }

    /// Points the Shared with Casterr show at its art. Called on each pickup, since the file's path can change.
    public func setSharedShowArtwork(_ url: URL) throws {
        let raw = ShowKey.shared.rawValue
        guard let show = try modelContext.fetch(FetchDescriptor<ShowRecord>(predicate: #Predicate { $0.key == raw })).first,
              show.artworkURL != url else { return }
        show.artworkURL = url
        try modelContext.save()
    }

    /// Removes a shared episode from wherever it is, and its record. The caller deletes the file.
    public func deleteSharedEpisode(_ key: EpisodeKey) throws {
        guard key.rawValue.hasPrefix(ShowKey.shared.rawValue + "|") else { return }
        try removeFromQueue(key)
        if let state = try state(key) { modelContext.delete(state) }
        if let record = try episodeRecord(key) { modelContext.delete(record) }
        try modelContext.save()
    }

    public func episode(_ key: EpisodeKey) throws -> EpisodeInfo? {
        try episodeRecord(key).map(info)
    }

    private func episodeRecord(_ key: EpisodeKey) throws -> EpisodeRecord? {
        let raw = key.rawValue
        return try modelContext.fetch(FetchDescriptor<EpisodeRecord>(predicate: #Predicate { $0.key == raw })).first
    }

    private func episodeRecords(of showKey: ShowKey) throws -> [EpisodeRecord] {
        let raw = showKey.rawValue
        return try modelContext.fetch(FetchDescriptor<EpisodeRecord>(predicate: #Predicate { $0.showKey == raw }))
    }

    /// Deletes all feed data. User data is untouched and re-attaches on the next fetch.
    /// Keeps the built-in Shared with Casterr show: its episodes can't be fetched again.
    public func wipeFeedCache() throws {
        let shared = ShowKey.shared.rawValue
        try modelContext.delete(model: EpisodeRecord.self, where: #Predicate { $0.showKey != shared })
        try modelContext.delete(model: ShowRecord.self, where: #Predicate { $0.key != shared })
        try modelContext.save()
    }

    private func info(_ record: EpisodeRecord) -> EpisodeInfo {
        EpisodeInfo(
            key: EpisodeKey(rawValue: record.key), showKey: ShowKey(rawValue: record.showKey), title: record.title,
            audioURL: record.audioURL, publishDate: record.publishDate, duration: record.duration, summary: record.summary,
            webPage: record.webPage
        )
    }
}
