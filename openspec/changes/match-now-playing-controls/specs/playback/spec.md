## ADDED Requirements

### Requirement: Now Playing control sheets
Speed, voice boost and the sleep timer in Now Playing SHALL each open a sheet of the same shape and height: the name and current value on top, a one-line description for voice boost and the sleep timer, then the control. Speed and voice boost SHALL end with a "Use my default" switch showing the default "from Settings", with no footer text. Every change MUST apply right away, with no Done button.

#### Scenario: Same shape
- **WHEN** the listener opens the speed sheet, then the voice boost sheet, then the sleep timer sheet
- **THEN** each has its name and value on top and the same height

### Requirement: Sleep timer sheet
The sleep timer sheet SHALL offer 15, 30, 45 and 60 minutes, "This chapter" with the minutes left in the chapter, and "End of episode" with the minutes left in the episode. "This chapter" MUST show only when the episode has chapters. While a timer runs, its choice MUST be marked, the value on top MUST show the time left, and a Turn Off button MUST show. Picking a choice MUST start it, replacing any running timer, and close the sheet.

#### Scenario: No chapters
- **WHEN** the listener opens the sleep timer sheet on an episode without chapters
- **THEN** it offers the four durations and "End of episode", without "This chapter"

#### Scenario: Turn off
- **WHEN** a 30-minute timer runs and the listener taps Turn Off
- **THEN** the timer stops and the button under the play controls loses its time

## MODIFIED Requirements

### Requirement: Speed default and per-show override
Speed SHALL have a global default of 1.0x, which the listener sets in Settings. The system SHALL let the listener override speed for each show from Now Playing. A show without an override MUST follow the global default, including after the global default changes. Now Playing MUST NOT change the global default.

#### Scenario: Show without an override
- **WHEN** the global speed is 1.3x and a show has no override
- **THEN** that show's episodes play at 1.3x

#### Scenario: Show with an override
- **WHEN** a show overrides speed to 1.0x and the global speed is 1.3x
- **THEN** that show's episodes play at 1.0x

#### Scenario: Global default changes
- **WHEN** the listener changes the global speed from 1.3x to 1.5x
- **THEN** every show without an override plays at 1.5x and shows with an override are unchanged

#### Scenario: Reset an override
- **WHEN** the listener resets a show's speed override
- **THEN** that show follows the global speed again

#### Scenario: Own speed from Now Playing
- **WHEN** the listener opens speed in Now Playing and drags the slider to 1.3x
- **THEN** the episode plays at 1.3x right away, with no Done button, "Use my default" turns off by itself, and other shows keep the default

#### Scenario: Follow the default again
- **WHEN** the listener turns "Use my default" back on
- **THEN** the show's override is reset, the slider moves to the default speed, and the episode plays at it

#### Scenario: Default speed on purpose
- **WHEN** the show plays at the default 1.0x and the listener turns "Use my default" off
- **THEN** the show keeps 1.0x as its own speed, and a later change of the default doesn't move it

### Requirement: Sleep timer
The system SHALL let the listener set a sleep timer for a fixed duration, the end of the current chapter, or the end of the current episode. When the timer ends, playback MUST pause. While a timer runs, the sleep timer button in Now Playing SHALL show the time left, "Chapter" for the end of the chapter, or "End" for the end of the episode.

#### Scenario: Timer for a duration
- **WHEN** the listener sets a 15-minute sleep timer
- **THEN** playback pauses 15 minutes later

#### Scenario: End of episode
- **WHEN** the listener sets the timer to the end of the current episode
- **THEN** playback pauses when that episode ends and the next Queue item does not start

#### Scenario: Cancel
- **WHEN** the listener cancels an active sleep timer
- **THEN** playback continues without pausing

#### Scenario: Time left
- **WHEN** a 30-minute timer has run for 6 minutes
- **THEN** the sleep timer button shows 24:00 and counts down

#### Scenario: End of chapter
- **WHEN** the episode has chapters and the listener picks "This chapter" with 3 minutes left in it
- **THEN** playback pauses when the next chapter starts, and the button shows "Chapter" until then

#### Scenario: Last chapter
- **WHEN** the listener picks "This chapter" during the episode's last chapter
- **THEN** playback pauses when the episode ends, and the next Queue item does not start

#### Scenario: Seek to another chapter
- **WHEN** the chapter timer runs and the listener seeks into a later chapter
- **THEN** playback pauses at the end of the chapter it landed in

### Requirement: Voice boost in Now Playing
Now Playing SHALL show a round voice boost button with a waveform symbol, white while boost is on for the playing episode. Tapping it MUST open the voice boost sheet, with On and Off and a "Use my default" switch that shows the default. Picking On or Off MUST set the show's own choice and turn the switch off. Turning the switch on MUST remove the show's own choice. A choice applies right away, with no Done button.

#### Scenario: Turn it on for a show
- **WHEN** the default is off and the listener picks On in the sheet
- **THEN** the episode plays with voice boost right away, "Use my default" turns off, the button turns white, and other shows keep the default

#### Scenario: Follow the default again
- **WHEN** a show is set to on, the default is off, and the listener turns "Use my default" on
- **THEN** the show's own choice is removed, the boost stops, Off is picked, and the button turns back from white

#### Scenario: Menu shows the default
- **WHEN** the global default is on and the listener opens the voice boost sheet
- **THEN** the switch reads "Use my default" with "On, from Settings" under it
