## Why

After a force quit, the app opens with nothing loaded in the player, so the bottom bar is the up-next bar, not the mini player: "Continue · N min left", no bookmark button, and a tap opens the Queue instead of Now Playing. Pressing play loads the episode and the real mini player comes back. The listener expects the episode they were in the middle of to look and act the same as before the force quit (backlog: "Mini player after relaunch"). The listener picked option A: restore it, paused.

The listener also wants the bookmark button off the mini player. Bookmarking stays one tap in Now Playing.

This is not a roadmap milestone. It is polish from daily use after the MVP.

## What Changes

- Whenever nothing is loaded and the first Queue episode has progress, the player loads it, paused, at its saved position. The bottom bar is then the mini player: tapping it opens Now Playing, and play resumes. This happens when the app opens, and if the loaded episode leaves the Queue while the next one was already started.
- Loading an episode this way doesn't count as playing it: the Auto-queue card's "first played" date and Back a Beat are untouched.
- The up-next bar shows only for an episode that was never started, and says "Up next · from your Queue". Its "Continue · N min left" form goes away, because a started episode is always loaded.
- **BREAKING:** the mini player loses its bookmark button. It keeps the art, titles, and play or pause.

Out of scope: restoring a speed, timer, or anything else beyond the episode and its position, and showing the up-next bar for an empty Queue.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `queue`: the up-next bar is for an unstarted episode only; a started first episode is loaded paused.
- `capture`: bookmarking is one tap in Now Playing; the mini player no longer has the button.

## Impact

- `Player.swift`: `load(_:)` loads an episode paused at its saved position, sharing setup with starting playback, without recording a play start. Core tests.
- `AppModel.swift`: after loading the up-next episode, load it into the player when nothing is loaded and it has progress. `UpNext.caption` loses its "Continue" form.
- `RootView.swift`: `MiniPlayer` drops `BookmarkButton`.
- `podcast_app_concept.md`: the mini player sentence in Capture.
- `BACKLOG.md`: the "Mini player after relaunch" entry is removed.
