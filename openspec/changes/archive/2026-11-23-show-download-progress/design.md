## Context

`Downloader` runs a background `URLSession` whose task descriptions are episode keys; `AppModel.performSync` makes a `DownloadPlan` from the top of the Queue and the Keep downloaded setting. Rows learn "Downloaded" from `model.isDownloaded(episode)`. Nothing tracks progress or the network.

## Decisions

**Progress from the session delegate.** `Downloader` implements `urlSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)` and hands `(key, fraction)` to a closure the model sets. The model stores `downloadProgress: [EpisodeKey: Double]`, updating at most a few times a second, and clears an entry when the file is saved or the task ends. Polling `session.allTasks` would also work but wakes up even when nothing downloads.

**Waiting means "wanted, not running, no usable network".** The model keeps the plan's wanted keys from the last sync, and a `downloadsAllowed` flag from `NWPathMonitor`: Wi-Fi or wired, not expensive, not constrained, matching the session's own rules. A wanted episode with no file and no progress shows "Waiting for Wi-Fi" when downloads aren't allowed; on a usable network it shows "Downloading 0%" until bytes arrive.

**One download state on the row.** `EpisodeRow` takes `download: DownloadState?` (`.downloaded`, `.downloading(Double)`, `.waiting`) instead of `downloaded: Bool`, and turns it into the last gray word. One helper on `AppModel` gives the state for an episode, so the three screens can't disagree.

**Percent rounding.** Whole percents, rounded down, so 100% only shows as "Downloaded".

## Risks / Trade-offs

- [Rows redraw on each progress update] → Updates are throttled, and only rows whose state changed redraw.
- [A server that sends no content length] → No fraction is known; the row says "Downloading" with no number.
