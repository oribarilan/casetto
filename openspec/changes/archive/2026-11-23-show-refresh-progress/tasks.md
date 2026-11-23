## 1. Progress

- [x] 1.1 Give `FeedService.refreshAll` a `progress` callback, called with 0 and after each show. Verify with a core test
- [x] 1.2 Track `refreshProgress` in `AppModel` from 0 to 1 while a refresh runs, moving only forward

## 2. The line

- [x] 2.1 Remove Cassy's loading row from the Queue and draw the line under the title: fill with each report, fill to the end and fade when done, labeled for VoiceOver. Verify in a simulator recording that the list doesn't move
- [x] 2.2 Remove the backlog entry for Cassy's loading animation

## 3. Tests

- [x] 3.1 Run the core and UI tests

## Workflow follow-up

- Move the check that needs the real iPhone (the line on app open with many shows) to `openspec/device-checks.md` before archiving.
