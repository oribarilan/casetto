## 1. The star in the core

- [ ] 1.1 Add `starred: Bool = false` to `Subscription` and `SubscriptionInfo`, and `Library.setStarred(_:_:)`: starring an Inbox show sets Auto-queue, other levels stay, unstarring touches only the star. Verify with core tests for each case
- [ ] 1.2 Run the core tests, including sync, and confirm an existing library opens with every show unstarred

## 2. The app

- [ ] 2.1 Find Shows: Star, its tip and Cassy's cheer read and write the star; starring an unfollowed show follows it at Auto-queue and stars it. Verify in the simulator
- [ ] 2.2 Show page: the Star button reads and writes the star; tapping Starred removes only the star. Verify the New episodes row keeps its setting
- [ ] 2.3 Shows tab: "Starred" and "More Shows" sections when a show is starred and nothing is typed in search; one grid otherwise; no tile badge. Verify in the simulator, light and dark
- [ ] 2.4 Rows: a small gray star at the start of the status line for starred shows in the Queue and Inbox, with the label "Starred", not on show pages. Verify in the simulator
- [ ] 2.5 Update `podcast_app_concept.md`: a star is a favorite, starring sets Queue for an Inbox show, unstarring keeps the setting

## 3. Tests

- [ ] 3.1 Update the UI tests for Star in onboarding, Find Shows and the show page; add checks for the Shows tab sections and the star on a Queue row
- [ ] 3.2 Run the core and UI tests, and take light and dark screenshots of the Shows tab and the Queue

## Workflow follow-up

- Move any check that needs the real iPhone to `openspec/device-checks.md` before archiving.
