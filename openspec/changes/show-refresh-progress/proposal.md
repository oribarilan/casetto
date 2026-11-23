## Why

While shows refresh, Cassy appears as a row at the top of the Queue list and disappears when the refresh ends. The row pushes every episode down and pulls them back up, with no animation, so the list jumps every time the app opens. After trying Cassy in the top bar, the listener chose design A: a thin progress line that fills as shows are checked. Cassy stays for outcomes, in the refresh summary toast.

This is not a roadmap milestone. It is polish from daily use after the MVP, logged in the backlog as "Cassy's entrance and exit while the Queue loads".

## What Changes

- Cassy's loading row at the top of the Queue goes away.
- While a refresh runs, a 2-point tangerine line under the Queue's title fills as each show is checked, fills to the end when the refresh finishes, and fades out. Nothing in the list moves.
- The same line shows whether the listener pulled to refresh or the app refreshed on its own.
- The refresh reports how many shows it has checked out of how many, so the line shows real progress.
- VoiceOver reads the line as "Checking for new episodes" with a percentage.

Out of scope: the line on other tabs, keeping the system pull-to-refresh spinner open, and any change to the summary toast.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `look-and-feel`: a new requirement for the refresh progress line on the Queue.

## Impact

- `FeedService.refreshAll` takes a `progress` callback, called with 0 first and then after each show. A core test covers it.
- `AppModel.refreshProgress` holds the progress from 0 to 1 while a refresh runs.
- `QueueView.swift`: the loading row is removed and a `RefreshLine` overlay draws the line.
- `BACKLOG.md`: the entry for Cassy's loading animation is removed.
