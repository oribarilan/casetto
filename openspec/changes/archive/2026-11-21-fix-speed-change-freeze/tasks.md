# Tasks

## 1. Fix

- [x] 1.1 Create the loudness tap after the speed change (PostEffects) and pass the playback speed to it, so each reading's time is episode time at any speed; verify the smoke test passes 10 runs in a row and the debug log shows about 300 Back a Beat readings for a 3-second stretch at 1x and at 2x
- [x] 1.2 Run all core and UI tests; add Back a Beat at 2x and dragging the speed while playing to `openspec/device-checks.md`

## Workflow follow-up

- Archive the change after the listener approves the result, then run `openspec validate --specs --strict`.
