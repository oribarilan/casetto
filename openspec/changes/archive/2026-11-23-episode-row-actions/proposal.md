## Why

Swipes give each episode row two hidden actions, and each screen has a different pair. The Queue can't mark an episode played, move it up next, share it, or open its show. Each screen also marks an episode's state differently: the show page has orange words above the title, the Queue has a download icon, and the Inbox has neither.

This is not a roadmap milestone. It is polish from daily use after the MVP. The listener picked B1, a line of actions under the row, and 1B, gray status words.

## What Changes

- **BREAKING:** a tap on an episode row in the Queue, the Inbox, or a show page no longer plays it. The tap opens a line of round buttons under the row, with Play first. Only one line is open at a time. Tapping the same row closes it, tapping another row moves it there, and using any action but Share closes it. The mini player still plays with one tap.
- Each screen offers the actions that apply, at most six, and hides the rest:

  | Action | Queue | Inbox | Show page |
  |---|---|---|---|
  | Play (Pause while that episode plays) | ✓ | ✓ | ✓ |
  | Play Next | ✓, not on the first two rows | ✓ | ✓, when not first or second in the Queue |
  | Add to Queue | (none) | ✓ | ✓, when not queued |
  | Played / Unplayed | ✓ | (none) | ✓ |
  | Share | ✓ | ✓ | ✓ |
  | Show | ✓ | ✓ | (none) |
  | Remove | ✓ | ✓ | ✓, when in the Inbox or Queue |
  | Delete | (none) | (none) | shared files only |

- The swipes and drag to reorder in the Queue stay as they are.
- **BREAKING:** the Undo button for automatic moves goes away. The line already fixes each one: Remove for an auto-queued or play-next episode, Add to Queue or Play for a skipped or expired one. The gray reason words stay, so every automatic move still says why it happened. Sending an expired episode back to the Inbox is no longer possible; queue or play it instead.
- An episode removed from the Queue now reads "Removed" on its show page, like one removed from the Inbox. Before, it was left with no place and no word.
- The long-press menu on show page rows goes away. Its Share Episode and Delete are now in the line.
- Every row shows its status in the same way: words in the line above the title. Queued, In Inbox, Played, Removed, Downloaded and the automatic move reasons are gray. Only "Up next", "Playing" and "Paused" on the first Queue row stay orange. A played episode's title is gray.
- "Downloaded" replaces the download icon. A started episode shows "18 min left" in place of its length.
- A status that every row on a screen shares is left out: no "Queued" in the Queue, and no "In Inbox" in the Inbox.

Calls made while writing this, open to correction:

- The Inbox has no Played, so it fits in six buttons. Remove already covers "not for me".
- On the episode that's playing, the first button is Pause.
- The long-press menu on show pages is dropped, because the line has the same actions.

Out of scope: download progress while a download runs (the backlog item "Download status in the Queue" stays for that), Bookmarks rows, Find Shows rows, and Now Playing.

## Capabilities

### New Capabilities

- `episode-rows`: what a tap on an episode row does, the actions on each screen, and how a row shows its status.

### Modified Capabilities

- `triage`: the Undo requirement is removed.
- `queue`: removing from the Queue leaves the episode "Removed", not with no place.
- `downloads`: the downloaded mark is the word "Downloaded" on every episode row, not only the Queue's icon.
- `sharing`: episodes share from rows in the Queue and the Inbox as well as show pages, from the action line instead of a long press.

## Impact

- `EpisodeRow.swift`: the tap toggles the action line, the status line, minutes left, the gray played title.
- `QueueView.swift`, `InboxView.swift`, `ShowView.swift`: which row is open, the actions for each screen, the status words to leave out. `ShowView` loses its `contextMenu`.
- No CasterrCore changes: `Library` already has play next, mark played and unplayed, add to Queue, remove, dismiss and progress.
- UI tests that tap a row to play (`SmokeTests`, `ScreensTests`) now tap Play in the line. The share test opens the line instead of long-pressing.
