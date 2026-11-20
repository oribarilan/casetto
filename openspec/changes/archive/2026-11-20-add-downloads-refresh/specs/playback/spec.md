# Spec Delta

## MODIFIED Requirements

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
