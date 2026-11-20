# Proposal

## Why

Casterr works, but it looks like a settings screen: text rows, system blue, and no show art outside Now Playing. Its pitch is an inbox that triages itself and explains every move, and right now those explanations are anonymous labels. This change gives Casterr the look picked in the Glow-Up mockups, Tangerine, and gives the automation a face: Cassy, who suggests rule changes, sums up what a refresh did, and reacts when things happen.

## What Changes

- **Tangerine look:** a tangerine accent in light and dark, heavy rounded titles, and rounded type throughout.
- **Show art everywhere:** on Queue, Inbox, and show page rows, a three-column Shows grid, a large show page header, and the mini player. A bigger image cache keeps scrolling from downloading art again.
- **Now Playing tinted** by the show's artwork color.
- **Cassy**, a sticker-style cassette whose reels are her eyes, in four moods: playing (reels spin while audio plays), dozing, cheering, and dizzy. She is never angry.
- **Cassy's jobs**, in her own voice (first person):
  - She presents the rule cards, as a speech bubble with the same buttons as today.
  - After a refresh that moved episodes, she sums it up in a toast: "3 new episodes. I queued 1 and removed 2 old ones from your Inbox." Tapping it opens the Inbox.
  - She guides onboarding and cheers at the first star.
  - She reacts in the bookmark toast.
  - When the last Queue episode finishes, she offers to check for new episodes.
  - She dozes on an empty Queue, cheers on an empty Inbox, and gets dizzy on a failing feed.
- **Rows keep neutral labels** ("Auto-queued", "Removed after 7 days"), so lists stay short. Cassy speaks only in cards, toasts, and empty states.
- **One copy pass** in a warm, witty voice. The full list is in the design.

## Capabilities

### New Capabilities

- `look-and-feel`: the Tangerine look, show art, the Now Playing tint, and Cassy's moods and jobs.

### Modified Capabilities

None. Behavior is unchanged; this change is presentation, plus the refresh summary and the end-of-queue offer, which are new.

## Out of scope

- The "Top Shows" heading and personal suggestions. That interview comes after this change.
- A banner on the Queue for failing feeds. The show page and the Shows grid show it.
- Custom fonts. SF Pro Rounded comes with iOS.
- An app icon with Cassy. It can follow as its own small change.
- Cassy's sheepish and puzzled moods from the mockups.

## Impact

- `CasterrCore`: `RefreshSummary` (counts from triage and expiry, and its sentence), an artwork tint function, a query for every show's artwork address, and a Player signal when the Queue runs out.
- App: a theme, `ArtworkView`, `CassyView`, a Cassy toast, the Shows grid, the show page header, and copy updates across the screens.
- UI tests: updated copy, plus checks for the refresh summary and Cassy's empty states.
- No new dependencies.
