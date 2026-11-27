/// What a refresh moved, for Cassy's summary toast.
public struct RefreshSummary: Equatable, Sendable {
    /// New episodes put in the Inbox.
    public var arrived = 0
    /// New episodes added to the Queue, by Auto-queue or Play next.
    public var queued = 0
    /// New episodes archived by the Skip level.
    public var skipped = 0
    /// Inbox episodes that expired.
    public var expired = 0

    public init(arrived: Int = 0, queued: Int = 0, skipped: Int = 0, expired: Int = 0) {
        self.arrived = arrived
        self.queued = queued
        self.skipped = skipped
        self.expired = expired
    }

    public static func + (a: RefreshSummary, b: RefreshSummary) -> RefreshSummary {
        RefreshSummary(
            arrived: a.arrived + b.arrived, queued: a.queued + b.queued,
            skipped: a.skipped + b.skipped, expired: a.expired + b.expired)
    }

    /// Cassy's line, e.g. "3 new episodes. I queued 1 and removed 2 old ones from your Inbox." Nil when nothing moved.
    public var sentence: String? {
        let new = arrived + queued + skipped
        var actions: [String] = []
        if queued > 0 { actions.append("queued \(queued)") }
        if skipped > 0 { actions.append("skipped \(skipped)") }
        if expired > 0 { actions.append("removed \(expired) old \(expired == 1 ? "one" : "ones") from your Inbox") }
        var parts: [String] = []
        if new > 0 { parts.append("\(new) new \(new == 1 ? "episode" : "episodes").") }
        if !actions.isEmpty { parts.append("I \(Self.list(actions)).") }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    private static func list(_ items: [String]) -> String {
        switch items.count {
        case 1: items[0]
        case 2: "\(items[0]) and \(items[1])"
        default: items.dropLast().joined(separator: ", ") + ", and " + items.last!
        }
    }
}
