## 1. Tests first

- [x] 1.1 Bring the 25 investigation tests from branch `back-a-beat-investigation` (worktree `.claude/worktrees/agent-ace05b55f79eee54f`) into `BackABeatTests.swift`, `QuietGapsTests.swift` and `PlayerTests.swift`. Verify the same 12 fail on today's code

## 2. The gap logic

- [x] 2.1 Find gaps across the readings first, then choose the latest whose middle is 2 s to 5 s before the anchor. Verify the edge tests pass
- [x] 2.2 Anchor at the start of the quiet run when the pause point is inside one. Verify the pause-inside-a-gap and silence tests pass
- [x] 2.3 Judge quiet against about the 90th percentile of the stretch, and let one missing reading pass inside a gap. Verify the slow-speaker and skipped-reading tests pass, and the existing gap tests still pass

## 3. The player

- [x] 3.1 Replace `pausedInPlace` with `pausePoint`, set only when pausing playing audio and cleared by seek, skip, start and unload; Back a Beat uses it. Verify the second-pause and late-report tests pass
- [x] 3.2 Make Back a Beat's resume seek exact and open local files with precise timing; keep 15 s of readings in the audio tap. Verify the app builds and Back a Beat still resumes in the simulator

## 4. Checks

- [x] 4.1 Run the core and UI tests
- [x] 4.2 Add a device check: pause inside a silence, on a streamed MP3 and a downloaded one, and at 2x; playback goes back to an earlier gap and never lands later

## Workflow follow-up

- Move the device check to `openspec/device-checks.md` before archiving.
