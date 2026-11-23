## 1. Loading paused

- [x] 1.1 Add `Player.load(_:)`: the same setup as starting an episode (info, show, saved position, speed, chapters, voice boost, file or stream) without playing and without recording a play start; `start` shares it. Verify with core tests: position, not playing, no play start recorded, and play resumes from the saved position with no Back a Beat
- [x] 1.2 In `AppModel.loadUpNext`, load the up-next episode into the player when nothing is loaded and it has progress; drop the "Continue" caption. Verify in the simulator that a started first episode shows the mini player after the app opens

## 2. Mini player

- [x] 2.1 Remove `BookmarkButton` from `MiniPlayer`, update the Capture paragraph in `podcast_app_concept.md`, and remove the backlog entry. Verify the capture UI test still bookmarks from Now Playing

## 3. Checks

- [x] 3.1 Run the core and UI tests
- [x] 3.2 Add a device check: play an episode, force quit, reopen; the mini player shows it paused, opens Now Playing on tap, and play resumes where it stopped

## Workflow follow-up

- Move the device check to `openspec/device-checks.md` before archiving.
