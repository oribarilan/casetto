import CoreGraphics
import Foundation
import Testing
@testable import CasterrCore

struct RefreshSummaryTests {
    @Test func mixedRefresh() {
        #expect(RefreshSummary(arrived: 1, queued: 1, expired: 2).sentence
                == "2 new episodes. I queued 1 and removed 2 old ones from your Inbox.")
    }

    @Test func singularAndThreeActions() {
        #expect(RefreshSummary(arrived: 0, queued: 1, skipped: 1, expired: 1).sentence
                == "2 new episodes. I queued 1, skipped 1, and removed 1 old one from your Inbox.")
        #expect(RefreshSummary(arrived: 1).sentence == "1 new episode.")
        #expect(RefreshSummary(expired: 3).sentence == "I removed 3 old ones from your Inbox.")
    }

    @Test func quietRefreshSaysNothing() {
        #expect(RefreshSummary().sentence == nil)
    }

    @Test func summariesAdd() {
        #expect(RefreshSummary(arrived: 1, queued: 2) + RefreshSummary(arrived: 3, skipped: 1)
                == RefreshSummary(arrived: 4, queued: 2, skipped: 1))
    }
}

struct ArtworkTintTests {
    private func solid(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGImage {
        let context = CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 32,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(red: r, green: g, blue: b, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        return context.makeImage()!
    }

    @Test(arguments: [(0.2, 0.8, 0.3), (0.5, 0.5, 0.5), (0.97, 0.97, 0.95), (1.0, 0.85, 0.1)])
    func tintKeepsWhiteTextReadable(r: Double, g: Double, b: Double) {
        let tint = ArtworkTint.color(of: solid(r, g, b))
        #expect(ArtworkTint.contrastWithWhite(tint) >= 4.5)
    }

    @Test func greenArtGivesADarkGreen() {
        let tint = ArtworkTint.color(of: solid(0.2, 0.8, 0.3))
        #expect(tint.green > tint.red && tint.green > tint.blue)
        #expect(max(tint.red, tint.green, tint.blue) <= 0.351)
    }

    @Test func greyArtStaysGrey() {
        let tint = ArtworkTint.color(of: solid(0.5, 0.5, 0.5))
        #expect(abs(tint.red - tint.green) < 0.02 && abs(tint.green - tint.blue) < 0.02)
    }
}

struct ShowArtTests {
    @Test func returnsEveryShowsTitleAndArtwork() async throws {
        let library = try Library.open(inMemory: true)
        let a = ShowKey(feedURL: URL(string: "https://a.example.com/feed")!)!
        let b = ShowKey(feedURL: URL(string: "https://b.example.com/feed")!)!
        try await library.saveFeed(ParsedShow(title: "A", artworkURL: URL(string: "https://a.example.com/art.jpg"), episodes: []), for: a)
        try await library.saveFeed(ParsedShow(title: "B", episodes: []), for: b)
        #expect(try await library.showArt() == [
            a: ShowArt(title: "A", artworkURL: URL(string: "https://a.example.com/art.jpg")),
            b: ShowArt(title: "B", artworkURL: nil),
        ])
    }
}

struct ShowSearchTests {
    @Test func everyWordMustMatchTitleOrAuthor() {
        #expect(ShowSearch.matches("pock econ", title: "Pocket Economics", author: "Field Media"))
        #expect(!ShowSearch.matches("pod econ", title: "Pocket Economics", author: "Field Media"))
        #expect(ShowSearch.matches("TAPE", title: "Tape Hiss", author: nil))
        #expect(ShowSearch.matches("ada hiss", title: "Tape Hiss", author: "Ada Reel"))
        #expect(ShowSearch.matches("cafe", title: "Café Stories", author: nil))
        #expect(!ShowSearch.matches("tape econ", title: "Tape Hiss", author: "Ada Reel"))
        #expect(!ShowSearch.matches("   ", title: "Tape Hiss", author: nil))
    }
}

struct PlainSummaryTests {
    private func info(_ summary: String?) -> ShowInfo {
        ShowInfo(key: ShowKey(rawValue: "k"), title: "T", summary: summary)
    }

    @Test func stripsTagsAndEntities() {
        #expect(info("<p>Tapes &amp; decks,<br/> weekly.</p>\n\n").plainSummary == "Tapes & decks, weekly.")
        #expect(info("<p> </p>").plainSummary == nil)
        #expect(info(nil).plainSummary == nil)
    }
}
