## Context

A star is the Auto-queue level today: `DiscoverView` and `ShowView` read `level == .autoQueue` for the button and write the level when tapped. `ShowsView` badges `.autoQueue` and `.playNext` shows. `Subscription` is a SwiftData model synced through CloudKit, and per-show settings such as `voiceBoostOverride` are plain optional or defaulted fields on it. See proposal.md for why.

## Goals / Non-Goals

**Goals:**
- One saved fact for the star, read in one way everywhere.

**Non-Goals:**
- No migration code. A new field with a default is picked up by SwiftData and CloudKit by itself; existing shows read `false`.
- No change to triage levels or the New episodes sheet.

## Decisions

**The star is a field on `Subscription`.** `var starred: Bool = false`, exposed on `SubscriptionInfo`. A separate model or a list of starred keys in settings would need its own sync and cleanup on unfollow; a field goes away with the subscription.

**One library call owns the rule.** `Library.setStarred(_ showKey: ShowKey, _ starred: Bool)` sets the field and, when starring a show at `.inbox`, sets the level to `.autoQueue` in the same save. Unstarring touches only the field. Every Star button calls it, so the rule lives in one place and has core tests.

**Starring an unfollowed show** subscribes at `.autoQueue` (as today, so the newest episode is queued), then calls `setStarred(key, true)`.

**Find Shows keeps a map of subscriptions.** `DiscoverView.levels` becomes the followed shows' `SubscriptionInfo`, so the Star button, the + button and Cassy's cheer read `starred` and following separately. `isStar` and `starredBefore` switch from levels to the flag.

**Shows tab sections.** `ShowsView` splits its sorted rows into starred and the rest. With at least one starred show and no search, it shows two `Section`s with headers "Starred" and "More Shows"; otherwise one grid, as today. The shared-files show always sits in the rest. The tile's star badge is removed.

**Star on rows.** `EpisodeRow` gets `var starred = false`. When true, the status line starts with `star.fill` at caption size in `.secondary`, with the accessibility label "Starred". The Queue and Inbox load the set of starred show keys with their other row data and pass `starred:`; the show page doesn't pass it.

## Risks / Trade-offs

- [Unstarring keeps queuing] → It is the decoupled rule the listener chose. The New episodes row on the show page shows the setting right under the button.
- [Existing favorites start unstarred] → Accepted: one user, a few taps to re-star.
