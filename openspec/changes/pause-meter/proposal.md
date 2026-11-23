## Why

The listener wanted a waveform animation in the mini player, turned down a first set of nine ideas, and proposed their own: fill the pause icon's two existing bars with color as the voice plays. A trial on the phone went through three rounds: too jumpy at 30 updates a second, better with quarter-second averages and a glide, and best with an ease-out glide and the right bar lagging a tenth of a second. The listener approved that version.

This is not a roadmap milestone. It is polish from daily use after the MVP.

## What Changes

- While an episode plays, the mini player's pause icon keeps its shape, and each of its two bars fills with tangerine from the bottom as loud as the voice is: the left bar over the last quarter second, the right bar over the same span a tenth of a second earlier, so the two ripple instead of moving as one.
- Loudness is measured against the loudest moment of the last 3 seconds, from the readings the audio tap already keeps, so quiet and loud shows both use the full height.
- The fill updates about ten times a second and eases out (fast start, slow finish) over a quarter second.
- Paused, the icon is the play triangle as today. With Reduce Motion, it's the plain pause icon. VoiceOver reads it as Pause or Play.

Out of scope: Now Playing's pause button and the clip video (the clip waveform stays in the backlog).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `look-and-feel`: a new requirement for the mini player's pause meter.

## Impact

- `Player.levels()` gives the two levels from the engine's loudness readings. Core tests.
- `RootView.swift`: `PauseMeter` draws the bars in the mini player's play button.
