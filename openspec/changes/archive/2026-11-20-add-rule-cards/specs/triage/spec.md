# Spec Delta

## MODIFIED Requirements

### Requirement: Inbox
The system SHALL show the Inbox episodes newest first. From the Inbox the listener SHALL be able to add an episode to the Queue, dismiss it to the archive with the reason "dismissed", or play it. The Queue screen SHALL show a "New (N)" row linking to the Inbox when N is at least 1, where N counts the Inbox episodes and the cards.

#### Scenario: Count on the Queue screen
- **WHEN** the Inbox holds 3 episodes and 1 card
- **THEN** the Queue screen shows "New (4)" and tapping it opens the Inbox

#### Scenario: Empty Inbox
- **WHEN** the Inbox holds no episodes and no cards
- **THEN** the Queue screen shows no "New" row

#### Scenario: Queue from the Inbox
- **WHEN** the listener adds an Inbox episode to the Queue
- **THEN** it leaves the Inbox and becomes the last Queue item

#### Scenario: Dismiss
- **WHEN** the listener dismisses an Inbox episode
- **THEN** it moves to the archive with the reason "dismissed"
