import Foundation

/// A show from a podcast directory, with the feed address needed to subscribe.
public struct DirectoryShow: Equatable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var author: String?
    public var artworkURL: URL?
    public var feedURL: URL
}

public enum DirectoryError: Error, Equatable {
    case unreachable
}

/// Apple's documented top podcasts chart, plus the iTunes lookup and search endpoints. None need a key.
public struct AppleDirectory: Sendable {
    let session: URLSession

    public init(session: URLSession = AppleDirectory.defaultSession) {
        self.session = session
    }

    /// Gives up after 10 seconds, so a slow directory shows its error instead of loading for a minute.
    public static let defaultSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

    /// The device region, lowercased, or `us`.
    public static var deviceCountry: String {
        Locale.current.region?.identifier.lowercased() ?? "us"
    }

    /// Top shows in chart order. The chart has no feed addresses, so one lookup call adds them;
    /// shows the lookup can't give a feed address for are left out.
    public func topShows(country: String = deviceCountry, limit: Int = 25) async throws(DirectoryError) -> [DirectoryShow] {
        let chartURL = URL(string: "https://rss.marketingtools.apple.com/api/v2/\(country)/podcasts/top/\(limit)/podcasts.json")!
        // The chart endpoint fails now and then on its own; one retry hides most of those.
        let chart: Chart
        do { chart = try await get(chartURL) } catch { chart = try await get(chartURL) }
        let ids = chart.feed.results.map(\.id)
        guard !ids.isEmpty else { return [] }
        var lookup = URLComponents(string: "https://itunes.apple.com/lookup")!
        lookup.queryItems = [
            URLQueryItem(name: "id", value: ids.joined(separator: ",")),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "country", value: country),
        ]
        let found: ITunesResults = try await get(lookup.url!)
        let byID = Dictionary(found.shows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { byID[$0] }
    }

    /// Up to 25 shows matching the term.
    public func search(_ term: String, country: String = deviceCountry) async throws(DirectoryError) -> [DirectoryShow] {
        var search = URLComponents(string: "https://itunes.apple.com/search")!
        search.queryItems = [
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "limit", value: "25"),
            URLQueryItem(name: "country", value: country),
        ]
        let found: ITunesResults = try await get(search.url!)
        return found.shows
    }

    private func get<T: Decodable>(_ url: URL) async throws(DirectoryError) -> T {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw DirectoryError.unreachable
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw .unreachable
        }
    }
}

private struct Chart: Decodable {
    struct Feed: Decodable { var results: [Entry] }
    struct Entry: Decodable { var id: String }
    var feed: Feed
}

private struct ITunesResults: Decodable {
    struct Result: Decodable {
        var collectionId: Int?
        var collectionName: String?
        var artistName: String?
        var feedUrl: String?
        var artworkUrl600: String?
    }

    var results: [Result]

    /// Shows with a usable feed address. Apple sometimes lists one feed under two IDs; the first is kept.
    var shows: [DirectoryShow] {
        var seen: Set<ShowKey> = []
        return results.compactMap { result in
            guard let id = result.collectionId, let title = result.collectionName,
                  let feed = result.feedUrl.flatMap(URL.init(string:)), let key = ShowKey(feedURL: feed),
                  seen.insert(key).inserted
            else { return nil }
            return DirectoryShow(
                id: String(id), title: title, author: result.artistName,
                artworkURL: result.artworkUrl600.flatMap(URL.init(string:)), feedURL: feed
            )
        }
    }
}
