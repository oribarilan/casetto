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
    /// Where the feed was fetched from, for a show reached without subscribing (a shared episode).
    var feedURL: URL?
    var webPage: URL?

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
    var webPage: URL?
    var byteLength: Int64?

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
    /// Nil follows the global voice boost setting.
    var voiceBoostOverride: Bool?
    var subscribedAt: Date = Date.distantPast
    var level: String = TriageLevel.inbox.rawValue
    /// A favorite, separate from where new episodes go.
    var starred: Bool = false
    /// Days, with 0 for never. Nil follows the global setting.
    var expiryDaysOverride: Int?
    /// Episodes published after this date, and never placed, are new. Nil until the first triage.
    var triageAfter: Date?
    /// When each card may show again. Nil means it may show now; `distantFuture` means never.
    var autoQueueCardHiddenUntil: Date?
    var ignoredCardHiddenUntil: Date?

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
    var moveReason: String?
    var movedAt: Date?
    /// When playback first started. Set once; the Auto-queue card reads it.
    var firstPlayedAt: Date?

    init(episodeKey: String) {
        self.episodeKey = episodeKey
    }
}

@Model final class UserSettings {
    var speed: Double = 1.0
    var voiceBoost: Bool = false
    /// Days, with 0 for never.
    var expiryDays: Int = 14
    /// How many Queue episodes to keep downloaded, with 0 for Off.
    var downloadCount: Int = 3
    /// `ButtonAction` raw values for the AirPods double and triple press.
    var doublePress: String = ButtonAction.doublePressDefault.rawValue
    var triplePress: String = ButtonAction.triplePressDefault.rawValue
    /// When the listener last changed a setting. Defaults that were never changed keep `distantPast`.
    var updatedAt: Date = Date.distantPast

    init() {}
}

/// A saved moment. It keeps a snapshot of the titles and audio address, so it survives the feed cache.
@Model final class Bookmark {
    var id: UUID = UUID()
    var episodeKey: String = ""
    var position: Double = 0
    /// Empty means no note.
    var note: String = ""
    var createdAt: Date = Date.distantPast
    var showTitle: String = ""
    var episodeTitle: String = ""
    var audioURL: URL?

    init(episodeKey: String, position: Double, showTitle: String, episodeTitle: String, audioURL: URL, createdAt: Date)
    {
        self.episodeKey = episodeKey
        self.position = position
        self.showTitle = showTitle
        self.episodeTitle = episodeTitle
        self.audioURL = audioURL
        self.createdAt = createdAt
    }
}

enum Schemas {
    static let feedCache = Schema([ShowRecord.self, EpisodeRecord.self])
    static let userData = Schema([Subscription.self, EpisodeState.self, UserSettings.self, Bookmark.self])
}
