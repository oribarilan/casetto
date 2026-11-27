import Foundation
import Testing

@testable import CasterrCore

/// Serves the chart, lookup, and search fixtures by path.
private final class DirectoryStub: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let url = request.url!
        let name =
            url.path().hasSuffix("podcasts.json")
            ? "chart.json" : url.path() == "/lookup" ? "lookup.json" : "search.json"
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: try! fixture(name))
        client?.urlProtocolDidFinishLoading(self)
    }
}

/// Fails every request as offline.
private final class OfflineStub: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}
    override func startLoading() { client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)) }
}

/// Fails the first chart request with a 502, then serves fixtures like `DirectoryStub`.
private final class FlakyChartStub: URLProtocol {
    nonisolated(unsafe) static var chartRequests = 0
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let url = request.url!
        let isChart = url.path().hasSuffix("podcasts.json")
        if isChart { Self.chartRequests += 1 }
        let failing = isChart && Self.chartRequests == 1
        let name = isChart ? "chart.json" : "lookup.json"
        let response = HTTPURLResponse(url: url, statusCode: failing ? 502 : 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: failing ? Data() : try! fixture(name))
        client?.urlProtocolDidFinishLoading(self)
    }
}

private func directory(_ stub: URLProtocol.Type) -> AppleDirectory {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [stub]
    return AppleDirectory(session: URLSession(configuration: config))
}

struct AppleDirectoryTests {
    @Test func topShowsKeepChartOrderAndDropShowsWithoutAFeed() async throws {
        let shows = try await directory(DirectoryStub.self).topShows(country: "us", limit: 3)
        #expect(shows.map(\.id) == ["1200361736", "1464919521"])
        #expect(shows.first?.title == "The Daily")
        #expect(shows.first?.feedURL == URL(string: "https://feeds.simplecast.com/Sl5CSM3S"))
        #expect(shows.first?.artworkURL != nil)
    }

    @Test func searchReturnsShowsWithFeedsOncePerFeed() async throws {
        let shows = try await directory(DirectoryStub.self).search("planet money", country: "us")
        #expect(shows.map(\.title) == ["Planet Money", "The Indicator from Planet Money"])
        #expect(shows.first?.feedURL == URL(string: "https://feeds.npr.org/510289/podcast.xml"))
        #expect(shows.first?.author == "NPR")
    }

    @Test func chartFailureIsRetriedOnce() async throws {
        let shows = try await directory(FlakyChartStub.self).topShows(country: "us", limit: 3)
        #expect(FlakyChartStub.chartRequests == 2)
        #expect(shows.count == 2)
    }

    @Test func offlineIsUnreachable() async {
        await #expect(throws: DirectoryError.unreachable) {
            try await directory(OfflineStub.self).topShows(country: "us")
        }
        await #expect(throws: DirectoryError.unreachable) {
            try await directory(OfflineStub.self).search("x", country: "us")
        }
    }
}

struct OPMLWriterTests {
    @Test func roundTripsThroughTheParser() throws {
        let feeds = [
            (title: "Tom & Jerry's \"Show\" <live>", url: URL(string: "https://example.com/feed?a=1&b=2")!),
            (title: "Plain", url: URL(string: "https://example.org/rss")!),
        ]
        let parsed = try OPMLParser.parse(OPMLWriter.write(feeds))
        #expect(parsed.feeds.map(\.title) == feeds.map(\.title))
        #expect(parsed.feeds.map(\.url) == feeds.map(\.url))
        #expect(parsed.invalidEntries.isEmpty)
    }
}

/// Serves the episode lookup fixture.
private final class EpisodeLookupStub: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}
    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: try! fixture("episode-lookup.json"))
        client?.urlProtocolDidFinishLoading(self)
    }
}

struct ApplePodcastsLinkTests {
    @Test func readsShowAndEpisode() {
        let link = ApplePodcastsLink(
            URL(string: "https://podcasts.apple.com/us/podcast/the-warp-zone/id617416468?i=1000803195167")!)
        #expect(link?.showID == "617416468" && link?.episodeID == "1000803195167")
    }

    @Test func aShowLinkIsNotAnEpisode() {
        #expect(ApplePodcastsLink(URL(string: "https://podcasts.apple.com/us/podcast/atp/id617416468")!) == nil)
    }

    @Test func otherLinksAreNotApplePodcasts() {
        #expect(ApplePodcastsLink(URL(string: "https://overcast.fm/+abc?i=123")!) == nil)
        #expect(ApplePodcastsLink(URL(string: "https://example.com/podcast/id617416468?i=1000803195167")!) == nil)
    }

    @Test func findsTheLinkedEpisode() async throws {
        let link = try #require(
            ApplePodcastsLink(URL(string: "https://podcasts.apple.com/us/podcast/x/id617416468?i=1000801592580")!))
        let episode = try await directory(EpisodeLookupStub.self).episode(for: link)
        #expect(
            episode
                == DirectoryEpisode(
                    title: "Two Hot Streaks", feedURL: URL(string: "https://cdn.atp.fm/rss/public?wtvryzdm")!,
                    guid: "t3vbwlfpueremdht", audioURL: URL(string: "https://atp.fm/audio/t3vbwlfpueremdht/atp717.mp3")!
                ))
    }

    @Test func anEpisodeAppleDoesNotListIsNil() async throws {
        let link = try #require(
            ApplePodcastsLink(URL(string: "https://podcasts.apple.com/us/podcast/x/id617416468?i=42")!))
        #expect(try await directory(EpisodeLookupStub.self).episode(for: link) == nil)
    }

    @Test func offlineIsUnreachable() async throws {
        let link = try #require(
            ApplePodcastsLink(URL(string: "https://podcasts.apple.com/us/podcast/x/id617416468?i=42")!))
        await #expect(throws: DirectoryError.unreachable) { try await directory(OfflineStub.self).episode(for: link) }
    }
}
