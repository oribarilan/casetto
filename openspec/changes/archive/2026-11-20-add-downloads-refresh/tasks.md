# Tasks

## 1. Core

- [x] 1.1 Implement the download store (file name from the episode key and the audio URL's extension, list, delete, excluded from backup), and verify tests against a temporary folder
- [x] 1.2 Implement `DownloadPlan.make`, and verify tests for the top N, Off, an episode pushed out of range, a running download that is no longer wanted, and an existing file that is still wanted
- [x] 1.3 Add `UserSettings.downloadCount` with the `Library` getter and setter, and verify the setting tests and the CloudKit schema-rules test
- [x] 1.4 Make `Player` load a local file when the lookup returns one, and verify `PlayerTests` for a downloaded episode and a streamed one

## 2. App

- [x] 2.1 Build `Downloader` (background session, Wi-Fi only, the episode key as the task description, the move on finish, cancel), and verify the app builds and a queued episode downloads on the simulator
- [x] 2.2 Implement `AppModel.syncDownloads` and its triggers (change, refresh, open, the Player's episode, a finished download), and verify with the plan tests and the Off check in the UI test. Played and removed episodes use the same sync and are checked in 3.2
- [x] 2.3 Add the background refresh task, its `Info.plist` entries, and scheduling on background, and verify the app builds. The simulator has no `BGTaskScheduler`, so the run check moves to 3.2
- [x] 2.4 Add the downloaded icon and the Downloads menu to the Queue, and verify in the screens UI test that a queued episode shows the icon and Off removes it

## 3. Verify

- [x] 3.1 Update the README, and verify that all UI tests and `swift test` pass
- [ ] 3.2 Device check (needs the listener's phone): a download completes after leaving the app, a downloaded episode plays in airplane mode, a played or removed episode loses its file (the icon moves to the next episode), a cellular-only phone starts no download, and a background refresh triggered from the debugger logs "Background refresh started" and queues and downloads a new Auto-queue episode → Tracked in `openspec/device-checks.md`.

## Workflow follow-up

- Archive `add-player-core` and `add-inbox-triage` before archiving this change.
