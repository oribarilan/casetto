# Spec Delta

## MODIFIED Requirements

### Requirement: Refresh feeds
The system SHALL refresh all subscribed feeds when the app comes to the foreground, when the listener pulls to refresh, and in the background when iOS allows it. A refresh MUST NOT block playback or the user interface, and a feed that fails MUST NOT stop the others.

#### Scenario: New episode published
- **WHEN** a subscribed feed has a new episode and the app comes to the foreground
- **THEN** the new episode appears on the show page

#### Scenario: One feed fails
- **WHEN** one subscribed feed returns an error during a refresh
- **THEN** the other feeds still refresh and the failing show displays when it last refreshed successfully

#### Scenario: Background refresh
- **WHEN** iOS runs a background refresh and an Auto-queue show has a new episode
- **THEN** the episode is added to the Queue and, if it is within the download setting and the phone is on Wi-Fi, its download starts
