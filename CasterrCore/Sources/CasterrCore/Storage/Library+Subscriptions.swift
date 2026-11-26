import Foundation
import SwiftData

extension Library {
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
}
