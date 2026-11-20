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
- **WHEN** the listener opens speed in Now Playing, turns off "Use my default", and drags the slider to 1.3x
- **THEN** the episode plays at 1.3x right away, with no Done button, and other shows keep the default

#### Scenario: Follow the default again
- **WHEN** the listener turns "Use my default" back on
- **THEN** the show's override is reset, the slider hides, and the episode plays at the default speed

### Requirement: Sleep timer
The system SHALL let the listener set a sleep timer for a fixed duration or for the end of the current episode. When the timer ends, playback MUST pause. While a timer runs, the sleep timer button in Now Playing SHALL show the time left, or "End" for the end of the episode.

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

## ADDED Requirements

### Requirement: Show name opens the show page
Tapping the show name in Now Playing SHALL close Now Playing and open that show's page in the Shows tab.

#### Scenario: Open the show
- **WHEN** the listener taps "Pocket Economics" in Now Playing
- **THEN** Now Playing closes and the Shows tab shows the Pocket Economics page
