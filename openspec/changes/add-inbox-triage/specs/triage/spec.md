# Spec Delta

## Purpose

Sorts new episodes for the listener, per show, so something good is ready to play without manual triage, and makes every automatic move visible and reversible.

## ADDED Requirements

### Requirement: Triage levels
Each subscription SHALL have one triage level: Inbox, Auto-queue, Play next, or Skip. A new subscription MUST start at Inbox. The system SHALL let the listener change a show's level on its show page.

#### Scenario: New subscription
- **WHEN** the listener subscribes to a show
- **THEN** the show's level is Inbox

#### Scenario: Change level
- **WHEN** the listener sets a show's level to Auto-queue
- **THEN** the show page shows Auto-queue and later new episodes follow it

### Requirement: New episodes follow the level
On refresh, each new episode of a subscribed show SHALL move according to the show's level. Auto-queue adds it to the end of the Queue. Play next adds it as the "Play next" requirement says. Inbox puts it in the Inbox. Skip moves it to the archive with the reason "skipped". A new episode is one that was published after the show's triage date and has never had a place. Subscribing sets the triage date.

#### Scenario: Auto-queue show releases an episode
- **WHEN** an Auto-queue show publishes a new episode and the app refreshes
- **THEN** the episode is the last item in the Queue with the reason "auto-queued"

#### Scenario: Inbox show releases an episode
- **WHEN** an Inbox show publishes a new episode and the app refreshes
- **THEN** the episode is in the Inbox

#### Scenario: Skip show releases an episode
- **WHEN** a Skip show publishes a new episode and the app refreshes
- **THEN** the episode is in the archive with the reason "skipped"

#### Scenario: Feed data re-fetched
- **WHEN** the feed cache is wiped and every feed is fetched again
- **THEN** no already-triaged episode is triaged a second time

#### Scenario: Episode the listener already placed
- **WHEN** a new episode already has a place because the listener acted on it
- **THEN** triage leaves it where it is

### Requirement: Play next
A show at the Play next level MUST put its new episodes directly after Now Playing, after any earlier play-next episodes, so that several releases stack in release order above the episodes the listener queued.

#### Scenario: Two play-next shows release the same morning
- **WHEN** play-next shows A and B release episodes, A's first, and the Queue holds Now Playing then 3 episodes the listener queued
- **THEN** the Queue is Now Playing, A's episode, B's episode, then the 3 queued episodes in their order

#### Scenario: Empty Queue
- **WHEN** a play-next show releases an episode and the Queue is empty
- **THEN** the episode is the only item in the Queue

### Requirement: Inbox
The system SHALL show the Inbox episodes newest first. From the Inbox the listener SHALL be able to add an episode to the Queue, dismiss it to the archive with the reason "dismissed", or play it. The Queue screen SHALL show a "New (N)" row linking to the Inbox when N is at least 1.

#### Scenario: Count on the Queue screen
- **WHEN** the Inbox holds 3 episodes
- **THEN** the Queue screen shows "New (3)" and tapping it opens the Inbox

#### Scenario: Empty Inbox
- **WHEN** the Inbox is empty
- **THEN** the Queue screen shows no "New" row

#### Scenario: Queue from the Inbox
- **WHEN** the listener adds an Inbox episode to the Queue
- **THEN** it leaves the Inbox and becomes the last Queue item

#### Scenario: Dismiss
- **WHEN** the listener dismisses an Inbox episode
- **THEN** it moves to the archive with the reason "dismissed"

### Requirement: Inbox expiry
An Inbox episode untouched for its expiry period SHALL move to the archive with the reason "expired". The period SHALL be a global setting of 7 days by default, with options of 3, 7, 14, or 30 days or never. The system SHALL let the listener override it per show. Expiry MUST run on every refresh.

#### Scenario: Episode expires
- **WHEN** an episode has been in the Inbox for 8 days and the period is 7 days
- **THEN** after the next refresh it is in the archive with the reason "expired after 7 days"

#### Scenario: Show override
- **WHEN** the global period is 7 days and a show overrides it to 14 days
- **THEN** that show's Inbox episodes expire after 14 days

#### Scenario: Never
- **WHEN** the period for a show is never
- **THEN** that show's Inbox episodes do not expire

### Requirement: Explain automatic moves
Every episode row SHALL show the reason for the episode's latest automatic move: "Auto-queued", "Play next", "Skipped by show setting", or "Expired after N days".

#### Scenario: Expired episode on the show page
- **WHEN** the listener opens the show page of an episode that expired after 7 days
- **THEN** the episode row reads "Expired after 7 days"

### Requirement: Undo automatic moves
The system SHALL offer Undo on an episode whose latest move was automatic and happened less than 30 days ago. Undo MUST return the episode to its previous place. An expired episode restored to the Inbox MUST get a full new expiry period. The listener's own moves have no Undo.

#### Scenario: Undo an expiry
- **WHEN** the listener taps Undo on an episode that expired
- **THEN** it is back in the Inbox and expires again only after a full period

#### Scenario: Undo an auto-queue
- **WHEN** the listener taps Undo on an auto-queued episode
- **THEN** it leaves the Queue and has no place

#### Scenario: Episode moved again
- **WHEN** an auto-queued episode is later played or dismissed
- **THEN** it shows no Undo

#### Scenario: Older than 30 days
- **WHEN** an episode expired 31 days ago
- **THEN** it shows no Undo
