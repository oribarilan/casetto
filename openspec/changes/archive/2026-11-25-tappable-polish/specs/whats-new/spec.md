## MODIFIED Requirements

### Requirement: Version in Settings
Settings SHALL end with an About section showing the version and build. The row MUST show "What's New" in the accent color. Tapping it MUST open What's New with every version, newest first.

#### Scenario: Version in Settings
- **WHEN** the listener opens Settings on version 0.3
- **THEN** the last section reads "Version 0.3" with the build number and "What's New" in the accent color, and tapping it opens What's New with every version, newest first
