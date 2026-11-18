/// Where an episode lives. An episode with no place is `Place?.none`.
public enum Place: Hashable, Sendable {
    case queue
    case archive(ArchiveReason)

    public enum ArchiveReason: String, Sendable {
        case played
    }

    public struct StoredFormError: Error, Equatable {
        public let storedPlace: String?
        public let archiveReason: String?
    }

    /// The flat form that storage keeps, since synced records can't hold enums with payloads.
    public var stored: (place: String, archiveReason: String?) {
        switch self {
        case .queue: ("queue", nil)
        case .archive(let reason): ("archive", reason.rawValue)
        }
    }

    /// Reads the flat stored form back. Returns nil for no place and throws for any invalid combination.
    public init?(storedPlace: String?, archiveReason: String?) throws {
        switch (storedPlace, archiveReason) {
        case (nil, nil):
            return nil
        case ("queue", nil):
            self = .queue
        case ("archive", let reason?):
            guard let reason = ArchiveReason(rawValue: reason) else {
                throw StoredFormError(storedPlace: storedPlace, archiveReason: archiveReason)
            }
            self = .archive(reason)
        default:
            throw StoredFormError(storedPlace: storedPlace, archiveReason: archiveReason)
        }
    }
}
