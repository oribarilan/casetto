## MODIFIED Requirements

### Requirement: Clip editor
"Share Clip" in Now Playing SHALL open an editor that shows the two minutes around the current time as loudness bars, with a clip framed from 15 seconds before now to 15 seconds after, kept within the episode. The listener MUST be able to drag either edge, for a clip of 5 to 60 seconds, and preview it at normal speed, as it will be sent. Previewing MUST pause the episode.

#### Scenario: Opens around now
- **WHEN** the listener opens the editor at 12:19
- **THEN** the bars span 11:19 to 13:19 and the clip is 12:04 to 12:34

#### Scenario: Near the start
- **WHEN** the listener opens the editor at 0:05
- **THEN** the clip starts at 0:00 and runs 30 seconds

#### Scenario: Limits
- **WHEN** the listener drags an edge to make the clip 75 seconds
- **THEN** the clip stops at 60 seconds
