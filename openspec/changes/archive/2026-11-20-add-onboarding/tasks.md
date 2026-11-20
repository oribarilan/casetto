# Tasks

## 1. Core

- [x] 1.1 Implement `AppleDirectory` (chart plus lookup, and search), and verify tests with a stub session and fixtures trimmed from real responses, including a show without a feed address and an unreachable chart
- [x] 1.2 Implement `OPMLWriter`, and verify a round-trip test through `OPMLParser` with titles that need escaping
- [x] 1.3 Add a level parameter to `FeedService.subscribe`, and verify that subscribing at Auto-queue puts the newest episode in the Queue

## 2. App

- [x] 2.1 Move to tabs with the mini player as the bottom accessory, and verify the existing UI tests after updating their navigation
- [x] 2.2 Build `DiscoverView` (top shows, search with the 400 ms pause, Subscribe and Star), and use it in the empty Shows tab and the Shows search
- [x] 2.3 Add onboarding on first launch, and verify in a UI test that it shows, a star queues the newest episode, and Done closes it
- [x] 2.4 Add OPML export to the Shows menu, and verify the app builds and the share item appears

## 3. Verify

- [x] 3.1 Update the README, and verify that all UI tests and `swift test` pass

## Workflow follow-up

- Archive `add-player-core` before archiving this change.
