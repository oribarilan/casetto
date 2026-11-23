## MODIFIED Requirements

### Requirement: Show art
Episode rows in the Queue, Inbox, and show page SHALL show their show's artwork. The Shows tab SHALL show followed shows as a grid of artwork with titles. The show page SHALL open with a large artwork header. The mini player SHALL show the current show's artwork. A show without artwork MUST show a placeholder with its first letter.

#### Scenario: Shows grid
- **WHEN** the listener follows 9 shows
- **THEN** the Shows tab shows 9 artwork tiles with titles, starred shows under their own heading, and failing feeds marked with a warning

#### Scenario: No artwork
- **WHEN** a feed has no artwork
- **THEN** its rows and tile show a tangerine placeholder with the show's first letter
