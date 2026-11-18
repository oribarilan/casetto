import Foundation

/// Playback speed from 1.0x to 2.0x in steps of 0.1x.
public struct PlaybackSpeed: Hashable, Sendable {
    public static let normal = PlaybackSpeed(1.0)

    public let value: Double

    /// Clamps to 1.0...2.0 and rounds to the nearest tenth.
    public init(_ value: Double) {
        let tenths = (min(max(value, 1.0), 2.0) * 10).rounded()
        self.value = tenths / 10
    }

    /// A show's override if it has one, otherwise the global speed.
    public static func effective(global: PlaybackSpeed, override: PlaybackSpeed?) -> PlaybackSpeed {
        override ?? global
    }
}

public enum PlayedRule {
    /// An episode counts as played when fewer than 60 seconds remain.
    public static func isPlayed(position: TimeInterval, duration: TimeInterval?) -> Bool {
        guard let duration else { return false }
        return duration - position < 60
    }
}
