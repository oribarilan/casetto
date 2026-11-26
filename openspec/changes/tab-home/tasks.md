## 1. Tab taps

- [x] 1.1 Check in the simulator what iOS does today on a second tap on the open tab: does it go back to the main page, and does it call the tab selection's setter? Write the result in design.md. Verify: the result is in design.md.
- [x] 1.2 Give the `TabView` a selection binding whose setter empties the Queue's path on a tap on Queue, then sets the tab. iOS already handles the second tap (task 1.1). Verify: in the simulator, Settings, then Shows, then Queue shows the Queue; a show page in Shows, then Queue, then Shows shows the show page; a second tap on Shows shows the grid. The refresh message's link moves to the iPhone (task 3.1): the message lasts 5 seconds, and the UI test's taps came too late to hit it, with the old code too.

## 2. Tests and release bookkeeping

- [x] 2.1 Add a UI test for the scenarios "Back to the Queue from another tab", "Shows keeps its place", and "Second tap on the open tab". Verify: it passes.
- [x] 2.2 Set `MARKETING_VERSION` to 0.8 and add a `## 0.8` CHANGELOG section. Verify: testWhatsNew passes.
- [x] 2.3 Run the core tests and the UI tests. Verify: all pass, apart from the known cold-start flakes.

## 3. On the iPhone

- [ ] 3.1 On the Shows tab, pull to refresh, then tap Cassy's message. Verify: the Inbox opens in the Queue tab.

## Workflow follow-up

- Install on the listener's iPhone to try it before the commit.
- Commit as version 0.8 only when the listener says to.
- Archive after the listener approves, then run `openspec validate --specs --strict`.
