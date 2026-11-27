import FeedKit
import Foundation

public struct ParsedShow: Equatable, Sendable {
    public var title: String
    public var author: String?
    public var artworkURL: URL?
    public var description: String?
    /// The feed's `itunes:new-feed-url`, when it declares a move.
    public var newFeedURL: URL?
    public var episodes: [ParsedEpisode]
    /// The channel's `<link>`.
    public var webPage: URL?
}

public struct ParsedEpisode: Equatable, Sendable {
    public var guid: String?
    public var title: String
    public var audioURL: URL
    public var publishDate: Date?
    /// In seconds.
    public var duration: TimeInterval?
    public var description: String?
    /// The item's `<link>`, or nil when it's the show's page or another item's too.
    public var webPage: URL?
    /// The file size the enclosure lists, often missing or wrong.
    public var byteLength: Int64?
}

public enum FeedParseError: Error, Equatable {
    /// The data is not a parsable RSS document.
    case malformed
    /// The feed parsed, but no item has an audio enclosure.
    case notPodcast
}

public enum FeedParser {
    public static func parse(_ data: Data) throws(FeedParseError) -> ParsedShow {
        let channel: RSSFeedChannel?
        do {
            channel = try RSSFeed(data: data).channel
        } catch {
            throw .malformed
        }
        var episodes = (channel?.items ?? []).compactMap(episode)
        guard let channel, !episodes.isEmpty else { throw .notPodcast }

        let showPage = url(channel.link)
        let linkCounts = Dictionary(episodes.compactMap(\.webPage).map { ($0, 1) }, uniquingKeysWith: +)
        for index in episodes.indices {
            if let page = episodes[index].webPage, page == showPage || linkCounts[page, default: 0] > 1 {
                episodes[index].webPage = nil
            }
        }

        return ParsedShow(
            title: channel.title ?? "",
            author: channel.iTunes?.author,
            artworkURL: url(channel.iTunes?.image?.attributes?.href ?? channel.image?.url),
            description: channel.description,
            newFeedURL: url(channel.iTunes?.newFeedURL),
            episodes: episodes,
            webPage: showPage
        )
    }

    /// Returns nil for items without an audio enclosure. An enclosure with no type counts as audio.
    private static func episode(_ item: RSSFeedItem) -> ParsedEpisode? {
        guard let enclosure = item.enclosure?.attributes,
            enclosure.type?.hasPrefix("audio/") ?? true,
            let audioURL = url(enclosure.url)
        else { return nil }

        return ParsedEpisode(
            guid: item.guid?.text,
            title: item.title ?? "",
            audioURL: audioURL,
            publishDate: item.pubDate,
            duration: item.iTunes?.duration,
            description: item.description,
            webPage: url(item.link),
            byteLength: enclosure.length
        )
    }

    private static func url(_ string: String?) -> URL? {
        string.flatMap { URL(string: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }
}
