import Foundation

/// Loudness bars for the clip editor.
public enum LoudnessBars {
    /// How far below the loudest bar a bar reaches zero height.
    /// Narrow enough that pauses between words show as clear dips.
    public static let range: Float = 24

    /// `count` bars from mono samples: each bar's RMS in decibels, scaled so the loudest bar is 1
    /// and anything `range` dB below it, or silent, is 0.
    public static func bars(from samples: [Float], count: Int) -> [Float] {
        guard count > 0 else { return [] }
        let decibels: [Float?] = (0..<count).map { index in
            let slice = samples[index * samples.count / count..<(index + 1) * samples.count / count]
            guard !slice.isEmpty else { return nil }
            let rms = (slice.reduce(0) { $0 + $1 * $1 } / Float(slice.count)).squareRoot()
            return rms > 0 ? 20 * log10(rms) : nil
        }
        guard let loudest = decibels.compactMap(\.self).max() else { return Array(repeating: 0, count: count) }
        return decibels.map { db in db.map { max(0, 1 - (loudest - $0) / range) } ?? 0 }
    }

    /// The bars for `clip` alone, from `bars` spread evenly over `span`, regrouped into `count` bars that each take
    /// the loudest bar they cover, so short pauses don't flatten the clip's shape.
    public static func bars(
        _ bars: [Float], over span: ClosedRange<TimeInterval>, for clip: ClosedRange<TimeInterval>,
        count: Int
    ) -> [Float] {
        let length = span.upperBound - span.lowerBound
        guard count > 0, !bars.isEmpty, length > 0 else { return Array(repeating: 0, count: max(count, 0)) }
        func index(_ time: TimeInterval) -> Int {
            min(bars.count, max(0, Int(((time - span.lowerBound) / length * Double(bars.count)).rounded())))
        }
        let step = (clip.upperBound - clip.lowerBound) / Double(count)
        return (0..<count).map { group in
            let first = index(clip.lowerBound + Double(group) * step)
            let last = max(first + 1, index(clip.lowerBound + Double(group + 1) * step))
            return bars[min(first, bars.count - 1)..<min(last, bars.count)].max() ?? 0
        }
    }
}

extension Loudness {
    /// One reading per `Loudness.slice` of mono samples, timed from `start`. A last partial slice is dropped.
    public static func readings(from samples: [Float], sampleRate: Double, startingAt start: TimeInterval) -> [Loudness]
    {
        let perSlice = Int((sampleRate * slice).rounded())
        guard perSlice > 0 else { return [] }
        return (0..<samples.count / perSlice).map { index in
            let chunk = samples[index * perSlice..<(index + 1) * perSlice]
            let rms = (chunk.reduce(0) { $0 + $1 * $1 } / Float(perSlice)).squareRoot()
            return Loudness(time: start + Double(index) * slice, level: rms)
        }
    }
}
