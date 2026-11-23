## MODIFIED Requirements

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
