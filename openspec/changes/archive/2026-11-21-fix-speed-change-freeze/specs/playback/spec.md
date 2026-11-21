## MODIFIED Requirements

### Requirement: Playback speed
The system SHALL let the listener set playback speed from 1x to 2x in steps of 0.1x. Speech MUST keep its natural pitch at every speed.

#### Scenario: Change speed
- **WHEN** the listener sets speed to 1.5x
- **THEN** the episode plays 1.5 times faster and voices keep their natural pitch

#### Scenario: Speed changes while playing
- **WHEN** the listener drags the speed from 1.0x to 2.0x while an episode plays
- **THEN** the elapsed time keeps advancing at the new speed, with no freeze
