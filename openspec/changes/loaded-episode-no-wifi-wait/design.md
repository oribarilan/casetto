## Context

`DownloadState.of(downloaded:progress:wanted:downloadsAllowed:)` in CasterrCore picks the download word; `AppModel.downloadState(_:)` feeds it for every row. The player knows the loaded episode as `player.episode`. `Downloader` runs one background URLSession that refuses cellular, expensive and constrained networks. `AppModel` reads the network from an `NWPathMonitor` into `downloadsAllowed`. Action lines are built per screen (`QueueView.actions`, `ShowView.actions`); Inbox episodes aren't in the download range, so the Inbox never needs the new action.

## Goals / Non-Goals

**Goals:** drop "Waiting for Wi-Fi" on the loaded episode; let the listener download one waiting episode over cellular.

**Non-Goals:** a cellular setting, downloading everything waiting at once, a "Streaming" word, downloads outside the top of the Queue.

## Decisions

- **Loaded flag in the core.** `DownloadState.of` gains `loaded: Bool`; when loaded and waiting it returns nil. Downloaded and Downloading are unchanged. `AppModel.downloadState` passes `player.episode?.key == episode.key`.
- **Second background session.** `Downloader` gets a session `casterr.downloads.cellular` that allows cellular, expensive and constrained networks, and `startOnCellular(_:from:)` cancels the episode's waiting Wi-Fi task and starts it there. `running()` lists tasks from both, so the usual rule cancels or keeps them the same way, and they survive a relaunch the same way.
- **When to offer it.** `AppModel` also keeps `onLimitedNetwork`: the path is satisfied but expensive or constrained. A row offers the action when that's true, the episode is wanted, not downloaded, and not downloading. Offline, the action stays hidden, because it couldn't start.
- **Instant feedback.** Tapping sets the episode's progress to 0, so the row says "Downloading 0%" until the first bytes arrive.
- **Label and warning.** "Download" with the `arrow.down.circle` symbol. Off Wi-Fi is the only time it shows, and Cassy's toast is the warning: "Downloading on cellular, about 62 MB.", with the size from the download's first bytes, or without it when the server sends none. No confirm.
- Rejected: a Settings switch (has to be remembered and turned off), and one tap that downloads every waiting episode until the next Wi-Fi (tapping one row would start others).

## Risks / Trade-offs

- A cellular download that's still running when the phone reaches Wi-Fi keeps going in its session. That's fine; it finishes sooner.
- If the episode leaves the top of the Queue mid-download, the usual check cancels it, as it does today.
