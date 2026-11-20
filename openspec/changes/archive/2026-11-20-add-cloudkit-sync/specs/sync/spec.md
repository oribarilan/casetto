# Spec Delta

## Purpose

Keeps the listener's subscriptions, Queue, episode states, settings, and bookmarks the same on every device signed in to their iCloud account.

## ADDED Requirements

### Requirement: User data syncs through iCloud
The system SHALL sync subscriptions, episode states, settings, and bookmarks through the listener's private iCloud database when the app is set up with an iCloud container. Feed data and downloaded files MUST NOT sync.

#### Scenario: Reinstall
- **WHEN** the listener reinstalls the app on a device signed in to the same iCloud account
- **THEN** their subscriptions, Queue, and bookmarks return

#### Scenario: Change on another device
- **WHEN** the listener queues an episode on one device and then opens the app on another
- **THEN** the second device shows the episode in its Queue

#### Scenario: Records in the CloudKit dashboard
- **WHEN** the listener subscribes to a show on a set-up device
- **THEN** a subscription record appears in the container's private database in the CloudKit dashboard

### Requirement: Duplicates merge
When more than one record exists for the same episode, show, or settings, the system SHALL keep one. For an episode, the record with the latest move MUST win, and the earliest first-play time MUST be kept. For a show, the earliest subscription MUST win. For settings, the most recently changed record MUST win. The Queue MUST be numbered 1 to N after a merge.

#### Scenario: Two devices place the same new episode
- **WHEN** one device puts a new episode in the Inbox and, before syncing, another device puts it in the Queue later
- **THEN** after both sync, the episode has one state, in the Queue

#### Scenario: New device with default settings
- **WHEN** a new device creates default settings before the listener's settings arrive from iCloud
- **THEN** the listener's settings win

### Requirement: Works without iCloud
The app SHALL work on one device when it has no iCloud container, when the listener is signed out of iCloud, or in the simulator.

#### Scenario: No container set up
- **WHEN** the app runs without the iCloud entitlement
- **THEN** every feature works and data stays on the device
