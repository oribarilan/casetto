# Proposal

## Why

A show opened from Find Shows isn't on the phone yet, so its page fetches the feed first. Until then the header is missing and a spinner says "Loading episodes…". Then the header appears all at once and the art starts its own shimmer. The page jumps instead of filling in.

This is a backlog item, not a numbered roadmap milestone.

## What Changes

- While the feed loads, the show page keeps its final layout: the header's art, title, author and description show as shimmering placeholders, and four shimmering episode rows replace the spinner.
- A show opened from Find Shows shows the name, host and art that Apple's directory already gave at once. Only the description and episodes shimmer.
- On a show from Find Shows, the art stays the directory's picture after the feed arrives, so it doesn't reload and shimmer twice.
- With Reduce Motion on, the placeholders stay still, as the art shimmer does today.
- The backlog entry goes.

## Out of scope

- Shows you follow, which open from the phone's own data almost at once.
- Placeholders anywhere else, such as the Queue, the Inbox or Find Shows.
- A slow or failing feed. The existing error line stays as it is.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `show-page`: a new requirement for what the page shows while the feed loads.

## Impact

- `Casterr/Screens/Theme.swift`: the art shimmer becomes a modifier any placeholder can use.
- `Casterr/Screens/ShowView.swift`: placeholder header and rows, and the directory's name, host and art when given.
- `Casterr/Screens/RootView.swift` and `DiscoverView.swift`: Find Shows passes the directory entry instead of only the feed address.
- `CHANGELOG.md` and `project.yml`: version 0.3.1, since the page only looks better while loading.
