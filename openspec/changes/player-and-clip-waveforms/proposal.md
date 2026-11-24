## Why

The mini player's pause meter (change `pause-meter`) worked, and the listener wants the same feel in Now Playing and in shared clips. From the mockups they picked N1 for Now Playing, the same meter on the big pause button, and W1 for clips, a classic waveform along the bottom. The backlog entry "Waveform in clips" asked for a waveform in the clip video.

This is not a roadmap milestone. It is polish from daily use after the MVP.

## What Changes

- Now Playing's pause button keeps its white circle, and its two bars fill with tangerine from the bottom as the voice plays, exactly as the mini player's do: the same levels, glide, and lag, plain with Reduce Motion, the play icon when paused.
- A shared clip video shows the clip's own waveform as rounded bars across the bottom of the full-size art, over a soft dark fade. The bars are the clip editor's loudness bars for just the clip, and they turn tangerine from left to right as the clip plays.
- The clip editor's preview shows the same waveform, all unplayed.
- The clip video is written at 15 frames a second instead of 1, so the fill moves smoothly. Only a bar's color changes between frames, so the file stays small.

Out of scope: a waveform anywhere else, and the WhatsApp and color backlog items for clips.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `look-and-feel`: the pause meter requirement covers Now Playing's pause button too.
- `sharing`: the clip video shows the clip's waveform filling as it plays.

## Impact

- `PauseMeter` moves to its own file and takes a size, so the mini player and Now Playing share it. `NowPlayingView.swift` uses it in the pause button.
- `LoudnessBars` gains a way to take the bars for just the clip from the editor's window, resampled to the clip's bar count. Core tests.
- `ClipFrame` draws the fade and the bars. The video renders two frames once, all unplayed and all played, and each video frame draws the played part of the second over the first, so no frame is laid out from scratch.
- `ClipVideo.make` writes 15 frames a second.
- `BACKLOG.md`: the "Waveform in clips" entry is removed.
