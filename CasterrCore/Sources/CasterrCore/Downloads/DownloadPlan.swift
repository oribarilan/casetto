/// Which downloads to start, cancel, and delete so the files match the top of the Queue.
public struct DownloadPlan: Equatable, Sendable {
    public var start: [EpisodeKey] = []
    public var cancel: [EpisodeKey] = []
    /// File stems, as `DownloadStore.stem(for:)` makes them.
    public var delete: [String] = []

    /// - Parameters:
    ///   - queue: Queue keys in play order.
    ///   - keep: How many Queue episodes to keep downloaded. 0 is Off.
    ///   - files: The stems of the files on disk.
    ///   - running: Keys with a download in progress.
    public static func make(queue: [EpisodeKey], keep: Int, files: [String], running: Set<EpisodeKey>) -> DownloadPlan {
        let wanted = Array(queue.prefix(max(keep, 0)))
        let wantedStems = Set(wanted.map(DownloadStore.stem(for:)))
        let fileStems = Set(files)
        return DownloadPlan(
            start: wanted.filter { !fileStems.contains(DownloadStore.stem(for: $0)) && !running.contains($0) },
            cancel: running.filter { !wanted.contains($0) }.sorted { $0.rawValue < $1.rawValue },
            delete: files.filter { !wantedStems.contains($0) }
        )
    }
}

/// The choices for how many Queue episodes to keep downloaded. 0 is Off.
public enum DownloadCount {
    public static let choices = [0, 1, 3, 5, 10]
}
