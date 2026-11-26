## 1. The card

- [x] 1.1 Add `InboxCard` in `Casterr/Screens/InboxCard.swift`: show art, show name with the gray star for a starred show, the title, the row's gray status line, and three lines of the summary without HTML, through the same cleanup as the show's `plainSummary`. Verify: in the simulator, the card shows these for the newest episode in light and dark.
- [x] 1.2 In `InboxView`, put the first episode on the card and the rest under "Also new · N", with no heading for one episode. A tap on the card opens the row's line of actions. Verify: with 5 episodes, the card and "Also new · 4"; with 1, only the card.

## 2. The drag

- [ ] 2.1 Add the horizontal drag: the card follows the finger and tilts, the Queue and Remove labels fade in, and letting go before a third of the width springs back. Verify on the iPhone first: a vertical drag that starts on the card scrolls the Inbox.
- [x] 2.2 Act past the point: fly off, light feedback at the point, `addToQueue` or `dismiss` through `model.change(.episodes)`, and the next episode takes the card at once while its row leaves the list. Verify: in the simulator, a right swipe queues the episode and the next one moves onto the card.
- [ ] 2.3 Reduce Motion: no tilt, fade out in place of flying off. VoiceOver: one element with Add to Queue and Remove actions. Verify: both in the simulator.
- [x] 2.4 Move the swipe tip to the card. Verify: testInboxSwipeTip.

## 3. Tests and release bookkeeping

- [x] 3.1 Update testInbox and testInboxSwipeTip for the card, and add a test that swipes the card right and left. Verify: they pass.
- [x] 3.2 Set `MARKETING_VERSION` to 0.7 and add a `## 0.7` CHANGELOG section. Verify: testWhatsNew passes.
- [x] 3.3 Add to `openspec/device-checks.md`: the drag feels right, scrolling from the card works, and the fly-off doesn't stutter. Verify: the section is there.
- [x] 3.4 Run the core tests and the UI tests. Verify: all pass, apart from the known testCapture cold-start flake.

## Workflow follow-up

- Install on the listener's iPhone to try it before the commit.
- Commit as version 0.7 only when the listener says to.
- Archive after the listener approves, then run `openspec validate --specs --strict`.
