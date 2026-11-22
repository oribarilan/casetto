## Why

Idle Cassy waits 2 to 5 seconds before her first loop and 8 to 15 seconds between loops, so she sits frozen about 85% of the time. On the welcome screen she looks broken rather than alive. The listener wants her moving most of the time, with very little stillness between loops.

## What Changes

- Idle Cassy waits 0.7 to 1.2 seconds before her first loop and between loops, one range for both. With loops of 0.35 to 3.2 seconds, she moves most of the time.
- The loops themselves, their order rules, and Reduce Motion stay as they are.
- It applies everywhere idle Cassy appears: the welcome screen, the Queue's empty state when the Inbox has episodes, Discover's "Let's add some shows!" card, and the Inbox rule card. Her other moods already move all the time.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `look-and-feel`: the Idle loops requirement gets the shorter pause.

## Impact

`CassyAnimation.pause` and `firstPause` in CasterrCore become one range, `CassyView.playIdleLoops` uses it, and the timing test changes. Her canvas now redraws at 30 frames a second most of the time while she's on screen, which costs a little battery on those four screens.
