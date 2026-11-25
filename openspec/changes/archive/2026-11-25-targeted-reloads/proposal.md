# Proposal

## Why

The listener wants every animation in the app to feel snappy and smooth, and wants an architecture where a change only redoes the work it touched, even if things feel fast enough today. On the phone, Unstar and Unfollow on a show page still stutter.

What we measured on the simulator (2026-11-25):

- Every save bumps one app-wide counter, `revision`. Every screen on screen reloads all its data when it moves.
- Screens that aren't on screen don't reload then. SwiftUI already skips them. But they reload in full every time they come back on screen, even when nothing changed.
- The show page's reload is the heavy part. For one Star on a show with 1,382 episodes, it reads every episode and every episode's place again, splits them into played and unplayed, and rebuilds every row it shows.
- That reload stalled the screen for 60 to 170 ms on the simulator. Positive taps hide it behind a 0.6 s wait (follow-star-spin). Unstar and Unfollow have no wait, so it lands in their animation.
- A finished download also bumps `revision`, so the show page re-reads all its episodes each time one lands.

This is a backlog fix, not a numbered roadmap milestone.

## What Changes

- **One counter per area of data, instead of one for everything:** follows (follow, star, and a show's own settings), episodes (where each episode is, and how far you got), feeds (show and episode data from the feeds), bookmarks, settings, and downloads.
- **Each change says which areas it touched.** A change that can't say touches all of them, which is today's behavior.
- **Each screen reloads only for the areas it shows.** The show page splits its reload: a Star re-reads the show's follow and star, not its 1,382 episodes.
- **A screen that comes back on screen reloads only if something it shows changed** while it was away.
- **A finished download redraws the download words** without re-reading the library.
- **The 0.6 s wait before a spin's save goes**, if the spin stays smooth without it. That's simpler, and positive and negative taps then behave the same.
- **AGENTS.md gets the rule:** a tap shows its result at once, a change names the areas it touched, and a screen reloads only for the areas it shows.
- **Before-and-after measurement** on the listener's phone with Instruments.

## Out of scope

- Changing what any screen shows, or any wording.
- Moving to SwiftData's live queries in the views. The app keeps its rule that views get value types from the library.
- Making the feed refresh itself faster.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. No behavior in the specs changes; the app does less work after each change.

## Impact

- `Casterr/AppModel.swift`: `revision` becomes per-area counters; `change` takes the areas it touched; downloads and refresh bump their own areas.
- Every `model.change` call (36, in 15 files) names its areas.
- The screens that reload today (Queue, Inbox, Shows, Bookmarks, Settings, Find Shows, the show page) and CarPlay depend on the areas they show.
- `AGENTS.md`: the rule above.
- No version bump unless the 0.6 s wait goes, which the listener can notice: then a patch version.
