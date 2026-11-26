import Foundation
import SwiftData

extension Library {
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
            record.byteLength = parsed.byteLength
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
            webPage: record.webPage, byteLength: record.byteLength
        )
    }
}
