# Design

## Context

M1 streams every episode and refreshes feeds on open and on pull to refresh. M2 runs triage and expiry inside that refresh. `Player.play` loads `EpisodeInfo.audioURL` into the `AudioEngine`. The SwiftUI scene API on iOS 27 has `.backgroundTask(.appRefresh(_:))` and `.backgroundTask(.urlSession(_:))`, so neither feature needs an app delegate. The simplicity rule applies: no stored download state, no progress, no manual downloads.

## Goals / Non-Goals

**Goals:**
- Which files to keep is a pure function in `CasterrCore`, tested without a network.
- The files on disk are the only download state. Nothing about downloads goes into SwiftData except the count setting.

**Non-Goals:**
- A guaranteed refresh schedule. iOS decides when background refresh runs, and it doesn't run after the listener force-quits the app.
- Downloads on cellular, download progress, and resuming failed downloads.

## Decisions

### D1. The files are the state

Downloads live in `Application Support/Downloads`, excluded from iCloud backup. A file's name is the SHA-256 hex of the episode key, plus the audio URL's path extension (`mp3` when the URL has none), because `AVPlayer` uses the extension to detect the file type. A file exists only after a download completes, because the session delivers it to a temporary location first. So "downloaded" means "the file exists".

- Why not a stored field: a field can disagree with the disk, for example after iOS clears space or a download fails. Reading the disk can't disagree.
- Why Application Support and not Caches: downloads exist for offline listening, and iOS can purge Caches when storage runs low, which is when the listener is least likely to notice before a flight. Casterr deletes its own files, so they don't pile up.

### D2. The plan is a pure function

`DownloadPlan.make(queue:keep:files:running:) -> (start: [EpisodeKey], delete: [String])`:
- `wanted` is the first `keep` Queue keys.
- `start` is each wanted key with no file and no running download, in Queue order.
- `delete` is each file whose name isn't the name of a wanted key.
- A running download for a key that isn't wanted is cancelled.

`UserSettings.downloadCount: Int = 3`, where 0 means Off. It syncs in M8 like the other settings, so one count applies on every device.

### D3. One background session in the app

A `Downloader` class (a `URLSessionDownloadDelegate`) owns one background session with the identifier `casterr.downloads`:
- `allowsCellularAccess = false`, `allowsExpensiveNetworkAccess = false` (Personal Hotspot), and `allowsConstrainedNetworkAccess = false` (Low Data Mode).
- `sessionSendsLaunchEvents = true`, and the scene declares `.backgroundTask(.urlSession("casterr.downloads"))`, so iOS can relaunch the app to deliver finished downloads.
- Each task's `taskDescription` is the episode key, so the running downloads come back from `allTasks` after a relaunch, with no stored state.
- On finish, the delegate moves the file to its final name before it returns, because iOS deletes the temporary file after the delegate method returns. A file that arrives for a key that is no longer wanted is deleted on the next sync.
- The `Downloader` lives in the app target, because background sessions need an app bundle. `CasterrCore` holds the store and the plan, which are where the tests are.

### D4. When the downloads sync

`AppModel.syncDownloads()` reads the Queue and the count, lists the files and the running tasks, applies the plan, and bumps `revision` when a file changed. It runs:
- after every `change` and every `refresh`
- when the app opens
- when the Player's current episode changes. A finished episode is archived as played, so it leaves the Queue. The app watches `player.episode` with `Observations`.
- after a download finishes, so the Queue row shows the icon.

### D5. Playback prefers the file

`Player` takes a `localFile: (EpisodeKey, URL) -> URL?` closure that defaults to returning nil. `play` loads the local URL when the closure returns one, otherwise the audio URL. The offline error stays as it is for streamed episodes. A file deleted while it is playing keeps playing, because iOS keeps an open file readable after it is deleted.

### D6. Background refresh

- `Info.plist` gains `BGTaskSchedulerPermittedIdentifiers: [casterr.refresh]` and the `fetch` background mode.
- The scene declares `.backgroundTask(.appRefresh("casterr.refresh"))`. Its action schedules the next refresh, then runs `refreshAll` and `syncDownloads`.
- The app schedules a `BGAppRefreshTaskRequest` with `earliestBeginDate` one hour ahead when it goes to the background.
- A refresh has about 30 seconds. Feeds fetch 6 at a time, and the downloads it starts belong to the background session, so they continue after the task ends.

### D7. UI

- Queue rows show an `arrow.down.circle.fill` icon when the episode's file exists.
- A Downloads menu in the Queue toolbar sets the count: Off, 1, 3, 5, or 10. The setting lives where its effect shows, like the Inbox expiry menu.

## Risks / Trade-offs

- [iOS may run background refresh rarely, or not at all for an app the listener seldom opens] → The refresh on open stays. The spec says "when iOS allows it".
- [The simulator can't schedule background refreshes] → The device check triggers one from the debugger with `_simulateLaunchForTaskWithIdentifier:`.
- [One synced count for devices with different storage] → Acceptable for one listener. It can become a per-device setting if that hurts.
- [A failed download retries on every sync] → It's cheap on Wi-Fi, and a broken URL fails fast.

## Migration Plan

`downloadCount` is defaulted, so lightweight migration adds it. The first sync after the update starts downloading the top 3.
