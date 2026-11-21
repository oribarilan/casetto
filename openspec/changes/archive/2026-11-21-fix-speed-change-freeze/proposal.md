# Proposal

## Why

Changing speed sometimes freezes playback. Apple's player keeps saying it's playing, and audio keeps flowing, but its clock stops. The elapsed time, saved progress, and the sleep timer's end-of-episode check all stall, for 20 seconds or more. The smoke test's speed step failed in about 1 run of 4. A helper traced it to Back a Beat's audio tap, which sits before the speed change. With the tap after the speed change, the step passed in 28 of 28 runs.

This isn't a roadmap milestone. It fixes Back a Beat (added after M1) and the speed control from M1.

## What Changes

- The audio tap that measures loudness for Back a Beat moves after the speed change.
- It's told the playback speed, so its readings stay in episode time and Back a Beat finds the same gaps at every speed.
- The Playback speed requirement gets a scenario saying playback keeps advancing after a speed change.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `playback`: Playback speed adds the scenario that playback keeps advancing after a speed change.

## Out of scope

- Voice boost. It's parked, and it can come back on top of this fix later.
- Finding why Apple's player freezes with a tap before the speed change. Moving the tap avoids it.

## Impact

- App: `LoudnessTap` (tap position and speed-aware times) and `AVPlayerEngine` (passes the speed to the tap). No CasterrCore change.
- **Risk:** the tap now hears sped-up audio. Back a Beat at 2x hasn't been checked by ear. The task checks its readings at 1x and 2x in the simulator, and a phone check covers listening.
