# Tasks

## 1. Core

- [x] 1.1 Add `Loudness` and `BackABeat.resumePoint(pausedAt:readings:)`, with tests: a gap, the latest of two gaps, no gap, a gap too short, a loud and a quiet show, no readings, and a pause near 0:00
- [x] 1.2 Add `loudness(from:to:)` to `AudioEngine` and the test fake; make `Player` record the pause point and resume at the found gap; tests for resume, seek while paused, skip while paused, a new episode, and the sleep timer

## 2. App

- [x] 2.1 Attach the PreEffects mix tap in `AVPlayerEngine` and log readings; confirm in the simulator that a downloaded file and a streamed MP3 both produce readings, and note the result for a streamed M4A
- [x] 2.2 Keep the 8-second ring, drop readings after a backward jump, and implement `loudness(from:to:)`; build with strict concurrency and no warnings
- [x] 2.3 Tune the gap constants on three real episodes (solo talk, interview, music under voices) by logging the chosen resume points in the simulator
- [x] 2.4 Run all core and UI tests; add Back a Beat to the Player section of `podcast_app_concept.md`; add the listening check to `openspec/device-checks.md`
