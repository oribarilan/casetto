import Foundation
import Testing
@testable import CasterrCore

struct FeedParserTests {
    @Test func parsesPodcastFeed() throws {
        let show = try FeedParser.parse(fixture("podcast.xml"))

        #expect(show.title == "Tape Hiss")
        #expect(show.author == "Ada Reel")
        #expect(show.artworkURL == URL(string: "https://example.com/tape-hiss/art.jpg"))
        #expect(show.description == "A show about cassette culture.")
        #expect(show.newFeedURL == nil)
        #expect(show.episodes.map(\.guid) == ["tape-hiss-3", "tape-hiss-2", "tape-hiss-1"])
    }

    @Test func parsesEpisodeFields() throws {
        let episode = try #require(FeedParser.parse(fixture("podcast.xml")).episodes.first)

        #expect(episode.title == "Side C")
        #expect(episode.audioURL == URL(string: "https://example.com/tape-hiss/3.mp3"))
        #expect(episode.publishDate == Date(timeIntervalSince1970: 1_793_786_400))
        #expect(episode.description == "The third episode.")
    }

    @Test func readsTheEnclosureLength() throws {
        let lengths = try FeedParser.parse(fixture("podcast.xml")).episodes.map(\.byteLength)
        #expect(lengths == [3000, 2000, 1000])
    }

    @Test func parsesDurationsInBothForms() throws {
        let durations = try FeedParser.parse(fixture("podcast.xml")).episodes.map(\.duration)
        #expect(durations == [3723, 1800, nil])
    }

    @Test func keepsItemsWithoutGUIDs() throws {
        let episodes = try FeedParser.parse(fixture("no-guids.xml")).episodes
        #expect(episodes.map(\.guid) == [nil, nil])
        #expect(episodes.map(\.audioURL.lastPathComponent) == ["1.mp3", "2.mp3"])
    }

    @Test func readsNewFeedURL() throws {
        let show = try FeedParser.parse(fixture("new-feed-url.xml"))
        #expect(show.newFeedURL == URL(string: "https://new.example.com/moving-day.xml"))
    }

    @Test func readsEachEpisodesOwnWebPage() throws {
        let show = try FeedParser.parse(fixture("own-links.xml"))
        #expect(show.webPage == URL(string: "https://example.com/own"))
        #expect(show.episodes.map(\.webPage) == [URL(string: "https://example.com/own/2"), URL(string: "https://example.com/own/1")])
    }

    @Test func dropsEpisodeLinksThatPointAtTheShowPage() throws {
        let show = try FeedParser.parse(fixture("show-page-links.xml"))
        #expect(show.webPage == URL(string: "https://example.com/one-page"))
        #expect(show.episodes.map(\.webPage) == [nil, nil])
    }

    @Test func dropsEpisodeLinksSharedByMoreThanOneEpisode() throws {
        let episodes = try FeedParser.parse(fixture("repeated-links.xml")).episodes
        #expect(episodes.map(\.webPage) == [URL(string: "https://example.com/repeats/3"), nil, nil])
    }

    @Test func feedWithoutLinksHasNoWebPages() throws {
        let show = try FeedParser.parse(fixture("no-guids.xml"))
        #expect(show.webPage == nil)
        #expect(show.episodes.map(\.webPage) == [nil, nil])
    }

    @Test func rejectsFeedWithoutAudio() {
        #expect(throws: FeedParseError.notPodcast) { try FeedParser.parse(fixture("not-podcast.xml")) }
    }

    @Test func rejectsMalformedXML() {
        #expect(throws: FeedParseError.malformed) { try FeedParser.parse(fixture("malformed.xml")) }
    }
}
