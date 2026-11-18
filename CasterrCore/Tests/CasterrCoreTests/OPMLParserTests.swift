import Foundation
import Testing
@testable import CasterrCore

struct OPMLParserTests {
    @Test func parsesNestedFeeds() throws {
        let result = try OPMLParser.parse(fixture("valid.opml"))

        #expect(result.feeds == [
            OPMLFeed(url: URL(string: "https://example.com/tape-hiss.xml")!, title: "Tape Hiss"),
            OPMLFeed(url: URL(string: "https://example.com/side-two.xml")!, title: "Side Two"),
            OPMLFeed(url: URL(string: "https://example.com/untitled.xml")!, title: nil),
        ])
        #expect(result.invalidEntries.isEmpty)
    }

    @Test func reportsBadEntries() throws {
        let result = try OPMLParser.parse(fixture("bad-entries.opml"))

        #expect(result.feeds.map(\.title) == ["Good"])
        #expect(result.invalidEntries == [
            OPMLInvalidEntry(title: "No URL", reason: .missingURL),
            OPMLInvalidEntry(title: "Bad URL", reason: .invalidURL("ftp://example.com/bad.xml")),
        ])
    }

    @Test func rejectsOtherXML() {
        #expect(throws: OPMLError.notOPML) { try OPMLParser.parse(fixture("not-opml.xml")) }
    }

    @Test func rejectsMalformedXML() {
        #expect(throws: OPMLError.notOPML) { try OPMLParser.parse(fixture("malformed.xml")) }
    }
}
