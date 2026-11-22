import Foundation
import Testing
@testable import CasterrCore

private let showKey = ShowKey(feedURL: URL(string: "https://atp.fm/rss")!)!
private let feedURL = URL(string: "https://atp.fm/rss")!
private let audio = URL(string: "https://cdn.atp.fm/718.mp3")!
private let atp = ShowInfo(key: showKey, title: "Accidental Tech Podcast", webPage: URL(string: "https://atp.fm"))

private func episode(webPage: URL? = URL(string: "https://atp.fm/718")) -> EpisodeInfo {
    EpisodeInfo(key: EpisodeKey(show: showKey, guid: "718", audioURL: audio), showKey: showKey,
                title: "718: The Warp Zone", audioURL: audio, webPage: webPage)
}

struct ShareTextTests {
    @Test func episodeWithItsOwnPage() {
        let share = ShareText.episode(episode(), show: atp, at: nil)
        #expect(share.text == "718: The Warp Zone – Accidental Tech Podcast")
        #expect(share.url == URL(string: "https://atp.fm/718"))
    }

    @Test func episodeWithoutAPageSendsItsAudio() {
        #expect(ShareText.episode(episode(webPage: nil), show: atp, at: nil).url == audio)
    }

    @Test func episodeWithoutAShowSendsItsTitleAlone() {
        #expect(ShareText.episode(episode(), show: nil, at: nil).text == "718: The Warp Zone")
    }

    @Test func positionAddsTheTime() {
        #expect(ShareText.episode(episode(), show: atp, at: 754).text
            == "718: The Warp Zone – Accidental Tech Podcast, from 12:34")
        #expect(ShareText.episode(episode(), show: nil, at: 5).text == "718: The Warp Zone, from 0:05")
    }

    @Test func positionPastAnHourShowsHours() {
        #expect(ShareText.episode(episode(), show: nil, at: 3723.9).text.hasSuffix(", from 1:02:03"))
    }

    @Test func showWithAPage() {
        let share = ShareText.show(atp, feedURL: feedURL)
        #expect(share.text == "Accidental Tech Podcast")
        #expect(share.url == URL(string: "https://atp.fm"))
    }

    @Test func showWithoutAPageSendsItsFeed() {
        var show = atp
        show.webPage = nil
        #expect(ShareText.show(show, feedURL: feedURL).url == feedURL)
    }
}
