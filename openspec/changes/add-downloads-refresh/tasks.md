# Tasks

## 1. Core

- [ ] 1.1 Implement the download store (file name from the episode key and the audio URL's extension, list, delete, excluded from backup), and verify tests against a temporary folder
- [ ] 1.2 Implement `DownloadPlan.make`, and verify tests for the top N, Off, an episode pushed out of range, a running download that is no longer wanted, and an existing file that is still wanted
- [ ] 1.3 Add `UserSettings.downloadCount` with the `Library` getter and setter, and verify the setting tests and the CloudKit schema-rules test
- [ ] 1.4 Make `Player` load a local file when the lookup returns one, and verify `PlayerTests` for a downloaded episode and a streamed one

## 2. App

- [ ] 2.1 Build `Downloader` (background session, Wi-Fi only, the episode key as the task description, the move on finish, cancel), and verify the app builds and a queued episode downloads on the simulator
- [ ] 2.2 Implement `AppModel.syncDownloads` and its triggers (change, refresh, open, the Player's episode, a finished download), and verify that played and removed episodes lose their files on the simulator
- [ ] 2.3 Add the background refresh task, its `Info.plist` entries, and scheduling on background, and verify the app builds and the refresh runs when triggered from the debugger
- [ ] 2.4 Add the downloaded icon and the Downloads menu to the Queue, and verify in the screens UI test that a queued episode shows the icon and Off removes it

## 3. Verify

- [ ] 3.1 Update the README, and verify that all UI tests and `swift test` pass
- [ ] 3.2 Device check (needs the listener's phone): a download completes after leaving the app, a downloaded episode plays in airplane mode, a cellular-only phone starts no download, and a background refresh queues and downloads a new Auto-queue episode

## Workflow follow-up

- Archive `add-player-core` and `add-inbox-triage` before archiving this change.
