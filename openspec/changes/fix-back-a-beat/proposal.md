## Why

Back a Beat works most of the time, but sometimes playback resumes where it paused, and once in a while it seems to land later. An investigation with 25 new tests (12 of them failing on today's code) found why:

1. A pause that lands inside a pause between phrases finds that same gap and resumes in it, so nothing is heard again.
2. Readings are cut to the 2 to 5 second window before gaps are found, so a gap that crosses an edge is trimmed and dropped as too short.
3. "Quiet" is judged against the stretch's median, so when pauses fill more than half of it (a slow speaker, or long silence), nothing counts as quiet.
4. A second pause (headphones unplugged, the sleep timer, the clip preview) turns Back a Beat back on after the listener moved the position while paused.
5. A position report that arrives after the pause can move the pause point, and one missing 10 ms reading splits a gap.

Landing later is not explained by the gap logic, which a test shows never picks a later point. The likely cause is the seek: it uses the default tolerance, which on some MP3 files can land seconds away while reporting the target. That part is not confirmed and needs the real iPhone.

The listener asked that a pause inside a gap still goes back to an earlier gap a few seconds before.

This is not a roadmap milestone. It is a fix from daily use after the MVP.

## What Changes

- The window is measured from where the speech stopped: the pause point, or the start of the quiet run the pause fell in. Playback then goes back to an earlier gap, never the one it paused in.
- Gaps are found across the whole stretch first. Any gap that reaches into the window counts, and playback resumes at its middle, or at the nearest point of it inside the window, so it always lands in the silence.
- Quiet is judged against the louder parts of the stretch (about the 90th percentile of loudness), so slow speech and long silences still have gaps.
- The pause point is remembered once, when playing audio actually pauses, and cleared by any seek, skip or new episode. A second pause while paused changes nothing, and late position reports can't move it.
- One missing reading inside a gap doesn't split it.
- Back a Beat's resume seek is exact, and downloaded files open with precise timing.
- The window stays 2 to 5 seconds of media time at every speed.

Out of scope: scaling the window with speed, a setting, and changing the minimum gap length.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `playback`: Back a Beat measures from where speech stopped, counts any gap reaching into the window, judges quiet against the louder parts, and ignores a second pause.

## Impact

- `CasterrCore/Sources/CasterrCore/Player/BackABeat.swift` and `QuietGaps.swift`: the anchor, finding gaps before choosing, the percentile reference, and a looser contiguity limit.
- `Player.swift`: `pausedInPlace` becomes `pausePoint: TimeInterval?`; `backABeat()` uses it.
- `AudioEngine` gains an exact seek for Back a Beat; `AVPlayerEngine` opens local files with precise timing. The app's audio tap keeps 15 s of readings instead of 8.
- Tests: the 25 tests from the investigation (`BackABeatEdgeTests`, 3 in `QuietGapsTests`, 5 in `BackABeatPlayerTests`) become the core of this change.
- `openspec/device-checks.md`: a check for landing after resume on a streamed MP3 and at 2x.
