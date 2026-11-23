## Why

A star does two jobs at once: it marks a favorite, and it sets the show's new episodes to go to the Queue. Because of that, a show set to Play next gets the star badge in the Shows grid, while its own page says "Star", and tapping that button changes it to Queue. The listener wants the star to mean favorite, separate from where new episodes go.

This is not a roadmap milestone. It is polish from daily use after the MVP. The listener picked design 2, a Starred section in the Shows tab, kept the star over a heart, and asked for a quiet star on episodes from starred shows.

## What Changes

- **BREAKING:** a star is a favorite, saved on its own for each followed show. It no longer is the Queue setting.
- Starring a show sets its new episodes to Queue only when they go to the Inbox. Play next and Skip stay as they are. The listener can change the setting any time, and the show stays starred.
- Unstarring removes only the star. The new-episode setting stays.
- Starring a show you don't follow follows it, starred, with new episodes set to Queue, as today.
- The Shows tab shows starred shows under a "Starred" heading, then the rest under "More Shows". With nothing starred, there are no headings. While searching, results are one grid, as today. The star badge on grid tiles goes away; the heading replaces it.
- An episode of a starred show shows a small gray star at the start of its status line in the Queue and the Inbox. A show page leaves it out, because every row there would have it.
- The Inbox's "Queue them" card changes only the new-episode setting. It doesn't star.
- Cassy's cheer and the star tip in Find Shows follow the star, not the setting.

Calls made while writing this, open to correction: starring leaves Play next and Skip alone; unstarring keeps the setting; the card doesn't star.

No migration: existing shows start unstarred. The listener is the only user and re-stars by hand.

Out of scope: a heart instead of the star, sorting inside the Starred section other than A to Z, and starring from an episode row.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `subscriptions`: a new requirement for the star as a favorite, the Starred section, and the star on episode rows.
- `discovery`: Star in Find Shows follows the show starred and no longer stands for the Queue setting; tapping it again removes only the star.
- `show-page`: the Star button sets and removes the star; tapping Starred no longer returns the show to Inbox.
- `look-and-feel`: the Shows grid scenario marks starred shows with the Starred section instead of a badge on Auto-queue and Play next shows.

## Impact

- CasterrCore: `Subscription` gets `starred: Bool = false`, synced like the other fields. `SubscriptionInfo` exposes it. `Library.setStarred(_:_:)` sets it and, when starring an Inbox show, sets the level to Auto-queue. Tests for both.
- `DiscoverView.swift`, `ShowView.swift`: Star reads and writes the star, not the level.
- `ShowsView.swift`: two sections, no badge.
- `EpisodeRow.swift`, `QueueView.swift`, `InboxView.swift`: a `starred` flag draws the gray star.
- UI tests: the star flows in onboarding, Find Shows, the show page, and the Shows grid.
- `podcast_app_concept.md`: what a star means.
