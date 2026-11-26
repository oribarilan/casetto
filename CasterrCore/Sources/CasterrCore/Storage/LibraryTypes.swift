import Foundation

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
    public var plainSummary: String? { HTMLText.plain(summary) }
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
    /// The episode's description without HTML tags or entities, with runs of whitespace collapsed.
    public var plainSummary: String? { HTMLText.plain(summary) }
    /// The episode's own page from its feed.
    public var webPage: URL?
    /// The file size the feed lists, often missing or wrong.
    public var byteLength: Int64?
}
