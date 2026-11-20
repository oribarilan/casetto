# Spec Delta

## MODIFIED Requirements

### Requirement: Inbox
The system SHALL show the Inbox episodes newest first. From the Inbox the listener SHALL be able to add an episode to the Queue by swiping right, remove it by swiping left (to the archive with the reason "dismissed"), or play it. The Queue screen SHALL show an "Inbox · N new" row linking to the Inbox when N is at least 1, where N counts the Inbox episodes and the cards. Under its episodes the Inbox SHALL say how long unplayed episodes wait, and that line MUST open Settings at the Inbox section. A row SHALL say when its episode will be removed only in the episode's last 3 days. The first Inbox visit SHALL show a one-time tip that teaches the swipes.

#### Scenario: Count on the Queue screen
- **WHEN** the Inbox holds 3 episodes and 1 card
- **THEN** the Queue screen shows "Inbox · 4 new" and tapping it opens the Inbox

#### Scenario: Empty Inbox
- **WHEN** the Inbox holds no episodes and no cards
- **THEN** the Queue screen shows no Inbox row

#### Scenario: Queue from the Inbox
- **WHEN** the listener adds an Inbox episode to the Queue
- **THEN** it leaves the Inbox and becomes the last Queue item

#### Scenario: Dismiss
- **WHEN** the listener swipes an Inbox episode left and taps Remove
- **THEN** it moves to the archive with the reason "dismissed" and its show page caption reads "Removed"

#### Scenario: Expiry line
- **WHEN** the global period is 14 days
- **THEN** the Inbox says "Unplayed episodes are removed after 14 days ›" and tapping it opens Settings at the Inbox section

#### Scenario: Countdown
- **WHEN** an Inbox episode has 2 days left and another has 10
- **THEN** the first row ends with "removed in 2 days" and the second shows no countdown

#### Scenario: First visit
- **WHEN** the listener opens the Inbox for the first time
- **THEN** a tip on the first row says "Swipe right to queue an episode, or left to remove it."

### Requirement: Inbox expiry
An Inbox episode untouched for its expiry period SHALL move to the archive with the reason "expired". The period SHALL be a global setting of 14 days by default, with options of 1, 3, 7, 14, or 30 days or never. Each show SHALL follow the global period unless the listener turns off "Use my default" in the show's new-episode settings and picks the show's own value, which MAY equal the global one. Expiry MUST run on every refresh.

#### Scenario: Episode expires
- **WHEN** an episode has been in the Inbox for 15 days and the period is 14 days
- **THEN** after the next refresh it is in the archive with the reason "expired"

#### Scenario: Show override
- **WHEN** the global period is 14 days and a show uses its own value of 3 days
- **THEN** that show's Inbox episodes expire after 3 days

#### Scenario: Own value equal to the default
- **WHEN** a show uses its own value of 14 days and the listener changes the global period to 7 days
- **THEN** that show's episodes still expire after 14 days

#### Scenario: Never
- **WHEN** the period for a show is never
- **THEN** that show's Inbox episodes do not expire

### Requirement: Explain automatic moves
Every episode row SHALL show the reason for the episode's latest automatic move: "Auto-queued", "Play next", "Skipped by show setting", or "Removed after N days".

#### Scenario: Expired episode on the show page
- **WHEN** the listener opens the show page of an episode that expired after 7 days
- **THEN** the episode row reads "Removed after 7 days"
