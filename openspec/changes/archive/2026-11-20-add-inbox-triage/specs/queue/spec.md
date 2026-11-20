# Spec Delta

## MODIFIED Requirements

### Requirement: One place per episode
Every episode SHALL be in exactly one place: the Inbox, the Queue, the archive, or no place. An episode with no place is only visible on its show page.

#### Scenario: Add an episode that has no place
- **WHEN** the listener adds an episode with no place to the Queue
- **THEN** the episode is in the Queue and in no other place

#### Scenario: Add an archived episode
- **WHEN** the listener adds an archived episode to the Queue
- **THEN** the episode leaves the archive and is in the Queue

#### Scenario: Add an episode that is already queued
- **WHEN** the listener adds an episode that is already in the Queue
- **THEN** the Queue does not get a second entry for it and its position does not change

#### Scenario: Add an Inbox episode
- **WHEN** the listener adds an Inbox episode to the Queue
- **THEN** the episode leaves the Inbox and is in the Queue
