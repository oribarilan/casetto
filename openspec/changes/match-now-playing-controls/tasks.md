## 1. Chapter sleep timer

- [x] 1.1 Add a chapter sleep timer to `Player` that pauses when the next chapter starts, or at the episode's end in the last chapter, with the next Queue item not starting
- [x] 1.2 Add core tests: pausing at the next chapter, the last chapter, and a seek past the chapter's end

## 2. Sheets

- [x] 2.1 Build one shared sheet layout in `NowPlayingView.swift`: name and value on top, an optional one-line description, the control, an optional "Use my default" switch, one height for all three
- [x] 2.2 Rebuild the speed sheet on it: the slider always there, moving it turns the switch off, turning the switch on moves the slider to the default, turning it off at the default keeps the default as the show's own
- [x] 2.3 Replace the voice boost menu with its sheet: On and Off, and the switch
- [x] 2.4 Replace the sleep timer menu with its sheet: the four durations, "This chapter" when the episode has chapters, "End of episode", the running choice marked, Turn Off, and "Chapter" on the button for the chapter timer

## 3. Tests

- [x] 3.1 Update the UI tests for speed and voice boost in `SmokeTests` and for the sleep timer in `ScreensTests`; add a chapter timer check to the chapters test
- [x] 3.2 Run the core and UI tests
