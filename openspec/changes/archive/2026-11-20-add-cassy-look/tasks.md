# Tasks

## 1. Core

- [x] 1.1 Return counts from `triage` and `expireInbox`, add `RefreshSummary` with `sentence`, return it from `refreshAll`, and verify tests for the mixed, single, plural, and quiet cases
- [x] 1.2 Add `ArtworkTint.color(of:)`, and verify tests with generated solid green, grey, and near-white images that the result is dark enough for white text
- [x] 1.3 Add `Library.showArt()` (title and artwork address per show), and verify a test
- [x] 1.4 Add `Player.queueRanOutAt`, and verify `PlayerTests` that it's set when the last episode ends and not when the end-of-episode timer stops playback

## 2. App

- [x] 2.1 Add the theme (tangerine tint, rounded type, large title appearance) and the image cache
- [x] 2.2 Add `ArtworkView` and show art on rows, the mini player, and the show page header
- [x] 2.3 Build the Shows grid with star and warning badges
- [x] 2.4 Tint Now Playing from the artwork, with no Cassy there; playback problems show in her toast
- [x] 2.5 Build `CassyView` with the four moods, their motion, and Reduce Motion support
- [x] 2.6 Put Cassy in the empty Queue, empty Inbox, failing feed, rule cards, onboarding, and bookmark toast, with the copy from D9
- [x] 2.7 Add the Cassy toast with the refresh summary and the end-of-queue offer

- [x] 2.8 Add the `CassyAnimation` catalog (idle loops and functional animations) and `CassyJob` with tests, drive `CassyView` by job, and use the idle job for the rule card avatar and the onboarding intro
- [x] 2.9 Rebuild the rule card as layout E with the accent show name, and update the rule card UI test





## 3. Verify

- [x] 3.1 Update the UI tests for the new copy, check the refresh summary toast with the fast clock, and verify that all UI tests and `swift test` pass
- [x] 3.2 Send screenshots of each screen in light and dark for review
