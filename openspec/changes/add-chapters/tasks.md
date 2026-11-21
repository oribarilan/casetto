# Tasks

## 1. Core

- [x] 1.1 Add `Chapter` and `ShowNotesChapters.parse(_:duration:)`; verify with unit tests on the real וויקלי סינק episode 218 notes as a fixture (10 chapters, with the repeated list removed), a Lex-style "(00:12:30) Title" list, "0:00 - Intro" separators, a single timestamp (no chapters), a time in prose (no chapters), a date line like "09:00:00 -0000" (no chapters), times out of order, and a time beyond the duration
- [x] 1.2 Add `onChapters` to `AudioEngine` and `FakeEngine`; give `Player` `chapters`, `currentChapter`, and `jump(to:)`, with show-notes chapters when an episode starts and file chapters replacing them; verify with player tests: notes chapters at start, file chapters win, file chapters from a previous episode are ignored, the current chapter before the first, inside one, and at a boundary, a jump while playing and while paused, and the progress helper (earlier, playing, and later fractions, time left rounded up, the last chapter with and without a duration)

## 2. App

- [x] 2.1 Read file chapters in `AVPlayerEngine` once the item is ready, using the reported chapter locale and including artwork; verify in the simulator with a debug log of the chapter count for a streamed ATP episode (12 chapters expected) and a downloaded one
- [x] 2.2 Add the chapter pill (with its fill) and the chapter list sheet (rows as progress bars, time left on the playing row) to Now Playing, with natural text direction, VoiceOver label and hint, and scrolling to the playing chapter; verify with a UI test on a feed with chapters that the pill appears, the list opens with "min left" on the playing row, and tapping a chapter moves the elapsed time to its start
- [x] 2.3 Show the current chapter's artwork in Now Playing when it has one, and the show's art otherwise; verify in the simulator on an episode with chapter pictures, or record that none of the sample feeds has them
- [x] 2.4 Run all core and UI tests; add a Chapters bullet to the Player section of `podcast_app_concept.md` and change the "After the MVP" item to "transcripts"; add a phone check to `openspec/device-checks.md` (a file-chapters episode, a show-notes episode such as וויקלי סינק, jumping from the list, and the pill updating as chapters change)

## Workflow follow-up

- Archive the change after the listener approves the result, then run `openspec validate --specs --strict`.
