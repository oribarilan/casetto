import Foundation
import SwiftData

public struct SubscriptionInfo: Equatable, Sendable {
    public var showKey: ShowKey
    public var feedURL: URL
    public var speedOverride: PlaybackSpeed?
    public var level: TriageLevel = .inbox
    /// Nil follows the global setting.
    public var expiryOverride: InboxExpiry?
}

public struct ShowInfo: Equatable, Sendable {
    public var key: ShowKey
    public var title: String
    public var author: String?
    public var artworkURL: URL?
    public var summary: String?
    public var lastRefreshSuccess: Date?
    public var lastRefreshError: String?
}

public struct EpisodeInfo: Equatable, Sendable {
    public var key: EpisodeKey
    public var showKey: ShowKey
    public var title: String
    public var audioURL: URL
    public var publishDate: Date?
    public var duration: TimeInterval?
    public var summary: String?
}

/// The app's only access to storage. It owns one long-lived context and hands out value types only.
@ModelActor
public actor Library {
    private var clock: @Sendable () -> Date = { Date.now }

    /// Replaces the clock that move times and expiry use. For tests.
    public func useClock(_ clock: @escaping @Sendable () -> Date) {
        self.clock = clock
    }

    /// Opens the feed cache and user data as two stores in one container.
    public static func open(inMemory: Bool = false) throws -> Library {
        let container = try ModelContainer(
            for: Schema([ShowRecord.self, EpisodeRecord.self, Subscription.self, EpisodeState.self, UserSettings.self]),
            configurations: [
                ModelConfiguration("FeedCache", schema: Schemas.feedCache, isStoredInMemoryOnly: inMemory),
                ModelConfiguration("UserData", schema: Schemas.userData, isStoredInMemoryOnly: inMemory),
            ]
        )
        return Library(modelContainer: container)
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
                    expiryOverride: record.expiryDaysOverride.map(InboxExpiry.init(storedDays:))
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

    public func setSpeedOverride(_ showKey: ShowKey, to speed: PlaybackSpeed?) throws {
        try subscription(showKey)?.speedOverride = speed?.value
        try modelContext.save()
    }

    public func setLevel(_ showKey: ShowKey, to level: TriageLevel) throws {
        try subscription(showKey)?.level = level.rawValue
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
    public func triage(_ showKey: ShowKey) throws {
        guard let subscription = try subscription(showKey) else { return }
        let records = try episodeRecords(of: showKey)
        guard let after = subscription.triageAfter else {
            subscription.triageAfter = records.compactMap(\.publishDate).max() ?? clock()
            try modelContext.save()
            return
        }
        let destination = (TriageLevel(rawValue: subscription.level) ?? .inbox).destination
        let fresh = records
            .compactMap { record in record.publishDate.map { (key: EpisodeKey(rawValue: record.key), date: $0) } }
            .filter { $0.date > after }
            .sorted { $0.date < $1.date }
        for episode in fresh where try state(episode.key) == nil {
            try relocate(state(episode.key, creating: true)!, to: destination.place, reason: destination.reason)
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

    /// Moves Inbox episodes that waited their show's period, or the global one, to the archive.
    public func expireInbox() throws {
        let global = InboxExpiry(storedDays: try settings().expiryDays)
        let overrides = try modelContext.fetch(FetchDescriptor<Subscription>()).compactMap { record in
            record.expiryDaysOverride.map { (show: ShowKey(rawValue: record.showKey), expiry: InboxExpiry(storedDays: $0)) }
        }
        let now = clock()
        for state in try states(in: .inbox) {
            let key = EpisodeKey(rawValue: state.episodeKey)
            let expiry = overrides.first { key.belongs(to: $0.show) }?.expiry ?? global
            guard case .days(let days) = expiry, let enteredAt = state.movedAt,
                  expiry.hasExpired(enteredAt: enteredAt, now: now) else { continue }
            try relocate(state, to: .archive(.expired), reason: .expired(days: days))
        }
        try modelContext.save()
    }

    // MARK: Undo

    public func lastMove(of key: EpisodeKey) throws -> LastMove? {
        guard let state = try state(key), let raw = state.moveReason, let reason = MoveReason(stored: raw) else { return nil }
        let recent = state.movedAt.map { clock().timeIntervalSince($0) < LastMove.undoWindow } ?? false
        return LastMove(reason: reason, canUndo: reason.isUndoable && recent)
    }

    /// Returns the episode to where it was before its latest automatic move. The restore is the
    /// listener's move, so it has no Undo, and an episode back in the Inbox starts a new period.
    public func undo(_ key: EpisodeKey) throws {
        guard let move = try lastMove(of: key), move.canUndo, let state = try state(key) else { return }
        try relocate(state, to: move.reason.placeBefore, reason: .listener)
        try modelContext.save()
    }

    // MARK: Queue

    /// Episode keys in play order. The first is Now Playing.
    public func queue() throws -> [EpisodeKey] {
        try states(in: .queue).map { EpisodeKey(rawValue: $0.episodeKey) }
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

    /// The episode ends up with no place and keeps its progress.
    public func removeFromQueue(_ key: EpisodeKey) throws {
        guard let state = try state(key), state.place == Place.queue.stored.place else { return }
        try relocate(state, to: nil, reason: .listener)
        try modelContext.save()
    }

    /// Play-next episodes go after Now Playing and after earlier play-next episodes.
    private func playNextIndex(in queued: [EpisodeState]) -> Int {
        var index = min(1, queued.count)
        while index < queued.count, queued[index].moveReason == MoveReason.playNext.stored {
            index += 1
        }
        return index
    }

    private func renumber(_ states: [EpisodeState]) {
        for (index, state) in states.enumerated() {
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
            queued.insert(state, at: reason == .playNext ? playNextIndex(in: queued) : queued.count)
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
        try settings().speed = speed.value
        try modelContext.save()
    }

    public func effectiveSpeed(for showKey: ShowKey) throws -> PlaybackSpeed {
        PlaybackSpeed.effective(
            global: try globalSpeed(),
            override: try subscription(showKey)?.speedOverride.map(PlaybackSpeed.init)
        )
    }

    public func globalExpiry() throws -> InboxExpiry {
        InboxExpiry(storedDays: try settings().expiryDays)
    }

    public func setGlobalExpiry(_ expiry: InboxExpiry) throws {
        try settings().expiryDays = expiry.storedDays
        try modelContext.save()
    }

    public func downloadCount() throws -> Int {
        try settings().downloadCount
    }

    public func setDownloadCount(_ count: Int) throws {
        try settings().downloadCount = max(count, 0)
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
        }
        try modelContext.save()
    }

    public func recordRefreshFailure(_ showKey: ShowKey, error: String) throws {
        let raw = showKey.rawValue
        try modelContext.fetch(FetchDescriptor<ShowRecord>(predicate: #Predicate { $0.key == raw })).first?
            .lastRefreshError = error
        try modelContext.save()
    }

    public func show(_ showKey: ShowKey) throws -> ShowInfo? {
        let raw = showKey.rawValue
        return try modelContext.fetch(FetchDescriptor<ShowRecord>(predicate: #Predicate { $0.key == raw })).first
            .map { ShowInfo(
                key: showKey, title: $0.title, author: $0.author, artworkURL: $0.artworkURL, summary: $0.summary,
                lastRefreshSuccess: $0.lastRefreshSuccess, lastRefreshError: $0.lastRefreshError
            ) }
    }

    /// Newest first; episodes without a date come last.
    public func episodes(of showKey: ShowKey) throws -> [EpisodeInfo] {
        try episodeRecords(of: showKey)
            .sorted { ($0.publishDate ?? .distantPast) > ($1.publishDate ?? .distantPast) }
            .map(info)
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
    public func wipeFeedCache() throws {
        try modelContext.delete(model: EpisodeRecord.self)
        try modelContext.delete(model: ShowRecord.self)
        try modelContext.save()
    }

    private func info(_ record: EpisodeRecord) -> EpisodeInfo {
        EpisodeInfo(
            key: EpisodeKey(rawValue: record.key), showKey: ShowKey(rawValue: record.showKey), title: record.title,
            audioURL: record.audioURL, publishDate: record.publishDate, duration: record.duration, summary: record.summary
        )
    }
}
