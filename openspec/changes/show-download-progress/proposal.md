## Why

An episode row says "Downloaded" once its file is on the phone, but nothing shows while a download runs or while it waits. Downloads use Wi-Fi only, so away from Wi-Fi the top of the Queue can stay undownloaded with no sign why. The backlog entry "Download status in the Queue" asked for each episode's download status and progress. The listener picked option 1: words in the gray status line.

This is not a roadmap milestone. It is polish from daily use after the MVP.

## What Changes

- While an episode downloads, its status line says "Downloading 45%", updating as it goes, then "Downloaded".
- When an episode should be downloaded but the phone isn't on a network downloads may use (Wi-Fi without Low Data Mode), its status line says "Waiting for Wi-Fi".
- These words show on every episode row, in the Queue, the Inbox and on show pages, in gray like the other status words.

Out of scope: a way to start or cancel one download by hand, download space in Settings (its own backlog entry), and progress anywhere but the status line.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `downloads`: the downloaded indicator also says "Downloading N%" and "Waiting for Wi-Fi".

## Impact

- `Downloader.swift`: reports each running download's fraction done, from the session's progress callbacks.
- `AppModel.swift`: keeps the fraction for each downloading episode, and whether the phone is on a network downloads may use, watched with `NWPathMonitor`; knows which Queue episodes should be downloaded.
- `EpisodeRow.swift`: a download state (downloaded, downloading with a fraction, waiting) replaces the `downloaded` flag in the status line. The Queue, Inbox and show page pass it.
- `BACKLOG.md`: the "Download status in the Queue" entry is removed.
