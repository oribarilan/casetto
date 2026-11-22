## Why

Sometimes a drag on the Now Playing slider doesn't take. The time label shows where the thumb stopped, but the episode keeps playing from the old spot, and pausing saves the old spot as progress. The clip editor UI test hits it about one run in three: the label showed 48:00, the editor opened at 0:03.

The cause: the slider seeks only when the drag reports its end, and SwiftUI's `Slider` sometimes reports the start and the moves but never the end. Logging showed exactly that in every failing run, and no seek was sent. Every seek that was sent landed immediately, even on a streamed episode.

## What Changes

- The Now Playing slider seeks as the thumb moves, instead of waiting for the drag to end. The separate scrubbing state goes away.
- While a seek is still landing, the engine reports the seek's target time instead of AVPlayer's current time, so the thumb doesn't jump back between the seeks of a drag, and a pause in that moment saves the target.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `playback`: Saved progress gets a rule and a scenario for dragging the slider and pausing right away.

## Impact

`Casterr/Screens/NowPlayingView.swift` (the scrubber) and `Casterr/Playback/AVPlayerEngine.swift` (a remembered seek target, cleared in the seek's completion handler unless a newer seek replaced it). The clip editor UI test's retry loop for a lost first drag goes.
