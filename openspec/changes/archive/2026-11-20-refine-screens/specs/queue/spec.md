# Spec Delta

## MODIFIED Requirements

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
The system SHALL let the listener add an episode to the end of the Queue, remove an episode from the Queue by swiping left, and move an episode to any position by long-pressing and dragging, without an Edit button. The system MUST NOT reorder the Queue on its own.

#### Scenario: Add to end
- **WHEN** the listener taps "Add to Queue" on an episode
- **THEN** the episode becomes the last item in the Queue

#### Scenario: Reorder
- **WHEN** the listener long-presses the fourth item and drags it to the second position
- **THEN** the item is second and the relative order of all other items is unchanged

#### Scenario: Remove
- **WHEN** the listener swipes a Queue episode left and taps Remove
- **THEN** the episode has no place and keeps its listening progress

#### Scenario: Order survives restart
- **WHEN** the app is closed and opened again
- **THEN** the Queue has the same items in the same order

## ADDED Requirements

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
