## ADDED Requirements

### Requirement: Newest Inbox episode on a card
The Inbox SHALL show its newest episode on a card above the other episodes, with the show's art, the show's name, the title, the gray status line that a row shows, and the first three lines of the description without HTML. The other episodes MUST show as rows under the heading "Also new · N", where N counts them. A tap on the card MUST open the same line of actions as a row.

#### Scenario: Several episodes
- **WHEN** the Inbox holds 5 episodes
- **THEN** the newest is on the card and the other 4 are rows under "Also new · 4"

#### Scenario: One episode
- **WHEN** the Inbox holds 1 episode
- **THEN** it is on the card and there is no "Also new" heading

#### Scenario: Tap the card
- **WHEN** the listener taps the card
- **THEN** the line of actions opens under it, with Play first

### Requirement: Swiping the Inbox card
A swipe right on the card SHALL add its episode to the Queue, and a swipe left SHALL remove it, as on a row. The card MUST follow the finger, with a Queue or Remove label that shows on the side it moves to. Let go past the point of acting and the card MUST act, with a light tap of feedback at that point; let go before it and the card MUST spring back. The next episode MUST then take the card and leave the rows.

#### Scenario: Queue from the card
- **WHEN** the listener swipes the card right past the point of acting
- **THEN** its episode becomes the last Queue item, and the next episode moves from the rows onto the card

#### Scenario: Remove from the card
- **WHEN** the listener swipes the card left past the point of acting
- **THEN** its episode moves to the archive with the reason "dismissed"

#### Scenario: Change of mind
- **WHEN** the listener drags the card halfway and lets go
- **THEN** it springs back and nothing changes

#### Scenario: VoiceOver
- **WHEN** VoiceOver focuses the card
- **THEN** it reads like a row and offers the actions Add to Queue and Remove

### Requirement: Inbox card moves smoothly
While dragged, the card SHALL tilt toward the side it moves to. When it acts it MUST fly off on that side, and the rows MUST slide up as the next episode takes the card. With Reduce Motion on, the card MUST follow the finger without tilting and fade out in place of flying off.

#### Scenario: Fly off
- **WHEN** the listener swipes the card right and lets go
- **THEN** the card flies off to the right and the rows below slide up

#### Scenario: Reduce Motion
- **WHEN** Reduce Motion is on and the listener swipes the card
- **THEN** the card doesn't tilt and fades out when it acts

### Requirement: Inbox card on a pile
When more episodes wait under the card, a second card SHALL show behind it, turned a little and peeking out below, so the card looks like the top of a pile that it comes off. The card on top MUST stay straight. The card behind MUST stay in place while the listener drags the card on top, and MUST NOT be read by VoiceOver.

#### Scenario: More episodes waiting
- **WHEN** the Inbox holds 3 episodes
- **THEN** a turned card peeks out under the straight card on top

#### Scenario: Last episode
- **WHEN** the Inbox holds 1 episode
- **THEN** no card shows behind the card

#### Scenario: Drag the card
- **WHEN** the listener drags the card sideways
- **THEN** the card behind stays where it is

## MODIFIED Requirements

### Requirement: Inbox swipe tip
The first Inbox visit SHALL show a one-time tip on the card that teaches the swipes.

#### Scenario: First visit
- **WHEN** the listener opens the Inbox for the first time
- **THEN** a tip on the card says "Swipe right to queue an episode, or left to remove it."

#### Scenario: Seen the row tip before
- **WHEN** the listener saw the swipe tip on an Inbox row in an earlier version and opens the Inbox with the card
- **THEN** the tip shows once on the card
