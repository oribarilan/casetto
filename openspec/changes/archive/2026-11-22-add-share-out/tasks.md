# Tasks

## 1. Core

- [x] 1.1 Parse and store the episode's and the show's web page (dropping an item link that equals the channel link or repeats across items) and expose them on `EpisodeInfo` and `ShowInfo`; verify with parser tests (own links, all items pointing to the show page, no links) and a storage round trip
- [x] 1.2 Add `ShareText` for episodes (with and without a time) and shows (web page or feed address); verify with unit tests, including the audio-link fallback and the "from 12:34" suffix
- [x] 1.3 Add `ClipWindow` (visible span, default clip, drag limits, clamping near the start and end, and the byte range for a constant-bitrate file including an ID3 offset) and the loudness bar function; verify with unit tests for the middle, the start, the end, a 75-second drag, and a known byte range
- [x] 1.4 Extract `QuietGaps.find(in:)` from `BackABeat` with a moving two-second neighborhood option, and add `ClipWindow.snap(_:to:within:)` and snapping the default clip; verify the Back a Beat tests still pass and new tests cover snapping within 0.5 s, pulling free beyond it, the default clip snapping both edges within the limits, and no gap nearby

## 2. App

- [x] 2.1 Add the Now Playing share menu (Share Episode, Share Clip…), Share Episode in show page row context menus, and Share Show in the show page toolbar, all hidden for the built-in shared show; verify with a UI test that the menu offers both items and Share Episode opens the share sheet
- [x] 2.2 Fetch the clip span from what the player loaded (local file, or ranged requests with AVPlayer's User-Agent for a constant-bitrate streamed MP3, else the download or offline message) and decode it into bars; verify in the simulator that a streamed ATP episode shows bars within a few seconds and a downloaded one shows them at once, with the fetched bytes logged
- [x] 2.3 Build the E1 editor (bars, frame, draggable edges that snap to pauses with a tick, VoiceOver adjust, preview that pauses the episode); verify with a UI test that it opens around now, an edge drag changes the length, and the length stops at 60 seconds, and by listening in the simulator that a snapped clip starts and ends between words
- [x] 2.4 Export the square video (art still with the "Clipped with Casterr" badge, plus clip audio) and share it with the caption; verify in the simulator that the exported file plays, is about 1 MB for 30 s, and opens in the share sheet with the text
- [x] 2.5 Run all core and UI tests; add "Sharing from Casterr" to `podcast_app_concept.md`; add phone checks to `openspec/device-checks.md` (a clip to WhatsApp with its caption, a streamed and a downloaded clip, Share Episode to Messages with its preview, and Share Show)

## Workflow follow-up

- Archive the change after the listener approves the result, then run `openspec validate --specs --strict`.
