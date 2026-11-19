# Proposal

## Why

After M2, triage sorts new episodes, but only when you open the app, and every episode streams. So nothing is ready for the subway or a flight, and a new episode of a show you never miss waits until you look. This change is roadmap milestone **M3: Downloads and refresh**: the top of the Queue is on the phone before you leave the house.

## What Changes

- **Downloads follow the Queue.** The top 3 Queue episodes are kept downloaded. An episode's file is deleted when it leaves that range: played, removed, or pushed down. The number is a setting: Off, 1, 3, 5, or 10.
- **Wi-Fi only.** Downloads never use cellular data, Personal Hotspot, or Low Data Mode networks. Episodes that aren't downloaded still stream.
- **Downloads finish while the app is closed**, through a background download session.
- **Background refresh.** iOS runs a refresh when it allows. The refresh triages new episodes and expires the Inbox, as the refresh on open does, then starts downloads.
- **Playback prefers the file.** A downloaded episode plays from the phone, including offline.
- **A downloaded icon** on Queue rows whose file is on the phone.

## Capabilities

### New Capabilities

- `downloads`: keeping the top of the Queue downloaded on Wi-Fi, in the background.

### Modified Capabilities

- `playback`: a downloaded episode plays from its file, also offline.
- `subscriptions`: feeds also refresh in the background when iOS allows it.

## Out of scope

- Download progress, and manual download buttons. To download an episode, queue it.
- A cellular download setting.
- New-episode notifications.
- A storage screen. The Off setting deletes every download.
- Resuming a failed download. The next sync starts it again.

## Impact

- `CasterrCore`: a download store (files named from the episode key) and a pure plan function that says which files to start and delete. One new defaulted field, `UserSettings.downloadCount`. The player takes a lookup for local files.
- App: a background download session, a background refresh task, the Downloads menu on the Queue, and the downloaded icon. `Info.plist` gains the `fetch` background mode and the refresh task identifier.
- No new dependencies.
- **Order:** M1 (`add-player-core`) must be archived before this change, because this change modifies M1's `playback` and `subscriptions` requirements.
