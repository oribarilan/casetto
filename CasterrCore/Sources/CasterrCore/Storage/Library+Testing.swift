import Foundation
import SwiftData

/// Raw inserts that stand in for records another device created before syncing. Internal, for tests.
extension Library {
    func insertStateForTesting(_ key: EpisodeKey, place: Place?, queuePosition: Int? = nil, firstPlayedAt: Date? = nil)
        throws
    {
        let state = EpisodeState(episodeKey: key.rawValue)
        state.place = place?.stored.place
        state.archiveReason = place?.stored.archiveReason
        state.queuePosition = queuePosition
        state.firstPlayedAt = firstPlayedAt
        state.moveReason = MoveReason.listener.stored
        state.movedAt = now()
        modelContext.insert(state)
        try modelContext.save()
    }

    func insertSubscriptionForTesting(_ show: ShowKey) throws {
        let subscription = Subscription(showKey: show.rawValue, feedURL: URL(string: show.rawValue)!)
        subscription.subscribedAt = now()
        modelContext.insert(subscription)
        try modelContext.save()
    }

    func insertDefaultSettingsForTesting() throws {
        modelContext.insert(UserSettings())
        try modelContext.save()
    }

    func setRawButtonActionsForTesting(double: String, triple: String) throws {
        let settings = try modelContext.fetch(FetchDescriptor<UserSettings>()).first ?? UserSettings()
        if settings.modelContext == nil { modelContext.insert(settings) }
        settings.doublePress = double
        settings.triplePress = triple
        try modelContext.save()
    }

    func settingsUpdatedAtForTesting() throws -> Date {
        try modelContext.fetch(FetchDescriptor<UserSettings>()).first?.updatedAt ?? .distantPast
    }

    func stateCountForTesting(_ key: EpisodeKey) throws -> Int {
        let raw = key.rawValue
        return try modelContext.fetchCount(
            FetchDescriptor<EpisodeState>(predicate: #Predicate { $0.episodeKey == raw }))
    }
}
