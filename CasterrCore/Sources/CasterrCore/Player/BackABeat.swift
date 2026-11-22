import Foundation

/// The loudness of one short slice of audio, at its media time.
public struct Loudness: Equatable, Sendable {
    /// Each reading covers this much audio.
    public static let slice: TimeInterval = 0.01

    public let time: TimeInterval
    /// Root mean square of the samples, 0 for silence.
    public let level: Float

    public init(time: TimeInterval, level: Float) {
        self.time = time
        self.level = level
    }
}

/// Back a Beat: resume at the latest quiet gap between 5 s and 2 s before the pause point,
/// so the listener hears the end of the thought they paused in.
public enum BackABeat {
    /// How far before the pause point to look, nearest edge first.
    public static let nearest: TimeInterval = 2
    public static let farthest: TimeInterval = 5
    /// The shortest stretch that counts as a gap. Silences inside words (p, t, k) are shorter;
    /// pauses between phrases are longer. Tuned on three real episodes.
    static let shortestGap: TimeInterval = 0.15
    /// Quiet means below this share of the stretch's median level (about 14 dB down).
    static let quietShare: Float = 0.2

    /// The middle of the latest quiet gap, or `pausedAt` when there is none.
    public static func resumePoint(pausedAt: TimeInterval, readings: [Loudness]) -> TimeInterval {
        let stretch = readings.filter { $0.time >= pausedAt - farthest && $0.time < pausedAt - nearest }
        return QuietGaps.find(in: stretch).last.map { max(0, $0) } ?? pausedAt
    }
}
