## MODIFIED Requirements

### Requirement: Saved progress
The system SHALL save each episode's playback position so that playback resumes where the listener stopped, or up to 5 seconds before it when Back a Beat finds a quiet gap. A crash or force quit MUST lose no more than a few seconds of progress. After a drag on the Now Playing slider, playback and saved progress MUST continue from where the thumb stopped.

#### Scenario: Resume after pause
- **WHEN** the listener pauses an episode at 23:10 and plays it again later
- **THEN** playback resumes at 23:10, or at a quiet gap between 23:05 and 23:08

#### Scenario: App terminated during playback
- **WHEN** the app is terminated while playing at 41:00
- **THEN** the next time the episode plays, it resumes within a few seconds of 41:00

#### Scenario: Switch episodes
- **WHEN** the listener plays a different episode while one is partly played
- **THEN** the first episode keeps its position for later

#### Scenario: Pause right after dragging the slider
- **WHEN** the listener drags a streamed episode's slider from 0:05 to 48:00 and pauses right away
- **THEN** Now Playing shows 48:00, the saved progress is 48:00, and Share Clip opens around 48:00
