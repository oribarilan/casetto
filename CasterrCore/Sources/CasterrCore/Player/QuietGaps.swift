import Foundation

/// Quiet gaps between words: runs of at least `BackABeat.shortestGap` below `BackABeat.quietShare` of a reference
/// level, the loud part of the readings.
public enum QuietGaps {
    /// One stretch of quiet readings, from the first reading's start to the last reading's end.
    public struct Run: Equatable, Sendable {
        public let start: TimeInterval
        public let end: TimeInterval
        public var middle: TimeInterval { (start + end) / 2 }
        public var length: TimeInterval { end - start }
    }

    /// Readings this close count as one run, so a single dropped 10 ms slice doesn't split a gap.
    static let contiguity = Loudness.slice * 2.5
    /// The share of readings below the reference level: the 90th percentile stays on speech even when
    /// pauses fill most of the stretch, where the median would sit at the quiet level.
    static let referencePercentile = 0.9

    /// The clip editor judges quiet against this much audio around each reading, so a loud stretch doesn't hide
    /// gaps in a quiet one.
    public static let editorNeighborhood: TimeInterval = 2

    /// The middle of each gap, in time order. With a `neighborhood`, each reading is judged against the median of
    /// the readings within half of it on either side; without one, against the loud part of all readings.
    public static func find(in readings: [Loudness], neighborhood: TimeInterval? = nil) -> [TimeInterval] {
        runs(in: readings, neighborhood: neighborhood).filter(isGap).map(\.middle)
    }

    /// A run long enough to be a pause between phrases rather than a silence inside a word.
    static func isGap(_ run: Run) -> Bool { run.length >= BackABeat.shortestGap - 0.0001 }

    /// Every quiet run, however short, in time order.
    static func runs(in readings: [Loudness], neighborhood: TimeInterval? = nil) -> [Run] {
        let sorted = readings.sorted { $0.time < $1.time }
        let references: [Float]
        if let neighborhood {
            references = movingMedians(sorted, reach: neighborhood / 2)
        } else {
            guard let reference = percentile(sorted.map(\.level), referencePercentile) else { return [] }
            references = Array(repeating: reference, count: sorted.count)
        }

        var runs: [Run] = []
        var runStart: Loudness?
        var previous: Loudness?
        func closeRun() {
            guard let first = runStart, let last = previous else { return }
            runs.append(Run(start: first.time, end: last.time + Loudness.slice))
            runStart = nil
        }
        for (reading, reference) in zip(sorted, references) {
            let contiguous = previous.map { reading.time - $0.time < contiguity } ?? false
            if reference > 0 && reading.level < reference * BackABeat.quietShare {
                if runStart != nil && !contiguous { closeRun() }
                if runStart == nil { runStart = reading }
            } else {
                closeRun()
            }
            previous = reading
        }
        closeRun()
        return runs
    }

    private static func percentile(_ levels: [Float], _ share: Double) -> Float? {
        guard !levels.isEmpty else { return nil }
        let sorted = levels.sorted()
        return sorted[min(sorted.count - 1, Int(Double(sorted.count) * share))]
    }

    /// The median level of the readings within `reach` of each reading, from a sliding sorted window.
    private static func movingMedians(_ readings: [Loudness], reach: TimeInterval) -> [Float] {
        var window: [Float] = []
        var (next, oldest) = (0, 0)
        return readings.map { reading in
            while next < readings.count && readings[next].time <= reading.time + reach {
                window.insert(readings[next].level, at: insertionIndex(of: readings[next].level, in: window))
                next += 1
            }
            while readings[oldest].time < reading.time - reach {
                window.remove(at: insertionIndex(of: readings[oldest].level, in: window))
                oldest += 1
            }
            return window[window.count / 2]
        }
    }

    /// The first index in sorted `levels` whose value isn't below `level`.
    private static func insertionIndex(of level: Float, in levels: [Float]) -> Int {
        var (low, high) = (0, levels.count)
        while low < high {
            let middle = (low + high) / 2
            if levels[middle] < level { low = middle + 1 } else { high = middle }
        }
        return low
    }
}
