import Foundation
import Testing
@testable import CasterrCore

/// Routes by URL, with no shared state:
/// `…/offline.xml` fails offline, `…/missing.xml` is a 404, `/not-podcast.xml`, `/new-feed-url.xml`
/// and `/new-episode.xml` serve those fixtures, and anything else serves `podcast.xml`.
private final class FeedStub: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let url = request.url!
        switch url.lastPathComponent {
        case "offline.xml":
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        case "missing.xml":
            respond(status: 404, body: Data())
        case "not-podcast.xml", "new-feed-url.xml", "new-episode.xml":
            respond(status: 200, body: try! fixture(url.lastPathComponent))
        default:
            respond(status: 200, body: try! fixture("podcast.xml"))
        }
    }

    private func respond(status: Int, body: Data) {
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
}

private func makeService() throws -> (FeedService, Library) {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [FeedStub.self]
    let library = try Library.open(inMemory: true)
    return (FeedService(library: library, fetcher: FeedFetcher(session: URLSession(configuration: config))), library)
}

private func url(_ string: String) -> URL { URL(string: string)! }

private func opml(_ urls: [String]) -> Data {
    let outlines = urls.map { "<outline type=\"rss\" text=\"\($0)\" xmlUrl=\"\($0)\"/>" }.joined()
    return Data("<?xml version=\"1.0\"?><opml version=\"2.0\"><head/><body>\(outlines)</body></opml>".utf8)
}

struct SubscribeTests {
    @Test func validFeedSubscribesAndSavesEpisodes() async throws {
        let (service, library) = try makeService()
        let outcome = try await service.subscribe(to: url("https://example.com/show.xml"))
        let key = ShowKey(feedURL: url("https://example.com/show.xml"))!
        #expect(outcome == .subscribed(key))
        #expect(try await library.show(key)?.title.isEmpty == false)
        #expect(try await !library.episodes(of: key).isEmpty)
    }

    @Test func subscribingPutsNothingInTheQueue() async throws {
        let (service, library) = try makeService()
        _ = try await service.subscribe(to: url("https://example.com/show.xml"))
        #expect(try await library.queue().isEmpty)
    }

    @Test func notAPodcastDoesNotSubscribe() async throws {
        let (service, library) = try makeService()
        await #expect(throws: SubscribeError.notAPodcast) {
            try await service.subscribe(to: url("https://example.com/not-podcast.xml"))
        }
        #expect(try await library.subscriptions().isEmpty)
    }

    @Test func unreachableFeedDoesNotSubscribe() async throws {
        let (service, library) = try makeService()
        await #expect(throws: SubscribeError.unreachable) {
            try await service.subscribe(to: url("https://example.com/offline.xml"))
        }
        await #expect(throws: SubscribeError.unreachable) {
            try await service.subscribe(to: url("https://example.com/missing.xml"))
        }
        #expect(try await library.subscriptions().isEmpty)
    }

    @Test func sameFeedInAnotherURLFormIsAlreadySubscribed() async throws {
        let (service, library) = try makeService()
        _ = try await service.subscribe(to: url("https://example.com/show.xml"))
        let again = try await service.subscribe(to: url("http://EXAMPLE.com/show.xml/"))
        #expect(again == .alreadySubscribed(ShowKey(feedURL: url("https://example.com/show.xml"))!))
        #expect(try await library.subscriptions().count == 1)
    }

    @Test func nonWebURLIsRejected() async throws {
        let (service, _) = try makeService()
        await #expect(throws: SubscribeError.invalidURL) {
            try await service.subscribe(to: url("ftp://example.com/show.xml"))
        }
    }
}

struct OPMLImportTests {
    @Test func validFileSubscribesToEveryFeed() async throws {
        let (service, library) = try makeService()
        let report = try await service.importOPML(try fixture("valid.opml"))
        #expect(report.subscribed.count == 3)
        #expect(report.failures.isEmpty)
        #expect(try await library.subscriptions().count == 3)
    }

    @Test func failingFeedsAreReportedAndTheRestSubscribe() async throws {
        let (service, _) = try makeService()
        let report = try await service.importOPML(opml([
            "https://example.com/a.xml", "https://example.com/offline.xml", "https://example.com/not-podcast.xml",
        ]))
        #expect(report.subscribed == [ShowKey(feedURL: url("https://example.com/a.xml"))!])
        #expect(Set(report.failures.map(\.reason)) == ["Couldn't reach the feed", "Not a podcast feed"])
    }

    @Test func badEntriesAreReported() async throws {
        let (service, _) = try makeService()
        let report = try await service.importOPML(try fixture("bad-entries.opml"))
        #expect(report.subscribed.count == 1)
        #expect(!report.failures.isEmpty)
    }

    @Test func alreadyFollowedShowsAreSkipped() async throws {
        let (service, library) = try makeService()
        _ = try await service.subscribe(to: url("https://example.com/tape-hiss.xml"))
        let report = try await service.importOPML(try fixture("valid.opml"))
        #expect(report.alreadySubscribed == [ShowKey(feedURL: url("https://example.com/tape-hiss.xml"))!])
        #expect(try await library.subscriptions().count == 3)
    }

    @Test func fileThatIsNotOPMLImportsNothing() async throws {
        let (service, library) = try makeService()
        await #expect(throws: OPMLError.notOPML) {
            try await service.importOPML(try fixture("not-opml.xml"))
        }
        #expect(try await library.subscriptions().isEmpty)
    }
}

struct RefreshTests {
    @Test func oneFailingFeedDoesNotStopTheOthers() async throws {
        let (service, library) = try makeService()
        _ = try await service.subscribe(to: url("https://example.com/good.xml"))
        _ = try await service.subscribe(to: url("https://example.com/going-offline.xml"))
        let failing = ShowKey(feedURL: url("https://example.com/going-offline.xml"))!
        try await library.updateFeedURL(failing, to: url("https://example.com/offline.xml"))

        try await service.refreshAll()

        let good = try #require(try await library.show(ShowKey(feedURL: url("https://example.com/good.xml"))!))
        #expect(good.lastRefreshError == nil)
        let bad = try #require(try await library.show(failing))
        #expect(bad.lastRefreshError == "Couldn't reach the feed")
        #expect(bad.lastRefreshSuccess != nil)
    }

    @Test func feedMoveUpdatesTheURLAndKeepsTheKey() async throws {
        let (service, library) = try makeService()
        _ = try await service.subscribe(to: url("https://example.com/new-feed-url.xml"))
        try await service.refreshAll()
        let subscription = try #require(try await library.subscriptions().first)
        #expect(subscription.showKey == ShowKey(feedURL: url("https://example.com/new-feed-url.xml"))!)
        #expect(subscription.feedURL == url("https://new.example.com/moving-day.xml"))
    }
}

struct UnsubscribeTests {
    @Test func unsubscribedFeedIsNoLongerRefreshedAndQueueStays() async throws {
        let (service, library) = try makeService()
        _ = try await service.subscribe(to: url("https://example.com/show.xml"))
        let key = ShowKey(feedURL: url("https://example.com/show.xml"))!
        let queued = try #require(try await library.episodes(of: key).first).key
        try await library.addToQueue(queued)
        let refreshedAt = try await library.show(key)?.lastRefreshSuccess

        try await service.unsubscribe(key)
        try await service.refreshAll()

        #expect(try await library.subscriptions().isEmpty)
        #expect(try await library.queue() == [queued])
        #expect(try await library.show(key)?.lastRefreshSuccess == refreshedAt)
    }
}

struct TriageFlowTests {
    private let show = url("https://example.com/show.xml")
    private var key: ShowKey { ShowKey(feedURL: show)! }

    private func episode(_ guid: String) -> EpisodeKey {
        EpisodeKey(show: key, guid: guid, audioURL: url("https://example.com/unused.mp3"))
    }

    @Test func subscribePutsTheNewestEpisodeInTheInbox() async throws {
        let (service, library) = try makeService()
        _ = try await service.subscribe(to: show)
        #expect(try await library.inbox() == [episode("tape-hiss-3")])
        #expect(try await library.queue().isEmpty)
    }

    @Test(arguments: [
        (TriageLevel.inbox, Place.inbox), (.autoQueue, .queue), (.playNext, .queue), (.skip, .archive(.skipped)),
    ])
    func refreshPlacesTheNewEpisodeByLevel(level: TriageLevel, place: Place) async throws {
        let (service, library) = try makeService()
        _ = try await service.subscribe(to: show)
        try await library.setLevel(key, to: level)
        try await library.updateFeedURL(key, to: url("https://example.com/new-episode.xml"))
        try await service.refreshAll()
        #expect(try await library.place(of: episode("tape-hiss-4")) == place)
        #expect(try await library.place(of: episode("tape-hiss-2")) == nil)
    }

    @Test func unsubscribeArchivesInboxEpisodes() async throws {
        let (service, library) = try makeService()
        _ = try await service.subscribe(to: show)
        try await service.unsubscribe(key)
        #expect(try await library.inbox().isEmpty)
        #expect(try await library.place(of: episode("tape-hiss-3")) == .archive(.unsubscribed))
    }
}
