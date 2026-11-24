## 1. Core

- [x] 1.1 Read the enclosure length in `FeedParser` into `ParsedEpisode.byteLength`, with a parser test
- [x] 1.2 Store it in `EpisodeRecord` and `EpisodeInfo`, and update it on refresh
- [x] 1.3 Add `DownloadSize.estimate` with tests: feed size, implausible size, length only, neither
- [x] 1.4 Add `Library.queueEpisodes(limit:)`, leaving out shared files

## 2. App

- [x] 2.1 Show the size line under the Keep downloaded picker, following the choice, hidden for Off or nothing to count
- [x] 2.2 Remove the backlog entry and add a phone check to `openspec/device-checks.md`
- [x] 2.3 Run the core and UI tests
