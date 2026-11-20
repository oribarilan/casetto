# playback Specification

## Purpose
Plays podcast audio reliably: streaming from the publisher, in the background, with system controls, adjustable speed, skip intervals, a sleep timer, and progress that is never lost.

## Requirements

### Requirement: Stream episode audio
The system SHALL play a downloaded episode from its file on the phone. The system SHALL play any other episode by streaming its audio URL from the publisher. Streaming MUST start without downloading the whole file first.

#### Scenario: Play a streamed episode
- **WHEN** the listener plays an episode that isn't downloaded while online
- **THEN** audio starts playing from the episode's saved position

#### Scenario: Play a downloaded episode offline
- **WHEN** the listener plays a downloaded episode and the device has no network connection
- **THEN** audio starts playing from the episode's saved position

#### Scenario: Offline
- **WHEN** the listener plays an episode that isn't downloaded and the device has no network connection
- **THEN** the system tells the listener that the episode cannot be streamed offline

#### Scenario: Audio URL fails
- **WHEN** the audio URL returns an error
- **THEN** playback stops, the system tells the listener that the episode could not be played, and the Queue is unchanged

### Requirement: Background audio and interruptions
Playback SHALL continue when the app is in the background or the device is locked. The system MUST pause for interruptions such as phone calls and resume when the interruption ends, if the system allows it.

#### Scenario: Lock the phone
- **WHEN** the listener locks the device during playback
- **THEN** audio keeps playing

#### Scenario: Phone call
- **WHEN** a phone call interrupts playback and then ends
- **THEN** playback pauses during the call and resumes afterward when the system indicates that it should resume

#### Scenario: Headphones unplugged
- **WHEN** the audio route changes because headphones are disconnected
- **THEN** playback pauses

### Requirement: System playback controls
The system SHALL show the Now Playing episode on the lock screen and in Control Center with its title, show, artwork, elapsed time, and duration. The system SHALL respond to play, pause, skip forward, skip back, and seek commands from those controls and from headphones.

#### Scenario: Lock screen controls
- **WHEN** the listener taps skip forward on the lock screen
- **THEN** playback jumps forward 30 seconds

#### Scenario: Seek from Control Center
- **WHEN** the listener drags the progress bar in Control Center
- **THEN** playback continues from the chosen position

### Requirement: Playback speed
The system SHALL let the listener set playback speed from 1x to 2x in steps of 0.1x. Speech MUST keep its natural pitch at every speed.

#### Scenario: Change speed
- **WHEN** the listener sets speed to 1.5x
- **THEN** the episode plays 1.5 times faster and voices keep their natural pitch

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

### Requirement: Skip intervals
The system SHALL provide skip forward by 30 seconds and skip back by 15 seconds. The intervals are the same in the app, on the lock screen, and from headphones, and they are not configurable.

#### Scenario: Skip back
- **WHEN** the listener taps skip back
- **THEN** playback moves 15 seconds earlier, or to the start if less than 15 seconds have played

#### Scenario: Skip forward near the end
- **WHEN** the listener taps skip forward with less than 30 seconds remaining
- **THEN** playback moves to the end of the episode

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

### Requirement: Saved progress
The system SHALL save each episode's playback position so that playback resumes where the listener stopped, or up to 5 seconds before it when Back a Beat finds a quiet gap. A crash or force quit MUST lose no more than a few seconds of progress.

#### Scenario: Resume after pause
- **WHEN** the listener pauses an episode at 23:10 and plays it again later
- **THEN** playback resumes at 23:10, or at a quiet gap between 23:05 and 23:08

#### Scenario: App terminated during playback
- **WHEN** the app is terminated while playing at 41:00
- **THEN** the next time the episode plays, it resumes within a few seconds of 41:00

#### Scenario: Switch episodes
- **WHEN** the listener plays a different episode while one is partly played
- **THEN** the first episode keeps its position for later

### Requirement: Show name opens the show page
Tapping the show name in Now Playing SHALL close Now Playing and open that show's page in the Shows tab.

#### Scenario: Open the show
- **WHEN** the listener taps "Pocket Economics" in Now Playing
- **THEN** Now Playing closes and the Shows tab shows the Pocket Economics page

### Requirement: Back a Beat
When the listener plays an episode again after pausing it, the system SHALL resume at the latest quiet gap between 5 s and 2 s before the pause point, judged against that stretch's own loudness. With no quiet gap, or no audio for that stretch, playback MUST resume at the pause point, and never before 0:00. It SHALL NOT apply after a seek or skip while paused, or to a newly started episode. It SHALL work for downloaded and streamed episodes, with no setting.

#### Scenario: Resume at a gap
- **WHEN** the listener pauses at 23:10 and the audio is quiet from 23:06.9 to 23:07.1
- **THEN** pressing play resumes at that gap, about 23:07

#### Scenario: Latest gap wins
- **WHEN** the stretch from 23:05 to 23:08 has quiet gaps at 23:05.5 and 23:07.4
- **THEN** pressing play resumes at the 23:07.4 gap

#### Scenario: No quiet gap
- **WHEN** music plays under the voices and nothing from 23:05 to 23:08 is quiet enough
- **THEN** pressing play resumes at 23:10

#### Scenario: Interruption
- **WHEN** a phone call pauses playback and the system resumes it afterward
- **THEN** playback resumes at the latest quiet gap before the pause point

#### Scenario: Seek while paused
- **WHEN** the listener pauses, moves the position to 30:00, and presses play
- **THEN** playback resumes at 30:00

#### Scenario: Near the start
- **WHEN** the listener pauses 1 second into an episode
- **THEN** playback resumes at the pause point or later, never before 0:00
