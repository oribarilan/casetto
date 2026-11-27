import Foundation

/// How much space a set of episodes takes once downloaded, from what their feeds say.
public enum DownloadSize {
    /// Feeds often list 0 or a placeholder, so a smaller size doesn't count.
    static let plausibleBytes: Int64 = 1_000_000
    /// 128 kbps, a common podcast bitrate, for episodes whose feed lists no plausible size.
    static let bytesPerSecond: Double = 16_000

    /// Each episode counts the feed's size when plausible, else its length at 128 kbps, else nothing.
    public static func estimate(_ episodes: [EpisodeInfo]) -> Int64 {
        episodes.reduce(0) { total, episode in
            if let length = episode.byteLength, length >= plausibleBytes { return total + length }
            guard let duration = episode.duration, duration > 0 else { return total }
            return total + Int64(duration * bytesPerSecond)
        }
    }

    /// "About 210 MB for the top 3.", or nil for Off or nothing to count. Whole megabytes, gigabytes with one decimal.
    public static func caption(_ episodes: [EpisodeInfo], count: Int) -> String? {
        let bytes = estimate(Array(episodes.prefix(max(count, 0))))
        guard count > 0, bytes > 0 else { return nil }
        let size =
            bytes >= 1_000_000_000
            ? (Double(bytes) / 1_000_000_000).formatted(.number.precision(.fractionLength(1))) + " GB"
            : "\(max(1, Int((Double(bytes) / 1_000_000).rounded()))) MB"
        return "About \(size) for the top \(count == 1 ? "episode" : "\(count)")."
    }
}
