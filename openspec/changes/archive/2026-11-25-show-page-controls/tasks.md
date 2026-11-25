## 1. Buttons

- [x] 1.1 Follow: keep `ShowPageButton` as one button, tint it a grey system fill with primary text when on and tangerine with `onTangerine` text when off, and let it fill the width that Star leaves. Verify: in the simulator, Follow is tangerine, Following is grey, and the plus still spins into the check.
- [x] 1.2 Star: a round `.bordered` button with `.buttonBorderShape(.circle)` at Follow's height, grey with `star` or a tangerine `star.fill`, keeping the -144 degree spin and the accessibility label Star or Starred. Verify: in the simulator, Star spins as it fills, Unstar doesn't, and VoiceOver reads Star or Starred.

## 2. New episodes rows

- [x] 2.1 Check on the iOS 27 simulator how to show each choice's explanation and a value that reads differently from its menu item. Write the result in design.md. Verify: design.md names the one used and why.
- [x] 2.2 Replace the row with "New episodes go to" and its four choices and explanations, saving with `setLevel`. Keep the `newEpisodesRow` identifier on it. Verify: in the simulator, picking Play next on an Inbox show reads "Play next" at once.
- [x] 2.3 Add the "Removed after" row for Inbox only, with My default (and its period) first, then `InboxExpiry.choices`, saving with `setExpiryOverride`, identifier `removedAfterRow`. Verify: picking 3 days reads "3 days", picking My default reads the default period, and the row goes when the choice isn't Inbox.
- [x] 2.4 Delete `NewEpisodesSheet.swift` and the page's sheet state, and move `InboxExpiry.shortTitle` to `SettingsView.swift`. Verify: the app builds and Settings' Inbox period picker still reads 1d to Never.

## 3. No jump

- [x] 3.1 Add `pendingLevel` and `pendingOverride` beside `pendingFollow` and `pendingStar`, set and clear all four together in `act`, and send the rows' menu choices through `act`. Follow sets Inbox; Star sets Queue when the show isn't followed or is at Inbox. Show the rows from the pending values when there are any. Verify: in the simulator with a slow feed, tapping Follow shows the row at once reading Inbox, and picking Skip before the save lands keeps Skip after it.
- [x] 3.2 Animate: rows grow in and out with the List's own insert animation under `withAnimation(.snappy)`, and the value cross-fades. With Reduce Motion on, change without animation. Verify: in the simulator, Follow grows the row in and slides the list, Unfollow shrinks it, a new choice cross-fades, and with Reduce Motion on nothing moves.

## 4. Tests and release bookkeeping

- [x] 4.1 Update the UI tests that open the sheet (testScreens, testRuleCard, testInstantControls) to use the menus, and add a check that tapping Follow shows `newEpisodesRow` before the feed loads. Verify: those tests pass.
- [x] 4.2 Set `MARKETING_VERSION` to 0.6 and add a `## 0.6` CHANGELOG section: one line for the new Follow and Star look and one for choosing where new episodes go from a menu on the show page. Verify: testWhatsNew passes.
- [x] 4.3 Add to `openspec/device-checks.md`: on the iPhone, the row grows in on Follow without a jump, the list slides, a choice cross-fades, and the buttons look right in light and dark. Verify: the section is there.
- [x] 4.4 Run the core tests and the UI tests. Verify: all pass, apart from the known testCapture cold-start flake.

## Workflow follow-up

- Commit as version 0.6 only when the listener says to.
- Archive after the listener approves, then run `openspec validate --specs --strict`.
