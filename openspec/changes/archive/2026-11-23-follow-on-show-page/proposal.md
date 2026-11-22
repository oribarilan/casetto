# Proposal

## Why

Find Shows lets you follow a show without seeing its episodes, and the show page has no star: starring means opening the New episodes sheet and picking Queue, and Unsubscribe hides in the ⋯ menu. The app also mixes "Subscribe" on buttons with "follow" everywhere else, while Apple Podcasts says Follow.

This isn't a roadmap milestone. It extends the show page (M2) and Find Shows (M5).

## What Changes

- **Follow and Star on the show page** (design A): two wide buttons under the header, Follow or Following, and Star or Starred. Star works as in Find Shows. Tapping Following asks to confirm, then unfollows; Unsubscribe leaves the ⋯ menu. On a show you don't follow, the same two buttons replace the big Subscribe button.
- **Find Shows rows open the show page.** The app fetches the feed to show the episodes without following the show. The Follow and Star buttons on the row stay.
- **Follow, not Subscribe, in the app:** every label the app shows says Follow, Following, Unfollow, or Followed (Find Shows, the show page, the Add Show sheet, the rule card, the OPML import report, and the export file name, "Casterr Shows"). "Subscribe" stays a term inside the code and specs, like "archive". `podcast_app_concept.md` adds Follow to its word list.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `show-page`: Follow and Star buttons; the page of an unfollowed show is reachable from Find Shows and fetches its feed.
- `discovery`: Follow instead of Subscribe; a row opens the show page.
- `rule-cards`, `look-and-feel`: the Ignored card says Unfollow.

## Out of scope

- Renaming "subscribe" in code, data, or specs.
- Changing the New episodes sheet. Star and the sheet's Queue choice stay the same setting.

## Impact

- `Casterr/Screens/ShowView.swift`: the two buttons, the unfollow confirmation, fetching an unfollowed show's feed.
- `Casterr/Screens/DiscoverView.swift`: row opens the show page; labels.
- `Casterr/Screens/ShowsView.swift`, `InboxView.swift`: labels.
- `CasterrCore` `FeedService`: fetch and save a show's feed without following it, as Apple Podcasts links already do.
- `CasterrCore` `OPMLWriter`: the export's title.
- UI tests that tap Subscribe or Unsubscribe, and new ones for the buttons and opening a show from Find Shows.
