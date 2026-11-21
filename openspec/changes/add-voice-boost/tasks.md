# Tasks

Parked in the backlog (2026-11-21). The code for tasks 1.1 to 3.2 is saved in `parked.patch` next to this file (apply it with `git apply`); the app code is back at the previous commit. Blocker: with Apple's dynamics processor set up inside the audio tap, a speed change freezes the player's clock while audio keeps flowing. The smoke test's 2x step failed in about 1 run of 4 with boost off and on the first run with boost on, and never without the unit (8 of 8 passed). The next step would be our own leveler in place of the audio unit, tested against the same speed changes.

## 1. Core

- [x] 1.1 Add `UserSettings.voiceBoost` (default false) and `Subscription.voiceBoostOverride` (optional), and the `Library` methods `globalVoiceBoost`, `setGlobalVoiceBoost`, `voiceBoostOverride`, `setVoiceBoostOverride`, and `effectiveVoiceBoost(for:)`; verify with storage tests for the default, a show with its own choice, a default change, and removing a show's choice
- [x] 1.2 Add `setVoiceBoost(_:)` to `AudioEngine` and `FakeEngine`; give `Player` a `voiceBoost` value set when an episode starts and `reloadVoiceBoost()`; verify with player tests: a new episode gets its show's effective choice, a reload after a change reaches the engine while playing, and another show's episode gets its own choice

## 2. App audio

- [x] 2.1 Rename `LoudnessTap` to `AudioTap` and the logger category to "audioTap"; verify the build has no warnings and the Back a Beat core and UI tests still pass
- [ ] 2.2 Set up the dynamics processor in the tap's prepare callback with the approved values, tear it down in unprepare, and render it in process after measuring loudness, behind an `Atomic<Bool>` flag that resets the unit when it turns on; the engine remembers the flag for new items; verify in the simulator that the debug log shows a nonzero compression amount with boost on, for a downloaded episode and a streamed MP3, and that an unsupported format logs that it plays unboosted

## 3. App screens

- [x] 3.1 Add `VoiceBoostMenu` to Now Playing next to speed, with the title, the three items, the checkmark, the white button, and the VoiceOver label and value; verify with a UI test that choosing "On for this show" turns the button white and "Use my default (Off)" turns it back
- [x] 3.2 Add the Voice boost toggle under Default speed in Settings and update the Playback footer; verify with a UI test that turning it on makes the Now Playing button white for a show with no choice of its own
- [ ] 3.3 Run all core and UI tests; add a Voice boost bullet to the Player section of `podcast_app_concept.md`, remove voice boost from the "After the MVP" list, and add a listening check to `openspec/device-checks.md` (a quiet-caller show with boost off and on, switching while playing, a streamed episode, and Back a Beat with boost on)

## Workflow follow-up

- Archive the change after the listener approves the result, then run `openspec validate --specs --strict`.
