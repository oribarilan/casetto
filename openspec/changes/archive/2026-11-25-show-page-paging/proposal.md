# Proposal

## Why

A show with a long back catalog makes its page slow to open and to scroll. Measured in the simulator, reading all 2,787 episodes of The Joe Rogan Experience from the database takes 80 to 150 ms, but the page took about 0.2 seconds longer to open and 0.65 seconds longer to settle after each scroll than a 9-episode show. The cost is drawing thousands of rows, not reading them. The listener saw the lag on the phone.

This is a backlog-style fix, not a numbered roadmap milestone.

## What Changes

- The Episodes list on a show page shows the newest 30 episodes, then a "Show older episodes" row that adds the next 30 each time it's tapped.
- The folded Played list does the same when it's open. Its count still counts every played episode.
- The page still reads every episode, which is fast, so counts and actions stay right. Only the rows drawn are limited.
- Each visit starts again at 30.

## Out of scope

- The Queue and the Inbox, which stay short.
- Loading older episodes automatically as you scroll. A row you tap is simpler and says what happens.
- The Follow lag on huge feeds, which is its own backlog item.
- The new-episode settings lag, also its own backlog item.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `show-page`: a new requirement for long episode lists.

## Impact

- `Casterr/Screens/ShowView.swift`: the limit, the "Show older episodes" rows, and splitting played from unplayed once per draw instead of filtering twice.
- `CasterrUITests/ScreensTests.swift`: a check that a long show ends with "Show older episodes".
- `CHANGELOG.md` and `project.yml`: version 0.4, since the page gains a new row.
