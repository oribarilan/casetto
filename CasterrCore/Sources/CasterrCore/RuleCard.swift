import Foundation

/// A one-tap offer to change how a show is triaged, learned from how the listener treats it.
public struct RuleCard: Equatable, Sendable {
    public enum Kind: String, Sendable {
        /// The listener starts every new episode within a day. Offers Auto-queue.
        case autoQueue
        /// The show's recent episodes all expired unplayed. Offers Skip or Unsubscribe.
        case ignored
    }

    public struct Thresholds: Sendable {
        public var autoQueue = 4
        public var ignored = 3
        public init(autoQueue: Int = 4, ignored: Int = 3) {
            self.autoQueue = autoQueue
            self.ignored = ignored
        }
    }

    /// One episode as the evaluation sees it.
    public struct Episode: Sendable {
        public var published: Date
        public var firstPlayedAt: Date?
        public var place: Place?
    }

    public var show: ShowKey
    public var kind: Kind

    static let hideForNotNow: TimeInterval = 30 * 86_400
    private static let day: TimeInterval = 86_400

    /// The card a show earns, if any. `episodes` are the show's dated episodes in any order.
    static func evaluate(episodes: [Episode], now: Date, thresholds: Thresholds) -> Kind? {
        let newestFirst = episodes.sorted { $0.published > $1.published }
        let recent = newestFirst.prefix(thresholds.ignored)
        if recent.count == thresholds.ignored, recent.allSatisfy({ $0.place == .archive(.expired) }) {
            return .ignored
        }
        let settled = newestFirst.filter { now.timeIntervalSince($0.published) > day }.prefix(thresholds.autoQueue)
        let playedQuickly = settled.allSatisfy { episode in
            episode.firstPlayedAt.map { $0.timeIntervalSince(episode.published) < day } ?? false
        }
        if settled.count == thresholds.autoQueue, playedQuickly {
            return .autoQueue
        }
        return nil
    }
}
