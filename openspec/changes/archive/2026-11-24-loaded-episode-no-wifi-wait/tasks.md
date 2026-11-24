## 1. Core

- [x] 1.1 Add `loaded` to `DownloadState.of`, returning nil instead of `.waiting` for the loaded episode
- [x] 1.2 Add DownloadTests: loaded and waiting gives nil; loaded and downloaded or downloading keeps its word

## 2. Downloads

- [x] 2.1 Add the cellular background session to `Downloader`, a `cellular` flag on `start`, and list both sessions in `running()`
- [x] 2.2 Track `onLimitedNetwork` in `AppModel` from the path monitor
- [x] 2.3 Add `AppModel.canDownloadOnCellular(_:)` and `downloadOnCellular(_:)`, which starts the download and shows "Downloading 0%" at once

## 3. Rows

- [x] 3.1 Pass whether the episode is loaded from `AppModel.downloadState`
- [x] 3.2 Add Download before Share in the Queue and show page action lines when it applies

## 4. Wrap up

- [x] 4.1 Remove the backlog entry "Waiting for Wi-Fi on the episode that's streaming"
- [x] 4.2 Add phone checks to `openspec/device-checks.md`: on cellular, the playing Inbox episode reads "Playing" with no "Waiting for Wi-Fi"; Download downloads only that episode; it's gone on Wi-Fi and offline
- [x] 4.3 Run the core and UI tests
