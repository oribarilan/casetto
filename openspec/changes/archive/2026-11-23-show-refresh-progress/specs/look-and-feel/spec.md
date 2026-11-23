## ADDED Requirements

### Requirement: Refresh progress on the Queue
While shows refresh, the Queue SHALL show a thin tangerine line under its title that fills as each show is checked, fills to the end when the refresh finishes, and then fades out. The line MUST NOT move the list, and it MUST show whether the refresh came from a pull or from opening the app. VoiceOver SHALL read it as "Checking for new episodes" with how much is done.

#### Scenario: Refresh on opening the app
- **WHEN** the listener opens the app and 2 of 4 shows have been checked
- **THEN** the line under the Queue's title is half filled and the episodes have not moved

#### Scenario: Refresh ends
- **WHEN** the last show has been checked
- **THEN** the line fills to the end and fades out, and Cassy's summary toast shows if anything moved
