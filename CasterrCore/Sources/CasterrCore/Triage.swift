import Foundation

/// How a show's new episodes are placed.
public enum TriageLevel: String, CaseIterable, Sendable {
    case inbox
    case autoQueue
    case playNext
    case skip

    /// Where a new episode goes and the reason recorded for the move.
    public var destination: (place: Place, reason: MoveReason) {
        switch self {
        case .inbox: (.inbox, .arrived)
        case .autoQueue: (.queue, .autoQueued)
        case .playNext: (.queue, .playNext)
        case .skip: (.archive(.skipped), .skipped)
        }
    }
}

/// Why an episode last changed place.
public enum MoveReason: Hashable, Sendable {
    /// The listener moved it.
    case listener
    /// Triage put it in the Inbox.
    case arrived
    case autoQueued
    case playNext
    case skipped
    /// Expired from the Inbox after this many days.
    case expired(days: Int)

    /// Shown on the episode row, so an automatic move says why it happened. The listener's own moves need no label.
    public var label: String? {
        switch self {
        case .listener, .arrived: nil
        case .autoQueued: "Auto-queued"
        case .playNext: "Play next"
        case .skipped: "Skipped by show setting"
        case .expired(let days): "Removed after \(days) days"
        }
    }

    var stored: String {
        switch self {
        case .listener: "listener"
        case .arrived: "arrived"
        case .autoQueued: "autoQueued"
        case .playNext: "playNext"
        case .skipped: "skipped"
        case .expired(let days): "expired:\(days)"
        }
    }

    init?(stored: String) {
        switch stored {
        case "listener": self = .listener
        case "arrived": self = .arrived
        case "autoQueued": self = .autoQueued
        case "playNext": self = .playNext
        case "skipped": self = .skipped
        default:
            guard stored.hasPrefix("expired:"), let days = Int(stored.dropFirst("expired:".count)), days > 0 else {
                return nil
            }
            self = .expired(days: days)
        }
    }
}

/// How long an episode can wait in the Inbox before it moves to the archive.
public enum InboxExpiry: Hashable, Sendable {
    case days(Int)
    case never

    public static let choices: [InboxExpiry] = [.days(1), .days(3), .days(7), .days(14), .days(30), .never]

    /// The global period on a fresh install.
    public static let standard = InboxExpiry.days(14)

    /// Storage keeps days as an integer, with 0 for never.
    init(storedDays: Int) {
        self = storedDays > 0 ? .days(storedDays) : .never
    }

    var storedDays: Int {
        if case .days(let days) = self { days } else { 0 }
    }

    /// True once an episode that entered the Inbox at `enteredAt` has waited the full period.
    public func hasExpired(enteredAt: Date, now: Date) -> Bool {
        guard case .days(let days) = self else { return false }
        return now.timeIntervalSince(enteredAt) >= Double(days) * 86_400
    }
}

/// The latest move of an episode, as the episode row shows it.
public struct LastMove: Equatable, Sendable {
    public var reason: MoveReason
}
