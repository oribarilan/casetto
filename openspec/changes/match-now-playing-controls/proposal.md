## Why

The three controls under Now Playing's play button don't look or work alike. Speed opens a sheet, while voice boost and the sleep timer open menus. The speed sheet also misleads: its slider shows only after "Use my default" is turned off, so the listener has to flip a switch before they can change the speed. And the sleep timer can't stop at the end of a chapter.

The listener picked design 2, Matching sheets, and dropped the footer text under the switch.

## What Changes

- Speed, voice boost and the sleep timer each open a small sheet of the same shape: the name and current value on top, the control, and for speed and voice boost a "Use my default" switch. There is no footer text.
- **Speed:** the slider is always there. Moving it turns "Use my default" off by itself. Turning the switch on moves the slider back to the default. At the default speed, the switch can be turned off, which keeps the default speed as the show's own.
- **Voice boost:** the menu becomes a sheet with On and Off and the same "Use my default" switch. Picking On or Off turns the switch off.
- **Sleep timer:** the menu becomes a sheet of choices: 15, 30, 45 and 60 minutes, "This chapter" with the time left in the chapter, and "End of episode" with the time left. "This chapter" shows only when the episode has chapters. A running timer's choice is marked, and a Turn Off button shows.
- **New:** the sleep timer can pause at the end of the current chapter. While that timer runs, the button shows "Chapter", as it shows "End" for the end of the episode.

Calls made while writing this, open to correction: the sleep timer has no "Use my default", because Settings has no default for it. Turn Off is a button under the choices. The chapter timer's button says "Chapter" instead of counting down.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `playback`: the three control sheets, speed's always-there slider, voice boost as a sheet, and the chapter sleep timer.

## Impact

- `NowPlayingView.swift`: `SpeedSheet`, `VoiceBoostMenu` and `SleepTimerMenu` become three sheets built on one shared layout.
- `Player.swift` in CasterrCore: a chapter sleep timer that pauses when the next chapter starts.
- UI tests: `SmokeTests` (speed and voice boost) and `ScreensTests` (sleep timer).
