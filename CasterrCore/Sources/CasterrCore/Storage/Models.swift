import Foundation
import SwiftData

// MARK: Feed cache: re-fetchable, never synced.

@Model final class ShowRecord {
    @Attribute(.unique) var key: String
    var title: String
    var author: String?
    var artworkURL: URL?
    var summary: String?
    var lastRefreshSuccess: Date?
    var lastRefreshError: String?

    init(key: String, title: String) {
        self.key = key
        self.title = title
    }
}

@Model final class EpisodeRecord {
    #Index<EpisodeRecord>([\.showKey])

    @Attribute(.unique) var key: String
    var showKey: String
    var title: String
    var audioURL: URL
    var publishDate: Date?
    var duration: TimeInterval?
    var summary: String?

    init(key: String, showKey: String, title: String, audioURL: URL) {
        self.key = key
        self.showKey = showKey
        self.title = title
        self.audioURL = audioURL
    }
}

// MARK: User data: follows the CloudKit rules (no unique attributes,
// every property optional or defaulted, no relationships) so M8 can sync it.

@Model final class Subscription {
    var showKey: String = ""
    var feedURL: URL?
    var speedOverride: Double?
    var subscribedAt: Date = Date.distantPast

    init(showKey: String, feedURL: URL) {
        self.showKey = showKey
        self.feedURL = feedURL
        self.subscribedAt = .now
    }
}

@Model final class EpisodeState {
    var episodeKey: String = ""
    var place: String?
    var archiveReason: String?
    var queuePosition: Int?
    var progressSeconds: Double = 0

    init(episodeKey: String) {
        self.episodeKey = episodeKey
    }
}

@Model final class UserSettings {
    var speed: Double = 1.0

    init() {}
}

enum Schemas {
    static let feedCache = Schema([ShowRecord.self, EpisodeRecord.self])
    static let userData = Schema([Subscription.self, EpisodeState.self, UserSettings.self])
}
