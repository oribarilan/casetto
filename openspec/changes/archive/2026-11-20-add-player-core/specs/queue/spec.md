# Spec Delta

## Purpose

Holds the ordered list of episodes the listener chose to hear, defines the single place each episode lives, and defines when an episode counts as played.

## ADDED Requirements

### Requirement: One place per episode
Every episode SHALL be in exactly one place: the Queue, the archive, or no place. In this milestone an episode with no place is only visible on its show page.

#### Scenario: Add an episode that has no place
- **WHEN** the listener adds an episode with no place to the Queue
- **THEN** the episode is in the Queue and in no other place

#### Scenario: Add an archived episode
- **WHEN** the listener adds an archived episode to the Queue
- **THEN** the episode leaves the archive and is in the Queue

#### Scenario: Add an episode that is already queued
- **WHEN** the listener adds an episode that is already in the Queue
- **THEN** the Queue does not get a second entry for it and its position does not change

### Requirement: Queue is the home screen
The system SHALL show the Queue as the home screen. The first item in the Queue SHALL be the Now Playing episode.

#### Scenario: Open the app with a non-empty Queue
- **WHEN** the listener opens the app and the Queue has 5 episodes
- **THEN** the home screen lists the 5 episodes in order with the first shown as Now Playing

#### Scenario: Open the app with an empty Queue
- **WHEN** the Queue is empty
- **THEN** the home screen tells the listener that nothing is queued and links to their shows

### Requirement: Manage Queue order
The system SHALL let the listener add an episode to the end of the Queue, remove an episode from the Queue, and move an episode to any position. The system MUST NOT reorder the Queue on its own.

#### Scenario: Add to end
- **WHEN** the listener taps "Add to Queue" on an episode
- **THEN** the episode becomes the last item in the Queue

#### Scenario: Reorder
- **WHEN** the listener drags the fourth item to the second position
- **THEN** the item is second and the relative order of all other items is unchanged

#### Scenario: Remove
- **WHEN** the listener removes an episode from the Queue
- **THEN** the episode has no place and keeps its listening progress

#### Scenario: Order survives restart
- **WHEN** the app is closed and opened again
- **THEN** the Queue has the same items in the same order

### Requirement: Playing an episode puts it first
When the listener starts playing an episode, the system SHALL move that episode to the first position of the Queue. The order of the other items MUST NOT change.

#### Scenario: Play an episode from a show page
- **WHEN** the listener plays an episode that is not in the Queue
- **THEN** the episode becomes the first item and the previous items follow in their original order

#### Scenario: Play an episode lower in the Queue
- **WHEN** the listener plays the third item in the Queue
- **THEN** that episode becomes the first item and the others keep their relative order

### Requirement: Played episodes move to the archive
An episode SHALL count as played when fewer than 60 seconds of it remain, or when the listener marks it played. A played episode MUST move to the archive with the reason "played" and leave the Queue.

#### Scenario: Playback reaches the last 60 seconds
- **WHEN** playback of the first item reaches a point with fewer than 60 seconds remaining
- **THEN** the episode counts as played and moves to the archive when playback of it ends or the listener skips to the next item

#### Scenario: Mark played
- **WHEN** the listener marks a queued episode as played
- **THEN** the episode leaves the Queue and moves to the archive

#### Scenario: Next episode starts
- **WHEN** the first item finishes playing and the Queue has more items
- **THEN** the next item becomes first and starts playing

#### Scenario: Mark unplayed
- **WHEN** the listener marks an archived episode as unplayed
- **THEN** the episode has no place and its progress is reset to the start
