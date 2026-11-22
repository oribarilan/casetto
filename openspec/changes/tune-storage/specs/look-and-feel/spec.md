## MODIFIED Requirements

### Requirement: Show art on the device
Show art SHALL be kept on the device once loaded and shown from there without asking the server again, wherever it appears. It MUST show offline once it has loaded before. While art downloads, its square MUST show a soft grey shimmer, still grey with Reduce Motion, and fade into the art. Art already on the device MUST appear with no shimmer. A show with no art, or art that fails to load, MUST show the tangerine square with its first letter.

#### Scenario: Offline grid
- **WHEN** the listener follows shows whose art has loaded, then opens the Shows tab offline
- **THEN** every show's art appears

#### Scenario: No reload
- **WHEN** the listener scrolls the Shows grid away and back
- **THEN** the art appears at once, with no letter placeholder in between

#### Scenario: First download
- **WHEN** Find Shows lists a show whose art isn't on the device yet
- **THEN** its square shimmers grey until the art arrives, then fades into it

#### Scenario: No art
- **WHEN** a show's feed has no art
- **THEN** its square is tangerine with the show's first letter
