# Proposal

## Why

The listener taps the Queue tab to get to the Queue, but it opens the last page they left under it, such as the Inbox. They had to tap again or press Back to get home. The Queue is the home screen, and the pages under it are short side trips, so a tap on Queue should always land on the Queue. A tap on the tab that is already open should go back to that tab's main page, as in most iOS apps.

This is a backlog item, not a numbered roadmap milestone.

## What Changes

- **A tap on the Queue tab opens the Queue**, from another tab and from any page under the Queue (the Inbox, Settings, a show page).
- **Shows and Bookmarks keep their place.** A tap on either from another tab opens the page the listener left there.
- **A tap on the open tab goes back to its main page**: the Queue, the Shows grid, or the Bookmarks list.
- **Links the app opens by itself do not change.** The refresh message still opens the Inbox, the bookmark message still opens the bookmark, the up-next bar still opens the Queue, and a show tapped in Now Playing still opens its page in Shows.
- Version 0.8.

## Out of scope

- Scrolling a tab's main page to the top on a second tap.
- Keeping the Inbox's scroll position when the Queue tab resets.
- Any change to the tabs themselves, their order, or their names.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `queue`: a new requirement for what a tap on each tab opens.

## Impact

- `Casterr/Screens/RootView.swift`: the tab selection resets the Queue's pages on a tap on Queue, and an open tab's pages on a second tap.
- `CasterrUITests/ScreensTests.swift`: a test that opens the Inbox, switches tabs, and comes back to the Queue, and one for a second tap on Shows.
- `CHANGELOG.md` and `project.yml`: version 0.8.
