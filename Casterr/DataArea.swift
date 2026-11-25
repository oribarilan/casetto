/// The parts of stored data a change can touch. A change names the areas it touched, and a screen reloads only
/// for the areas it shows. A change that can't say touches `.all`.
struct DataArea: OptionSet, Sendable {
    let rawValue: Int

    /// Follow, star, and a show's own settings: its level, expiry, speed and voice boost.
    static let follows = DataArea(rawValue: 1 << 0)
    /// Where each episode is (Queue, Inbox, played, removed) and how far the listener got.
    static let episodes = DataArea(rawValue: 1 << 1)
    /// Show and episode data from the feeds, and shared files.
    static let feeds = DataArea(rawValue: 1 << 2)
    static let bookmarks = DataArea(rawValue: 1 << 3)
    /// The app-wide settings.
    static let settings = DataArea(rawValue: 1 << 4)
    /// Downloaded files. Nothing in the library changes, only which episodes have a file.
    static let downloads = DataArea(rawValue: 1 << 5)

    /// Following or unfollowing a show: it saves or keeps the feed, and fills or empties the show's Inbox episodes.
    static let following: DataArea = [.follows, .feeds, .episodes]

    static let all: DataArea = [.follows, .episodes, .feeds, .bookmarks, .settings, .downloads]
}
