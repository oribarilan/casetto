## MODIFIED Requirements

### Requirement: Back a Beat
When the listener plays again after pausing, the system SHALL resume inside the latest quiet gap reaching into 2 s to 5 s before where speech stopped: the pause point, or where the quiet it fell in began. Quiet MUST be judged against the stretch's louder parts. With no gap or no audio, it MUST resume at the pause point, never before 0:00. It SHALL NOT apply after a seek or skip while paused, a second pause, or a new episode. It SHALL work for downloaded and streamed episodes.

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

#### Scenario: Pause inside a gap
- **WHEN** the speaker stops at 23:07.4, the listener pauses at 23:10 during the silence, and the audio is quiet from 23:04.9 to 23:05.1
- **THEN** pressing play resumes at that earlier gap, about 23:05, not in the silence they paused in

#### Scenario: Gap across the window edge
- **WHEN** the listener pauses at 23:10 and the audio is quiet from 23:07.9 to 23:08.1
- **THEN** pressing play resumes at that gap, because its middle is 2 s before the pause

#### Scenario: Slow speaker
- **WHEN** pauses between words fill most of the stretch before the pause point
- **THEN** pressing play still resumes at the latest of those gaps

#### Scenario: Second pause after a seek
- **WHEN** the listener pauses, moves the position to 30:00, unplugs the headphones, and presses play
- **THEN** playback resumes at 30:00
