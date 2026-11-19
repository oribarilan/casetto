# Spec Delta

## MODIFIED Requirements

### Requirement: Unsubscribe
The system SHALL let the listener unsubscribe from a show. Episodes of that show that are in the Queue MUST stay in the Queue. Episodes of that show that are in the Inbox MUST move to the archive with the reason "unsubscribed".

#### Scenario: Unsubscribe with queued episodes
- **WHEN** the listener unsubscribes from a show that has 2 episodes in the Queue
- **THEN** the show leaves the subscription list and both episodes stay in the Queue in their positions

#### Scenario: Unsubscribe with Inbox episodes
- **WHEN** the listener unsubscribes from a show that has 3 episodes in the Inbox
- **THEN** those episodes move to the archive and the Inbox no longer lists them

#### Scenario: Feed stops refreshing
- **WHEN** the listener has unsubscribed from a show
- **THEN** the system no longer fetches that show's feed

## REMOVED Requirements

### Requirement: New subscription places no episodes
**Reason**: Subscribing now puts the newest episode through the show's triage level.
**Migration**: See "Subscribing places the newest episode" below.

## ADDED Requirements

### Requirement: Subscribing places the newest episode
Subscribing SHALL put the show's newest episode through the show's triage level, which starts at Inbox. Older episodes MUST get no place and appear only on the show page.

#### Scenario: Subscribe to a show with a back catalog
- **WHEN** the listener subscribes to a show with 200 published episodes
- **THEN** the newest episode is in the Inbox, the other 199 have no place, and the show page lists all 200, newest first
