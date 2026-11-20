# Proposal

## Why

Everything you do in Casterr lives on one phone. A new phone, or a reinstall, loses your subscriptions, Queue, and bookmarks. This change is roadmap milestone **M8: CloudKit sync**, the last step before Casterr becomes a daily driver.

## What Changes

- The **user data store syncs** with the listener's private iCloud database: subscriptions, episode states, settings, and bookmarks. The feed cache and downloads stay on the device.
- **Duplicates merge.** When two devices create a record for the same thing, the app keeps one: per episode, the latest move wins. Settings keep the most recently changed record.
- The app **merges and reloads** when it opens and on every refresh, so changes from other devices show up then.
- **Setup is the listener's.** The repository ships the entitlements file and the setup steps, with the team and container left for the listener to fill in. Without them, the app runs exactly as before, on one device.

## Capabilities

### New Capabilities

- `sync`: what syncs, how duplicates merge, and running without iCloud.

### Modified Capabilities

None.

## Out of scope

- Sharing with other people, and a public database.
- A sync status screen or a sync on/off setting. iCloud's system setting turns it off.
- Live updates while the app is open. Changes from another device show at the next open or pull to refresh.
- Syncing downloads or the feed cache.
- Per-device settings. The download count stays synced.

## Impact

- `CasterrCore`: the feed cache store sets `cloudKitDatabase: .none` explicitly (it defaulted to `.automatic`), the user store uses `.automatic`, `UserSettings` gains `updatedAt`, and `Library.mergeDuplicates()` merges.
- App: merge on refresh, the `remote-notification` background mode, and an entitlements file.
- README: the iCloud setup steps.
- No new dependencies.
