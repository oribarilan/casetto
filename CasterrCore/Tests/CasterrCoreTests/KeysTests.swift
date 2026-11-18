import Foundation
import Testing
@testable import CasterrCore

struct ShowKeyTests {
    private func key(_ string: String) -> ShowKey? {
        ShowKey(feedURL: URL(string: string)!)
    }

    @Test func httpBecomesHttps() {
        #expect(key("http://example.com/feed") == key("https://example.com/feed"))
    }

    @Test func hostIsCaseInsensitive() {
        #expect(key("https://Example.COM/feed") == key("https://example.com/feed"))
    }

    @Test func trailingSlashIsIgnored() {
        #expect(key("https://example.com/feed/") == key("https://example.com/feed"))
    }

    @Test func pathCaseMatters() {
        #expect(key("https://example.com/Feed") != key("https://example.com/feed"))
    }

    @Test func queryIsKept() {
        #expect(key("https://example.com/feed?id=1") != key("https://example.com/feed?id=2"))
    }

    @Test func fragmentIsIgnored() {
        #expect(key("https://example.com/feed#top") == key("https://example.com/feed"))
    }

    @Test func rawValueIsTheNormalizedURL() {
        #expect(key("HTTP://Example.com/feed/")?.rawValue == "https://example.com/feed")
    }

    @Test func rejectsNonWebURLs() {
        #expect(key("ftp://example.com/feed") == nil)
        #expect(key("file:///tmp/feed.xml") == nil)
    }
}

struct EpisodeKeyTests {
    private let show = ShowKey(feedURL: URL(string: "https://example.com/feed")!)!
    private let audio = URL(string: "https://cdn.example.com/ep1.mp3")!

    @Test func usesGUIDWhenPresent() {
        let key = EpisodeKey(show: show, guid: "abc-123", audioURL: audio)
        #expect(key.rawValue == "https://example.com/feed|guid:abc-123")
    }

    @Test func fallsBackToAudioURLWithoutGUID() {
        let key = EpisodeKey(show: show, guid: nil, audioURL: audio)
        #expect(key.rawValue == "https://example.com/feed|url:https://cdn.example.com/ep1.mp3")
    }

    @Test func blankGUIDCountsAsMissing() {
        #expect(EpisodeKey(show: show, guid: "  ", audioURL: audio)
            == EpisodeKey(show: show, guid: nil, audioURL: audio))
    }

    @Test func sameGUIDInDifferentShowsIsDifferent() {
        let other = ShowKey(feedURL: URL(string: "https://other.com/feed")!)!
        #expect(EpisodeKey(show: show, guid: "1", audioURL: audio)
            != EpisodeKey(show: other, guid: "1", audioURL: audio))
    }
}
