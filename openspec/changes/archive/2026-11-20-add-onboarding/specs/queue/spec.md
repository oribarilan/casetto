# Spec Delta

## MODIFIED Requirements

### Requirement: Queue is the home screen
The system SHALL show the Queue as the home screen, in the first of the app's tabs. The first item in the Queue SHALL be the Now Playing episode.

#### Scenario: Open the app with a non-empty Queue
- **WHEN** the listener opens the app and the Queue has 5 episodes
- **THEN** the Queue tab is selected and lists the 5 episodes in order with the first shown as Now Playing

#### Scenario: Open the app with an empty Queue
- **WHEN** the Queue is empty
- **THEN** the home screen tells the listener that nothing is queued and links to the Shows tab
