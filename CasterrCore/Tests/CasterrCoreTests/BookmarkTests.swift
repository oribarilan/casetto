import Foundation
import Testing

@testable import CasterrCore

private let show = ShowKey(feedURL: URL(string: "https://example.com/feed")!)!

private func episode(_ n: Int, title: String = "Episode") -> EpisodeInfo {
    EpisodeInfo(
        key: EpisodeKey(show: show, guid: "ep\(n)", audioURL: URL(string: "https://cdn.example.com/\(n).mp3")!),
        showKey: show, title: "\(title) \(n)", audioURL: URL(string: "https://cdn.example.com/\(n).mp3")!)
}

struct BookmarkStoreTests {
    @Test func addNoteAndDelete() async throws {
        let library = try Library.open(inMemory: true)
        let id = try await library.addBookmark(episode(1), showTitle: "Tape Hiss", at: 754)
        try await library.setNote("  great point \n", for: id)
        let saved = try #require(try await library.bookmarks().first)
        #expect(saved.note == "great point")
        #expect(saved.position == 754)
        #expect(saved.episodeTitle == "Episode 1")
        #expect(saved.showTitle == "Tape Hiss")
        try await library.deleteBookmark(id)
        #expect(try await library.bookmarks().isEmpty)
    }

    @Test func searchCoversNoteAndTitlesIgnoringCase() async throws {
        let library = try Library.open(inMemory: true)
        let noted = try await library.addBookmark(episode(1), showTitle: "Tape Hiss", at: 10)
        try await library.setNote("Great point about magnets", for: noted)
        try await library.addBookmark(episode(2, title: "Reels"), showTitle: "Tape Hiss", at: 20)
        try await library.addBookmark(episode(3), showTitle: "Vinyl Hour", at: 30)
        #expect(try await library.bookmarks(matching: "GREAT").map(\.note) == ["Great point about magnets"])
        #expect(try await library.bookmarks(matching: "reels").map(\.episodeTitle) == ["Reels 2"])
        #expect(try await library.bookmarks(matching: "vinyl").count == 1)
        #expect(try await library.bookmarks(matching: "").count == 3)
        #expect(try await library.bookmarks(matching: "nothing").isEmpty)
    }

    @Test func survivesUnsubscribingAndWipingTheFeedCache() async throws {
        let library = try Library.open(inMemory: true)
        try await library.addSubscription(show, feedURL: URL(string: show.rawValue)!)
        try await library.addBookmark(episode(1), showTitle: "Tape Hiss", at: 10)
        try await library.removeSubscription(show)
        try await library.wipeFeedCache()
        #expect(try await library.bookmarks().map(\.showTitle) == ["Tape Hiss"])
    }
}

struct BookmarkMarkdownTests {
    private func bookmark(
        _ position: TimeInterval, note: String = "", show: String = "Tape Hiss",
        episode: String = "Side A"
    ) -> BookmarkInfo {
        BookmarkInfo(
            id: UUID(), episodeKey: EpisodeKey(rawValue: "k"), position: position, note: note, createdAt: .now,
            showTitle: show, episodeTitle: episode, audioURL: URL(string: "https://cdn.example.com/a.mp3"))
    }

    @Test func rendersTitlesAndBookmarksInPositionOrder() {
        let text = BookmarkMarkdown.render([
            bookmark(3723, note: "late"), bookmark(754, note: "great point"), bookmark(5),
        ])
        #expect(
            text == """
                # Side A

                Tape Hiss
                <https://cdn.example.com/a.mp3>

                - 0:05
                - 12:34 great point
                - 1:02:03 late

                """)
    }

    @Test func rendersSeveralEpisodesInOneFile() {
        let first = [bookmark(754, note: "great point")]
        let second = [bookmark(5, show: "Deep Field", episode: "Ocean Floor")]
        #expect(
            BookmarkMarkdown.render(episodes: [first, second])
                == BookmarkMarkdown.render(first) + "\n" + BookmarkMarkdown.render(second))
        #expect(BookmarkMarkdown.fileName(episodes: [first, second]) == "Bookmarks.md")
        #expect(BookmarkMarkdown.fileName(episodes: [second]) == "Deep Field - Ocean Floor.md")
    }

    @Test func fileNameDropsUnsafeCharacters() {
        #expect(
            BookmarkMarkdown.fileName([bookmark(0, show: "AC/DC: Live", episode: "Who? \"Me\"")])
                == "AC-DC- Live - Who- -Me-.md")
    }
}
