import Foundation

/// What an episode row says about its download, as the last gray word of its status line.
public enum DownloadState: Equatable, Sendable {
    case downloaded
    /// The share done from 0 to 1, or nil when the server sent no size.
    case downloading(Double?)
    /// It should download, but the phone isn't on a network downloads may use.
    case waiting

    /// - Parameters:
    ///   - downloaded: The file is on the phone.
    ///   - progress: The running download's share done, `.some(nil)` when its size is unknown, nil when none runs.
    ///   - wanted: It's among the Queue episodes to keep downloaded.
    ///   - downloadsAllowed: The phone is on Wi-Fi or a wired network, not expensive and not in Low Data Mode.
    ///   - loaded: It's the player's episode, which streams fine, so it never waits for Wi-Fi.
    public static func of(downloaded: Bool, progress: Double??, wanted: Bool, downloadsAllowed: Bool,
                          loaded: Bool = false) -> DownloadState? {
        if downloaded { return .downloaded }
        if let progress { return .downloading(progress) }
        guard wanted else { return nil }
        if downloadsAllowed { return .downloading(0) }
        return loaded ? nil : .waiting
    }

    /// "Downloaded", "Downloading 45%" (whole percents, rounded down), or "Waiting for Wi-Fi".
    public var label: String {
        switch self {
        case .downloaded: "Downloaded"
        case .downloading(let share?): "Downloading \(Int((min(max(share, 0), 1) * 100).rounded(.down)))%"
        case .downloading(nil): "Downloading"
        case .waiting: "Waiting for Wi-Fi"
        }
    }
}
