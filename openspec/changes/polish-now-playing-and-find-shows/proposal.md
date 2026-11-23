## Why

Three small things the listener found on the phone. The Now Playing sheet has no grab handle, so nothing shows it can be swiped away. "Share Clip…" has three dots that the listener doesn't want. And Cassy's card in Find Shows says "Nice pick!" whenever any followed show is starred, so after the first star ever it always cheers, even on a visit where the listener did nothing.

## What Changes

- Now Playing shows the standard iOS grab handle at its top.
- The Now Playing share menu says "Share Clip", without the three dots.
- Cassy's card in Find Shows cheers only for a star given during the current visit. A star given before the visit doesn't count, and taking back this visit's star brings the invitation back.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `look-and-feel`: Now Playing shows a grab handle.
- `sharing`: the menu item is "Share Clip".
- `discovery`: the Find Shows card cheers only for a star given during this visit.

## Impact

`RootView.swift` (the Now Playing sheet), `NowPlayingView.swift` (the menu label), `DiscoverView.swift` (the card), and the UI tests that tap "Share Clip…".
