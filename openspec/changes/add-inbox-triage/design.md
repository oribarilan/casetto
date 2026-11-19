# Design

## Context

M1 is built: the `Library` actor owns a SwiftData container with a feed cache store and a CloudKit-safe user store, and `FeedService` subscribes and refreshes. `EpisodeState` holds the place (`queue` or `archive`, with a reason), `queuePosition`, and progress. Requirements are in this change's specs. The simplicity rule applies: no Event log (the latest move lives on `EpisodeState`), no filters (M4), and no undo for the listener's own moves.

## Goals / Non-Goals

**Goals:**
- Triage is a pure decision function in `CasterrCore`, tested without storage.
- Triage is idempotent. Re-fetching feeds, or a second device after M8, never triages an episode twice.

**Non-Goals:**
- Background triage. It runs when the app refreshes.
- A tab bar. The Inbox is one tap from the Queue.

## Decisions

### D1. Data changes, all CloudKit-safe

- `Subscription`:
  - `level: String = "inbox"`: `inbox`, `autoQueue`, `playNext`, or `skip`
  - `expiryDaysOverride: Int?`, where 0 means never
  - `triageAfter: Date?`
- `UserSettings`:
  - `expiryDays: Int = 7`, where 0 means never
- `EpisodeState`, the latest move:
  - `moveReason: String?`
  - `movedAt: Date?`
- `Place` gains `.inbox`. `ArchiveReason` gains `dismissed`, `expired`, `skipped`, and `unsubscribed`.

A `MoveReason` enum in the domain lists every move with whether it's automatic:

| Reason | Automatic |
|---|---|
| `autoQueued` | yes |
| `playNext` | yes |
| `arrived` (into the Inbox) | yes |
| `skippedByLevel` | yes |
| `expired(days)` | yes |
| `listener` | no |

Expired stores its day count in the raw string (`expired:7`), so the label can say "after 7 days" even if the setting changes later. A move is undoable exactly when it has a label, so `arrived` and `listener` have neither.

Play next is a fourth level, not a flag on Auto-queue, so the show page needs one picker and the subscription one field.

- Alternative: an Event log table. We rejected it to avoid a primitive and a retention job. The cost is that only the latest move is explained.

### D2. Which episodes are new

An episode is new for a show when its publish date is later than `Subscription.triageAfter` and it has no `EpisodeState`. Subscribing sets `triageAfter` once and it never moves.

- Why: inserted feed-cache records can't be the signal, because wiping the cache would make every episode look new. The date plus the "no state yet" check is wipe-safe, and under sync a device never overrides a place set elsewhere.
- Why fixed: the "no state yet" check already prevents a second triage. A date that never moves also catches an episode whose publish date is earlier than the time it appeared in the feed.
- Episodes without a publish date are never auto-triaged. That's rare, and they stay on the show page.

### D3. Triage as a pure function

`TriageLevel.destination` gives the place and reason for each level. `InboxExpiry.hasExpired(enteredAt:now:)` covers expiry. `Library` applies the decisions in one save per show. Play-next insertion is a `Library` queue operation: start at position 2, after Now Playing, and walk past the leading run of entries whose reason is `playNext`. New episodes are processed oldest first, so the stack keeps release order.

### D4. When triage runs

`FeedService.refresh` saves the feed, then calls `library.triage(show)`. After every refresh-all, `library.expireInbox()` runs. `Library` takes its time from a replaceable clock, so tests can move time forward. Subscribing triages the newest episode only: it sets `triageAfter` to the second-newest date, then triages.

### D5. Undo

`library.undo(episode)` is allowed when the latest move is automatic and less than 30 days old. The reason tells where the episode was: an expired episode came from the Inbox, and every other automatic move came from no place. So no previous place is stored. A restore into the Inbox sets `movedAt = now`, so the episode gets a full new period. The restore itself counts as a listener move, so it can't be undone again.

### D6. UI

- **Queue screen:** a "New (N)" row at the top links to `InboxView`.
- **InboxView:** episodes newest first. Swiping right queues an episode, swiping left dismisses it, and tapping plays it. A toolbar menu sets the global expiry (3, 7, 14, or 30 days, or never), so the setting lives in context.
- **Show page:** a level picker (Inbox, Add to Queue, Play Next, Skip) and, for Inbox shows, an expiry override (Default, 3, 7, 14, 30, Never).
- **Episode rows** show the reason label and an Undo button when it's allowed.

## Risks / Trade-offs

- [Feeds with wrong or missing publish dates] → Undated episodes aren't auto-triaged. An episode back-dated by its publisher is missed and stays on the show page. Both are acceptable for M2.
- [Expiry only runs on refresh, so an episode can sit past its period while the app is closed] → It expires on the next open. M3 adds background refresh.
- [Only the latest move is kept] → A second move replaces the first, and the explanation follows the latest one. That matches "Undo until it moves again".

## Migration Plan

New fields are optional or defaulted. SwiftData's lightweight migration adds them to existing stores. `triageAfter` starts nil on existing subscriptions. The first triage then sets it to the newest publish date without placing anything, so existing users don't get a flood of Inbox episodes.
