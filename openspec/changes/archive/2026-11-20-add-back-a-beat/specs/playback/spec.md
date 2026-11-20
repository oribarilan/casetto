## ADDED Requirements

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

## MODIFIED Requirements

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
