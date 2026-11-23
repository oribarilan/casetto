import Foundation

/// The message and link that Share Episode and Share Show send.
public enum ShareText {
    /// "Episode – Show", with ", from 12:34" when given a position. The link is the episode's page, else its audio.
    public static func episode(_ episode: EpisodeInfo, show: ShowInfo?, at position: TimeInterval?) -> (text: String, url: URL) {
        self.episode(episode, showTitle: show?.title, at: position)
    }

    public static func episode(_ episode: EpisodeInfo, showTitle: String?, at position: TimeInterval?) -> (text: String, url: URL) {
        var text = showTitle.map { "\(episode.title) – \($0)" } ?? episode.title
        if let position { text += ", from \(BookmarkMarkdown.timestamp(position))" }
        return (text, episode.webPage ?? episode.audioURL)
    }

    /// The show's title, with its page, else its feed address.
    public static func show(_ show: ShowInfo, feedURL: URL) -> (text: String, url: URL) {
        (show.title, show.webPage ?? feedURL)
    }
}
