import Foundation

/// Quiet gaps between words: runs of at least `BackABeat.shortestGap` below `BackABeat.quietShare` of the median level.
public enum QuietGaps {
    /// The clip editor judges quiet against this much audio around each reading, so a loud stretch doesn't hide
    /// gaps in a quiet one.
    public static let editorNeighborhood: TimeInterval = 2

    /// The middle of each gap, in time order. With a `neighborhood`, each reading is judged against the median of
    /// the readings within half of it on either side; without one, against the median of all readings.
    public static func find(in readings: [Loudness], neighborhood: TimeInterval? = nil) -> [TimeInterval] {
        let sorted = readings.sorted { $0.time < $1.time }
        let medians: [Float]
        if let neighborhood {
            medians = movingMedians(sorted, reach: neighborhood / 2)
        } else {
            guard let median = median(sorted.map(\.level)) else { return [] }
            medians = Array(repeating: median, count: sorted.count)
        }

        var middles: [TimeInterval] = []
        var runStart: Loudness?
        var previous: Loudness?
        func closeRun() {
            guard let first = runStart, let last = previous else { return }
            let end = last.time + Loudness.slice
            if end - first.time >= BackABeat.shortestGap - 0.0001 { middles.append((first.time + end) / 2) }
            runStart = nil
        }
        for (reading, median) in zip(sorted, medians) {
            let contiguous = previous.map { reading.time - $0.time < Loudness.slice * 1.5 } ?? false
            if median > 0 && reading.level < median * BackABeat.quietShare {
                if runStart != nil && !contiguous { closeRun() }
                if runStart == nil { runStart = reading }
            } else {
                closeRun()
            }
            previous = reading
        }
        closeRun()
        return middles
    }

    private static func median(_ levels: [Float]) -> Float? {
        guard !levels.isEmpty else { return nil }
        return levels.sorted()[levels.count / 2]
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
