# Design

## Context

Since M1 the user store follows the CloudKit rules (no unique attributes, every property optional or defaulted, no relationships), and a schema test enforces them. SwiftData's `ModelConfiguration` takes `cloudKitDatabase: .automatic | .none | .private(_:)`, and the default is `.automatic`, which syncs with the first iCloud container in the app's entitlements and does nothing without one. Both stores use that default today, so the feed cache would try to sync as soon as entitlements exist, and its unique attributes would fail CloudKit's rules.

## Decisions

### D1. Configurations

- FeedCache: `cloudKitDatabase: .none`, always.
- UserData: `.automatic`, so sync turns on with the entitlement and stays off without it. In-memory stores (tests and UI tests) use `.none`.

### D2. Merging duplicates

CloudKit merges edits to one record by itself. Duplicates come from two devices creating records for the same thing before they sync. `Library.mergeDuplicates()` runs after every refresh, which includes every app open, and saves only when it changed something:
- **Episode states**, grouped by episode key: keep the record with the latest `movedAt`, with no move counting as oldest. It takes the earliest `firstPlayedAt` of the group. Delete the rest.
- **Subscriptions**, grouped by show key: keep the earliest `subscribedAt`.
- **Settings**: keep the latest `updatedAt`. Every settings setter sets `updatedAt`, and a record that was only created with defaults keeps `distantPast`, so a new device's defaults lose to the listener's settings.
- **Queue**: renumber 1 to N by position, with ties going to the later move.
- Bookmarks never duplicate, because each has its own `UUID`.

Concurrent reorders on two devices: CloudKit keeps the last write per record, so positions can mix. The renumbering keeps the Queue valid, and the latest reorder mostly wins, which matches the decision that a lost reorder is acceptable.

### D3. When changes show

Changes from other devices show when the app opens and on pull to refresh, because both refresh, merge, and reload. A live listener on `NSPersistentStoreRemoteChange` was tried and removed: it also fires on the app's own saves, so merging there saved, fired again, and looped. Filtering the app's own saves needs persistent history and transaction authors, which is more machinery than a pull to refresh is worth.

### D4. Setup by the listener

`Casterr/Casterr.entitlements` declares CloudKit, the container placeholder, and `aps-environment`. It isn't referenced by `project.yml`, because a placeholder container fails signing. The README lists the steps: set `DEVELOPMENT_TEAM`, replace the container ID, and add `CODE_SIGN_ENTITLEMENTS`. `Info.plist` gains the `remote-notification` background mode, which CloudKit uses to deliver changes.

### D5. Testing

The merge runs against two `Library` actors opened on the same store files in a temporary folder, the way two sync imports would write. An internal `Library.open(directory:)` makes that possible. Sync itself is checked by the listener on a phone and in the CloudKit dashboard.

## Risks / Trade-offs

- [The long-lived `Library` context may hold stale objects after an import] → Views fetch again on every reload. The phone check confirms that a change from a second device shows up after opening the app.
- [CloudKit schema changes need deploying to production before TestFlight] → A step in the README.

## Migration Plan

`updatedAt` is defaulted. Turning sync on uploads the existing user store. Nothing changes for listeners without the entitlement.
