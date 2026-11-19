# Tasks

## 1. Domain

- [x] 1.1 Extend `Place` with `inbox` and the archive reasons `dismissed`, `expired`, `skipped`, and `unsubscribed`, and verify the round-trip and invalid-combination tests cover the new values
- [x] 1.2 Add `TriageLevel` (`inbox`, `autoQueue`, `playNext`, `skip`) and `MoveReason` (with `isAutomatic` and its stored form, including `expired:N`), and verify round-trip tests and the automatic flag for each case
- [x] 1.3 Implement `TriageLevel.destination` and `InboxExpiry.hasExpired`, and verify unit tests for each level, the 3/7/14/30/never periods, and the boundary day

## 2. Storage

- [x] 2.1 Add the new `Subscription`, `UserSettings`, and `EpisodeState` fields (optional or defaulted), and verify the CloudKit schema-rules test still passes
- [x] 2.2 Record the latest move on every place change (reason and `movedAt`). Listener actions use reason `listener`. Verify tests that the queue, played, and dismiss operations record their moves
- [x] 2.3 Implement `library.triage(show)` (new-episode rule from D2, oldest first, one save, nil `triageAfter` means set it without triaging), and verify tests for each "New episodes follow the level" scenario, including the feed-cache wipe and an already-placed episode
- [x] 2.4 Implement play-next insertion (after Now Playing and earlier play-next entries), and verify tests for the two-show stack and the empty Queue
- [x] 2.5 Implement Inbox queries (episodes newest first, count), dismiss, and `expireInbox(now:)` with global and per-show periods, and verify tests for each expiry scenario
- [x] 2.6 Implement `undo(episode)` (automatic, less than 30 days, latest move only, Inbox restore resets the period), and verify tests for each undo scenario
- [x] 2.7 Implement the level, expiry-override, and global-expiry setters, and verify tests for each

## 3. Feed flow

- [x] 3.1 Run triage after each feed refresh and `expireInbox` after refresh-all, and verify a `FeedService` test where a new fixture episode lands per level
- [x] 3.2 Subscribe places the newest episode by level, and verify the back-catalog scenario test (newest in the Inbox, the rest with no place)
- [x] 3.3 Unsubscribe archives Inbox episodes with reason `unsubscribed`, and verify the unsubscribe-with-Inbox test

## 4. Screens

- [x] 4.1 Add the "New (N)" row to the Queue screen and build `InboxView` (newest first, swipe to queue or dismiss, tap to play, global expiry menu), and verify in the screens UI test
- [x] 4.2 Add triage controls to the show page (level picker, expiry override for Inbox shows), and verify in the screens UI test
- [x] 4.3 Show reason labels and an Undo button on episode rows (Queue, Inbox, show page), and verify in the screens UI test by expiring an episode with the `-fastClock` launch argument and undoing it
- [x] 4.4 Update the screens UI test and README, and verify that all UI tests and `swift test` pass

## Workflow follow-up

- Archive `add-player-core` before archiving this change.
- Archive this change after the user approves the results.
