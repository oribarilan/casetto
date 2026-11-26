import Foundation
import SwiftData

/// The app's only access to storage. It owns one long-lived context and hands out value types only.
public actor Library: ModelActor {
    public nonisolated let modelContainer: ModelContainer
    public nonisolated let modelExecutor: any ModelExecutor
    var clock: @Sendable () -> Date = { Date.now }
    var ruleThresholds = RuleCard.Thresholds()

    /// Replaces the clock that move times and expiry use. For tests.
    public func useClock(_ clock: @escaping @Sendable () -> Date) {
        self.clock = clock
    }

    func now() -> Date { clock() }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        modelExecutor = LibraryExecutor(container: modelContainer)
    }

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

    // MARK: Shared helpers

    func subscription(_ showKey: ShowKey) throws -> Subscription? {
        let key = showKey.rawValue
        return try modelContext.fetch(FetchDescriptor<Subscription>(predicate: #Predicate { $0.showKey == key })).first
    }

    /// Changes the episode's place, records the move, and keeps the Queue numbered 1 to N.
    /// Moving an episode to the place it's in only records the move.
    func relocate(_ state: EpisodeState, to place: Place?, reason: MoveReason) throws {
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
    func states(in place: Place) throws -> [EpisodeState] {
        let raw = place.stored.place
        return try modelContext.fetch(FetchDescriptor<EpisodeState>(
            predicate: #Predicate { $0.place == raw },
            sortBy: [SortDescriptor(\.queuePosition)]
        ))
    }

    func state(_ key: EpisodeKey, creating: Bool = false) throws -> EpisodeState? {
        let raw = key.rawValue
        if let existing = try modelContext.fetch(FetchDescriptor<EpisodeState>(predicate: #Predicate { $0.episodeKey == raw })).first {
            return existing
        }
        guard creating else { return nil }
        let state = EpisodeState(episodeKey: raw)
        modelContext.insert(state)
        return state
    }

    func renumber(_ states: [EpisodeState]) {
        for (index, state) in states.enumerated() where state.queuePosition != index + 1 {
            state.queuePosition = index + 1
        }
    }

    func episodeRecord(_ key: EpisodeKey) throws -> EpisodeRecord? {
        let raw = key.rawValue
        return try modelContext.fetch(FetchDescriptor<EpisodeRecord>(predicate: #Predicate { $0.key == raw })).first
    }

    func episodeRecords(of showKey: ShowKey) throws -> [EpisodeRecord] {
        let raw = showKey.rawValue
        return try modelContext.fetch(FetchDescriptor<EpisodeRecord>(predicate: #Predicate { $0.showKey == raw }))
    }
}
