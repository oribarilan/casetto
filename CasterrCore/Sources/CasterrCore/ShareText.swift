import Foundation

/// The message and link that Share Episode, a clip, and Share Show send.
public enum ShareText {
    public static func episode(_ episode: EpisodeInfo, show: ShowInfo?) -> (text: String, url: URL) {
        self.episode(episode, showTitle: show?.title, feedURL: show?.feedURL)
    }

    /// "Episode – Show", with the episode's Podlink link, which lets the reader pick a podcast app.
    /// Podlink takes the feed address and the GUID, both in URL-safe base64 with no padding; an episode
    /// with no GUID links to the show. Without a feed address, the link is the episode's page, else its audio.
    public static func episode(_ episode: EpisodeInfo, showTitle: String?, feedURL: URL?) -> (text: String, url: URL) {
        let text = showTitle.map { "\(episode.title) – \($0)" } ?? episode.title
        guard let feedURL else { return (text, episode.webPage ?? episode.audioURL) }
        let show = podlink(feedURL)
        let link = episode.key.guid.map { "\(show)/episode/\(base64URL($0))" } ?? show
        return (text, URL(string: link) ?? episode.webPage ?? episode.audioURL)
    }

    private static func base64URL(_ text: String) -> String {
        Data(text.utf8).base64EncodedString()
            .replacing("+", with: "-").replacing("/", with: "_").replacing("=", with: "")
    }

    /// The show's title, with its Podlink page.
    public static func show(_ show: ShowInfo, feedURL: URL) -> (text: String, url: URL) {
        (show.title, URL(string: podlink(feedURL)) ?? show.webPage ?? feedURL)
    }

    private static func podlink(_ feedURL: URL) -> String {
        "https://pod.link/\(base64URL(feedURL.absoluteString))"
    }
}
