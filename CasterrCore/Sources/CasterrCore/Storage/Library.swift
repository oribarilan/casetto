import Foundation
import SwiftData

public struct SubscriptionInfo: Equatable, Sendable {
    public var showKey: ShowKey
    public var feedURL: URL
    public var speedOverride: PlaybackSpeed?
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
    @discardableResult
    public func addSubscription(_ showKey: ShowKey, feedURL: URL) throws -> Bool {
        guard try subscription(showKey) == nil else { return false }
        modelContext.insert(Subscription(showKey: showKey.rawValue, feedURL: feedURL))
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
                    speedOverride: record.speedOverride.map(PlaybackSpeed.init)
                )
            }
    }

    public func isSubscribed(_ showKey: ShowKey) throws -> Bool {
        try subscription(showKey) != nil
    }

    /// Queued episodes of the show stay in the Queue.
    public func removeSubscription(_ showKey: ShowKey) throws {
        guard let record = try subscription(showKey) else { return }
        modelContext.delete(record)
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

    private func subscription(_ showKey: ShowKey) throws -> Subscription? {
        let key = showKey.rawValue
        return try modelContext.fetch(FetchDescriptor<Subscription>(predicate: #Predicate { $0.showKey == key })).first
    }

    // MARK: Queue

    /// Episode keys in play order. The first is Now Playing.
    public func queue() throws -> [EpisodeKey] {
        try queuedStates().map { EpisodeKey(rawValue: $0.episodeKey) }
    }

    /// Adds to the end. An episode already in the Queue keeps its position.
    public func addToQueue(_ key: EpisodeKey) throws {
        let state = try state(key, creating: true)!
        guard state.place != Place.queue.stored.place else { return }
        var queued = try queuedStates()
        setPlace(.queue, on: state)
        queued.append(state)
        renumber(queued)
        try modelContext.save()
    }

    /// Moves a queued episode to `index` (0 is Now Playing). Others keep their relative order.
    public func move(_ key: EpisodeKey, to index: Int) throws {
        var queued = try queuedStates()
        guard let from = queued.firstIndex(where: { $0.episodeKey == key.rawValue }) else { return }
        let state = queued.remove(at: from)
        queued.insert(state, at: min(max(index, 0), queued.count))
        renumber(queued)
        try modelContext.save()
    }

    /// Puts the episode first, adding it to the Queue if needed. Used when playback starts.
    public func moveToTop(_ key: EpisodeKey) throws {
        try addToQueue(key)
        try move(key, to: 0)
    }

    /// The episode ends up with no place and keeps its progress.
    public func removeFromQueue(_ key: EpisodeKey) throws {
        guard let state = try state(key), state.place == Place.queue.stored.place else { return }
        setPlace(nil, on: state)
        renumber(try queuedStates())
        try modelContext.save()
    }

    private func queuedStates() throws -> [EpisodeState] {
        let queue = Place.queue.stored.place
        return try modelContext.fetch(FetchDescriptor<EpisodeState>(
            predicate: #Predicate { $0.place == queue },
            sortBy: [SortDescriptor(\.queuePosition)]
        ))
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
        let state = try state(key, creating: true)!
        let wasQueued = state.place == Place.queue.stored.place
        setPlace(.archive(.played), on: state)
        if wasQueued { renumber(try queuedStates()) }
        try modelContext.save()
    }

    /// Resets progress. An archived episode ends up with no place; a queued one stays queued.
    public func markUnplayed(_ key: EpisodeKey) throws {
        guard let state = try state(key) else { return }
        if state.place == Place.archive(.played).stored.place {
            setPlace(nil, on: state)
        }
        state.progressSeconds = 0
        try modelContext.save()
    }

    private func setPlace(_ place: Place?, on state: EpisodeState) {
        state.place = place?.stored.place
        state.archiveReason = place?.stored.archiveReason
        if place != .queue { state.queuePosition = nil }
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
        let raw = showKey.rawValue
        return try modelContext.fetch(FetchDescriptor<EpisodeRecord>(predicate: #Predicate { $0.showKey == raw }))
            .sorted { ($0.publishDate ?? .distantPast) > ($1.publishDate ?? .distantPast) }
            .map(info)
    }

    public func episode(_ key: EpisodeKey) throws -> EpisodeInfo? {
        let raw = key.rawValue
        return try modelContext.fetch(FetchDescriptor<EpisodeRecord>(predicate: #Predicate { $0.key == raw })).first.map(info)
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
