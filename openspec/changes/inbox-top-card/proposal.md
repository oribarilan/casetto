# Proposal

## Why

The listener wants the Inbox to feel more like a swipe deck. A full deck would ask for a decision on every episode and hide how much is waiting, while Casterr's Inbox lets the rest expire on their own. The listener picked option C, "The newest on a card, the rest below": the newest episode sits on a big card that you swipe, and the others wait as rows underneath. It keeps the overview and the fun of the swipe, with the gestures the Inbox already uses.

This is a backlog item, not a numbered roadmap milestone.

## What Changes

- **The newest episode is on a card** at the top of the Inbox episodes: big show art, the show, the title, the gray status line, and the first lines of its description.
- **Swipe the card** right to add it to the Queue or left to remove it, the same as a row today. The card follows the finger and tilts, and a Queue or Remove label fades in on the side it is going. Let go past the edge and it flies off; let go before and it springs back. A light tap of feedback marks the point where letting go will act.
- **The next episode takes the card**, and its row leaves the list below.
- **The others stay as rows** under "Also new · N", with their swipes and their line of actions as today.
- **A tap on the card** opens the same line of actions as a row.
- **VoiceOver** reads the card like a row and offers Add to Queue and Remove as actions.
- **The swipe tip** points at the card the first time.
- With Reduce Motion on, the card follows the finger but doesn't tilt, and it fades out in place of flying off.
- Version 0.7.

## Out of scope

- A card stack or a "sort one by one" mode.
- Undo after a swipe. The episode stays on its show page, as a removed row does today.
- Swipe up or down on the card.
- The suggestion cards, which stay above the episodes.
- The Queue screen.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `triage`: the newest Inbox episode on a swipeable card, the rest under "Also new", and the swipe tip on the card.

## Impact

- `Casterr/Screens/InboxView.swift`: the card for the first episode, the "Also new" section, and the tip target.
- `Casterr/Screens/InboxCard.swift` (new): the card and its drag.
- `CasterrUITests/ScreensTests.swift`: testInbox and testInboxSwipeTip use the card for the first episode.
- `CHANGELOG.md` and `project.yml`: version 0.7.
- `openspec/device-checks.md`: how the drag feels on the iPhone, and that scrolling still works when the finger starts on the card.
