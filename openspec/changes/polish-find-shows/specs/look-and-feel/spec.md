## ADDED Requirements

### Requirement: Show art on the device
Show art SHALL be kept on the device once loaded and shown from there without asking the server again, wherever it appears. It MUST show offline once it has loaded before.

#### Scenario: Offline grid
- **WHEN** the listener follows shows whose art has loaded, then opens the Shows tab offline
- **THEN** every show's art appears

#### Scenario: No reload
- **WHEN** the listener scrolls the Shows grid away and back
- **THEN** the art appears at once, with no letter placeholder in between
