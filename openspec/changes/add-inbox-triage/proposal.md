# Proposal

## Why

M1 gives Casterr a player and a Queue, but you still pick every episode by hand. This change is roadmap milestone **M2: Inbox and triage**, the first part of the bet: new episodes get sorted per show, ignored ones expire, and every automatic move explains itself and can be undone.

## What Changes

- Each subscription gets a triage level: **Inbox** (the default), **Auto-queue**, **Play next**, or **Skip**. New episodes follow it on refresh.
- **Play next** episodes go right after Now Playing, stacked in release order, above anything you queued yourself.
- An **Inbox screen**, reached from a "New (N)" row at the top of the Queue. From it you queue, dismiss, or play episodes.
- **Expiry:** Inbox episodes untouched for 7 days move to the archive. The 7 days is a global setting, and each show can override it.
- **Explain and undo:** each episode remembers its latest move: the reason and when it happened. An automatic move shows its reason and an Undo until the episode moves again, for up to 30 days.
- **Subscribing** now puts the newest episode through the show's level, instead of placing nothing.
- **Unsubscribing** now also moves the show's Inbox episodes to the archive.

## Capabilities

### New Capabilities

- `triage`: per-show levels, play next, the Inbox, expiry, and explaining and undoing automatic moves.

### Modified Capabilities

- `queue`: an episode's place can now also be the Inbox.
- `subscriptions`: subscribing places the newest episode by level, and unsubscribing archives the show's Inbox episodes.

## Out of scope

- Filters by length or title, and rule cards (M4).
- Undo for your own moves. They're one swipe to reverse.
- A history of older moves. Only the latest move per episode is kept.
- Downloads and background refresh (M3). Triage and expiry run when the app refreshes: on open and on pull to refresh.

## Impact

- `CasterrCore`: the `Place` enum gains `inbox` and new archive reasons. New fields on `Subscription`, `EpisodeState`, and `UserSettings`, all optional or defaulted under the CloudKit rules. Triage runs inside refresh and subscribe.
- App: an Inbox screen, a "New (N)" row on the Queue, triage controls on the show page, and reason and Undo labels on episode rows.
- No new dependencies.
- **Order:** M1 (`add-player-core`) must be archived before this change, because this change modifies M1's `queue` and `subscriptions` requirements.
