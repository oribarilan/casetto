import Foundation
import Testing

@testable import CasterrCore

private let showKey = ShowKey(feedURL: URL(string: "https://atp.fm/rss")!)!
private let feedURL = URL(string: "https://atp.fm/rss")!
private let audio = URL(string: "https://cdn.atp.fm/718.mp3")!
private let atp = ShowInfo(key: showKey, title: "Accidental Tech Podcast", webPage: URL(string: "https://atp.fm"))

private func episode(webPage: URL? = URL(string: "https://atp.fm/718")) -> EpisodeInfo {
    EpisodeInfo(
        key: EpisodeKey(show: showKey, guid: "718", audioURL: audio), showKey: showKey,
        title: "718: The Warp Zone", audioURL: audio, webPage: webPage)
}

struct ShareTextTests {
    private let feedB64 = "aHR0cHM6Ly9hdHAuZm0vcnNz"  // https://atp.fm/rss

    @Test func episodeSendsItsNamesAndItsPodlink() {
        let share = ShareText.episode(episode(), showTitle: "Accidental Tech Podcast", feedURL: feedURL)
        #expect(share.text == "718: The Warp Zone – Accidental Tech Podcast")
        #expect(share.url == URL(string: "https://pod.link/\(feedB64)/episode/NzE4"))
    }

    @Test func aGUIDThatNeedsPaddingIsSentWithout() {
        // "71" is "NzE=" in base64; Podlink's URL-safe form drops the padding.
        let key = EpisodeKey(show: showKey, guid: "71", audioURL: audio)
        let info = EpisodeInfo(key: key, showKey: showKey, title: "71", audioURL: audio)
        #expect(
            ShareText.episode(info, showTitle: nil, feedURL: feedURL).url
                == URL(string: "https://pod.link/\(feedB64)/episode/NzE"))
    }

    @Test func urlUnsafeCharactersBecomeDashAndUnderscore() {
        // "~~~" is "fn5+" in standard base64.
        let key = EpisodeKey(show: showKey, guid: "~~~", audioURL: audio)
        let info = EpisodeInfo(key: key, showKey: showKey, title: "x", audioURL: audio)
        #expect(ShareText.episode(info, showTitle: nil, feedURL: feedURL).url.absoluteString.hasSuffix("/episode/fn5-"))
    }

    @Test func anEpisodeWithNoGUIDLinksToTheShow() {
        let key = EpisodeKey(show: showKey, guid: nil, audioURL: audio)
        let info = EpisodeInfo(key: key, showKey: showKey, title: "x", audioURL: audio)
        #expect(
            ShareText.episode(info, showTitle: nil, feedURL: feedURL).url == URL(string: "https://pod.link/\(feedB64)"))
    }

    @Test func withoutAFeedItSendsTheEpisodesPageOrAudio() {
        #expect(ShareText.episode(episode(), showTitle: nil, feedURL: nil).url == URL(string: "https://atp.fm/718"))
        #expect(ShareText.episode(episode(webPage: nil), showTitle: nil, feedURL: nil).url == audio)
    }

    @Test func episodeWithoutAShowSendsItsTitleAlone() {
        #expect(ShareText.episode(episode(), showTitle: nil, feedURL: feedURL).text == "718: The Warp Zone")
    }

    @Test func theGUIDComesBackFromTheKey() {
        #expect(EpisodeKey(show: showKey, guid: " 718 ", audioURL: audio).guid == "718")
        #expect(EpisodeKey(show: showKey, guid: nil, audioURL: audio).guid == nil)
    }

    @Test func showSendsItsNameAndItsPodlink() {
        let share = ShareText.show(atp, feedURL: feedURL)
        #expect(share.text == "Accidental Tech Podcast")
        #expect(share.url == URL(string: "https://pod.link/aHR0cHM6Ly9hdHAuZm0vcnNz"))
    }
}
