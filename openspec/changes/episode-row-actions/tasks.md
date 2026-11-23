## 1. The row

- [ ] 1.1 Add the action line to `EpisodeRow`: `isOpen`, a toggle, a list of `RowAction`s, an optional share payload, round labeled buttons with Play filled; a tap toggles the line instead of playing. Verify the app builds and a Queue row opens and closes its line in the simulator
- [ ] 1.2 Add the status line to `EpisodeRow`: an orange `label`, gray `statuses`, the move reason and "Downloaded" appended, a gray title when played, "N min left" in place of the length when there's progress. Verify in the simulator on the show page

## 2. The screens

- [ ] 2.1 Queue: `openRow`, the actions Play or Pause, Play Next (not on the first row), Played, Share, Show, Remove, the first row's orange label, progress loaded with the moves, no "Queued". Verify each action in the simulator
- [ ] 2.2 Inbox: `openRow`, the actions Play or Pause, Play Next, Add to Queue, Share, Show, Remove, progress and downloads shown, no "In Inbox". Verify each action in the simulator
- [ ] 2.3 Show page: `openRow`, the actions Play or Pause, Play Next, Add to Queue, Played or Unplayed, Share (not for shared files), Remove (dismiss from the Inbox, remove from the Queue), Delete (shared files), the place words gray; remove the `contextMenu`. Verify each action, including on a shared file, in the simulator

## 3. Tests

- [ ] 3.1 Update the UI tests that tap a row to play so they tap Play in the line, with one helper; change the share test to open the line instead of long-pressing
- [ ] 3.2 Add UI checks: the line opens and moves between rows, Play Next and Played from the Queue, Show from the Inbox, "Queued · Downloaded" or "Queued" on a show page, no Share on a shared file
- [ ] 3.3 Run the core and UI tests, and take light and dark screenshots of the Queue, the Inbox and a show page with a line open

## Workflow follow-up

- Move the checks that need a real iPhone (feel of the line, VoiceOver on the line) to `openspec/device-checks.md` before archiving.
