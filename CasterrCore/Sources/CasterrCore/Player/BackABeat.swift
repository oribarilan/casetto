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

/// Back a Beat: resume in the latest quiet gap that reaches into 2 s to 5 s before where the speech stopped,
/// so the listener hears the end of the thought they paused in.
public enum BackABeat {
    /// How far before the pause point to look, nearest edge first.
    public static let nearest: TimeInterval = 2
    public static let farthest: TimeInterval = 5
    /// The shortest stretch that counts as a gap. Silences inside words (p, t, k) are shorter;
    /// pauses between phrases are longer. Tuned on three real episodes.
    static let shortestGap: TimeInterval = 0.15
    /// Quiet means below this share of the stretch's loud level (about 14 dB down).
    static let quietShare: Float = 0.2
    /// How much audio before the pause point to read: enough to find where the speech stopped when the pause
    /// fell inside a silence, and a full window before that.
    public static let lookBack: TimeInterval = 10

    /// A point in the latest quiet gap that reaches into 2 s to 5 s before where the speech stopped: its middle,
    /// or the nearest point of it inside that range. `pausedAt` when there is none. Speech stopped at the pause
    /// point, or where the quiet the pause fell in began; that quiet never counts, so playback goes back further.
    public static func resumePoint(pausedAt: TimeInterval, readings: [Loudness]) -> TimeInterval {
        let stretch = readings.filter { $0.time >= pausedAt - lookBack && $0.time < pausedAt }
        var runs = QuietGaps.runs(in: stretch)
        var speechStopped = pausedAt
        if let last = runs.last, last.end >= pausedAt - QuietGaps.contiguity {
            speechStopped = last.start
            runs.removeLast()
        }
        let earliest = speechStopped - farthest
        let latest = speechStopped - nearest
        let gap = runs.last { QuietGaps.isGap($0) && $0.end > earliest && $0.start < latest }
        return gap.map { max(0, min(max($0.middle, earliest), latest)) } ?? pausedAt
    }
}
