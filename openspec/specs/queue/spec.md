# queue Specification

## Purpose
Holds the ordered list of episodes the listener chose to hear, defines the single place each episode lives, and defines when an episode counts as played.

## Requirements

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

### Requirement: Queue is the home screen
The system SHALL show the Queue as the home screen, in the first of the app's tabs. The first item in the Queue SHALL be the episode the player plays, and its label MUST say what it's doing: "Playing" with a moving waveform while audio plays, "Paused" when it's loaded but stopped, or "Up next" when nothing is loaded. An empty Queue SHALL point at what's waiting in the Inbox when anything is, and otherwise lead to the Shows tab.

#### Scenario: Open the app with a non-empty Queue
- **WHEN** the listener opens the app and the Queue has 5 episodes
- **THEN** the Queue tab is selected and lists the 5 episodes in order with the first labeled "Up next"

#### Scenario: Playing
- **WHEN** the first episode is playing
- **THEN** its label reads "Playing" with a moving waveform

#### Scenario: Empty Queue with a waiting episode
- **WHEN** the Queue is empty and 1 episode is in the Inbox
- **THEN** Cassy says "Your Queue is empty, but 1 new episode is waiting." with an Open Inbox button

#### Scenario: Open the app with an empty Queue
- **WHEN** the Queue and the Inbox are empty
- **THEN** the home screen tells the listener that nothing is queued and links to the Shows tab

### Requirement: Manage Queue order
The system SHALL let the listener add an episode to the end of the Queue, remove an episode from the Queue by swiping left or from its action line, which leaves it removed like a removed Inbox episode, and move an episode to any position by long-pressing and dragging, without an Edit button. The system MUST NOT reorder the Queue on its own.

#### Scenario: Add to end
- **WHEN** the listener taps "Add to Queue" on an episode
- **THEN** the episode becomes the last item in the Queue

#### Scenario: Reorder
- **WHEN** the listener long-presses the fourth item and drags it to the second position
- **THEN** the item is second and the relative order of all other items is unchanged

#### Scenario: Remove
- **WHEN** the listener swipes a Queue episode left and taps Remove
- **THEN** the episode leaves the Queue, keeps its listening progress, and its show page row reads "Removed"

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

### Requirement: Up-next bar
While nothing is playing and the Queue isn't empty, the bottom bar SHALL offer the first Queue episode with a play button. It MUST say "Up next · from your Queue" for an episode with no progress and "Continue · N min left" for a started one, so starting is never mistaken for resuming. Tapping the bar SHALL open the Queue.

#### Scenario: New episode
- **WHEN** nothing is playing and the first Queue episode has never been played
- **THEN** the bar says "Up next · from your Queue" and its play button starts it

#### Scenario: Started episode
- **WHEN** nothing is playing and the first Queue episode has 25 minutes left
- **THEN** the bar says "Continue · 25 min left"

#### Scenario: Empty Queue
- **WHEN** nothing is playing and the Queue is empty
- **THEN** no bar shows

### Requirement: Queue shows episodes this device has
A device's Queue SHALL list only the queued episodes whose show and episode that device knows. An episode queued on another device, such as a shared file or an episode of a show the listener doesn't follow, MUST be skipped in the list, in the up-next bar, and when choosing what plays next. The others MUST keep their order, and moving an episode or choosing Play next MUST count only the episodes the device shows.

#### Scenario: Shared file queued on another device
- **WHEN** the phone's Queue is a shared file, then two episodes of followed shows, and the listener opens the iPad
- **THEN** the iPad's Queue lists the two episodes in order, and pressing play starts the first of them
