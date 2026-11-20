# Proposal

## Why

So far you can only subscribe by pasting a feed address or importing OPML, and mainstream switchers have neither. This change is roadmap milestone **M5: Onboarding**, with **M7: OPML export** folded in: a new listener finds shows in a minute, marks the ones they never miss, and can take their list elsewhere.

## What Changes

- **Two tabs:** Queue and Shows, with the mini player above the tab bar. Bookmarks joins as a third tab in M6.
- **Top shows:** Apple's documented top podcasts chart for the listener's country, with no genres.
- **Search** through the iTunes Search API, from the Shows tab.
- **Star a show** to subscribe at Auto-queue, so the shows you never miss start auto-queued. A plain subscribe starts at Inbox.
- **Onboarding:** on first launch, a skippable screen with top shows and search. The same view fills the Shows tab whenever you follow nothing.
- **OPML export** from the Shows tab, through the share sheet.

## Capabilities

### New Capabilities

- `discovery`: top shows, search, starring, and onboarding.

### Modified Capabilities

- `subscriptions`: export subscriptions as OPML.
- `queue`: the Queue is the first of two tabs.

## Out of scope

- Genre charts and curated lists.
- Other directories. The Apple directory is one struct, and a protocol can come with a second directory.
- Show details before subscribing. Subscribing is one tap and unsubscribing is on the show page.

## Impact

- `CasterrCore`: an `AppleDirectory` client (chart, lookup, search) and an OPML writer.
- App: a tab view, a Discover view used in onboarding and the empty Shows tab, search in the Shows tab, and an export item.
- No new dependencies.
- **Order:** archive M1 (`add-player-core`) before this change, because this change modifies its `subscriptions` and `queue` requirements.
