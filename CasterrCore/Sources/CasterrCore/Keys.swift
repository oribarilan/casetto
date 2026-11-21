import Foundation

/// A show's stable identity: its normalized feed URL at the moment of subscribing.
/// It never changes, even when the feed later moves to a new URL.
public struct ShowKey: Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Normalizes to https, a lowercase host, no trailing slash, and no fragment.
    /// Returns nil for URLs that are not http or https or that have no host.
    public init?(feedURL: URL) {
        guard var components = URLComponents(url: feedURL, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = components.host, !host.isEmpty
        else { return nil }

        components.scheme = "https"
        components.host = host.lowercased()
        components.fragment = nil
        while components.path.hasSuffix("/") {
            components.path.removeLast()
        }
        guard let normalized = components.string else { return nil }
        self.rawValue = normalized
    }
}

/// An episode's stable identity within its show: the feed item's GUID, otherwise its audio URL.
extension ShowKey {
    /// The built-in show that holds files shared to Casterr. It lives only on this device.
    public static let shared = ShowKey(rawValue: "casterr:shared")
}

public struct EpisodeKey: Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(show: ShowKey, guid: String?, audioURL: URL) {
        let trimmedGUID = guid?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let itemID = trimmedGUID.isEmpty ? "url:\(audioURL.absoluteString)" : "guid:\(trimmedGUID)"
        self.rawValue = "\(show.rawValue)|\(itemID)"
    }
}

extension EpisodeKey {
    public func belongs(to show: ShowKey) -> Bool {
        rawValue.hasPrefix(show.rawValue + "|")
    }
}
