## ADDED Requirements

### Requirement: Pause meter in the mini player
While an episode plays, the mini player's pause icon SHALL keep its shape and fill each bar with tangerine from the bottom as loud as the voice is: the left bar over the last quarter second, the right one a tenth of a second later, against the loudest moment of the last 3 seconds. The fill MUST glide, easing out. With Reduce Motion it MUST be the plain pause icon; paused, the play icon.

#### Scenario: Speaking
- **WHEN** the host speaks a loud sentence
- **THEN** both bars fill most of the way, the right one following the left by a tenth of a second

#### Scenario: Pause between phrases
- **WHEN** the voice stops between phrases
- **THEN** the fill sinks back and the icon looks like the plain pause icon

#### Scenario: Reduce Motion
- **WHEN** Reduce Motion is on and an episode plays
- **THEN** the mini player shows the plain pause icon with no fill
