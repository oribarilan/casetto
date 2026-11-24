## Context

`FeedParser.episode(_:)` reads FeedKit's enclosure attributes (url, type) but not `length`. Episodes live in `EpisodeRecord` (SwiftData, feed data, not synced) and reach the app as `EpisodeInfo`. Settings shows Keep downloaded as a segmented picker (Off, 1, 3, 5, 10) and already shows "Downloaded episodes" in Storage. `AppModel.performSync` takes the top of `library.playableQueue()` and leaves out shared files.

## Goals / Non-Goals

**Goals:** a size line under the picker that follows the choice.

**Non-Goals:** a megabyte cap, sizes per segment, measuring files with network requests.

## Decisions

- **Store the feed's size.** `ParsedEpisode.byteLength: Int64?` from the enclosure's `length`; `EpisodeRecord.byteLength` and `EpisodeInfo.byteLength`, optional, so SwiftData adds the column with no migration code. Refresh updates it like the other feed fields.
- **Estimate in the core.** `DownloadSize.estimate(_ episodes: [EpisodeInfo]) -> Int64`: each episode counts its `byteLength` when it's at least 1 MB (feeds often put 0 or a placeholder), else `duration × 16,000` bytes (128 kbps), else nothing. Tested in the core.
- **Query.** `Library.queueEpisodes(limit:)` returns the top playable Queue episodes, leaving out shared files, the same way downloads pick them. Settings loads it once with the largest choice (10) and slices per choice, so tapping is instant.
- **Words.** "About 210 MB for the top 3." with `ByteCountFormatter` file style rounded to whole megabytes, or gigabytes with one decimal above 1 GB ("About 1.2 GB for the top 10."). A gray caption inside the Downloads row, under the picker.

## Risks / Trade-offs

- Feed sizes can be wrong. The line says "About", and the Storage section shows the real downloaded size.
- Existing episodes have no size until their feed refreshes; until then they count by length.
