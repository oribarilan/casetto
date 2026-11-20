# Tasks

## 1. Core

- [x] 1.1 Set the feed cache to `.none` and the user store to `.automatic` (`.none` in memory), add `Library.open(directory:)`, and verify the existing tests and a test that both libraries see each other's writes
- [x] 1.2 Add `UserSettings.updatedAt`, set by every setter, and verify the schema-rules test
- [x] 1.3 Implement `Library.mergeDuplicates()`, and verify tests for each scenario: the latest move wins, the earliest first play is kept, the earliest subscription wins, the latest settings win, and the Queue renumbers

## 2. App

- [x] 2.1 Merge on refresh, add the `remote-notification` background mode, and verify the app builds, runs outside test mode without the entitlement, and all UI tests pass
- [x] 2.2 Add the entitlements file and the README setup steps

## 3. Verify

- [ ] 3.1 Phone check (needs the listener's setup): subscribe on a set-up phone and see the record in the CloudKit dashboard; queue an episode in the dashboard or on a second device and see it after reopening the app; reinstall and see the data return → Tracked in `openspec/device-checks.md`.
