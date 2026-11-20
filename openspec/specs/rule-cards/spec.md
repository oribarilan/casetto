# rule-cards Specification

## Purpose
Notices how the listener treats a show and offers a one-tap change to its level.

## Requirements

### Requirement: Auto-queue card
The system SHALL offer to set an Inbox-level show to Auto-queue when the listener started each of the show's last 4 episodes released more than a day ago within a day of its release. Accepting MUST set the show's level to Auto-queue.

#### Scenario: Listener always plays the show quickly
- **WHEN** an Inbox-level show's last 4 episodes released more than a day ago were each started within a day of release
- **THEN** the Inbox shows a card offering to auto-queue the show

#### Scenario: One episode played late
- **WHEN** one of those 4 episodes was started two days after release
- **THEN** the Inbox shows no Auto-queue card for the show

#### Scenario: Accept
- **WHEN** the listener accepts the Auto-queue card
- **THEN** the show's level is Auto-queue and the card is gone

### Requirement: Ignored card
The system SHALL offer to skip or unsubscribe from an Inbox-level show when its last 3 episodes expired unplayed. Skip MUST set the show's level to Skip. Unsubscribe MUST unsubscribe from the show.

#### Scenario: Show ignored
- **WHEN** an Inbox-level show's 3 newest episodes are in the archive with the reason "expired"
- **THEN** the Inbox shows a card offering Skip and Unsubscribe

#### Scenario: Skip
- **WHEN** the listener taps Skip on the card
- **THEN** the show's level is Skip and the card is gone

### Requirement: Hide a card
Every card SHALL offer Not now and Never. Not now MUST hide that card for that show for 30 days. Never MUST hide that card for that show for good. A card that is hidden or no longer applies MUST NOT show.

#### Scenario: Not now
- **WHEN** the listener taps Not now on a card
- **THEN** the card is gone and returns after 30 days only if its condition still holds

#### Scenario: Never
- **WHEN** the listener taps Never on a show's Ignored card
- **THEN** that show never shows the Ignored card again

### Requirement: Cards live in the Inbox
Cards SHALL show at the top of the Inbox, above its episodes.

#### Scenario: Card with an empty Inbox
- **WHEN** a card applies and the Inbox holds no episodes
- **THEN** the Queue screen shows "New (1)" and the Inbox shows the card
