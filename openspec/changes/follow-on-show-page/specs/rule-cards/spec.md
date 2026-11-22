## MODIFIED Requirements

### Requirement: Ignored card
The system SHALL offer to skip or unfollow an Inbox-level show when its last 3 episodes expired unplayed. Skip MUST set the show's level to Skip. Unfollow MUST unfollow the show.

#### Scenario: Show ignored
- **WHEN** an Inbox-level show's 3 newest episodes are in the archive with the reason "expired"
- **THEN** the Inbox shows a card offering Skip and Unfollow

#### Scenario: Skip
- **WHEN** the listener taps Skip on the card
- **THEN** the show's level is Skip and the card is gone
