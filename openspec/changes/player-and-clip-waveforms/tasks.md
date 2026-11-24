## 1. Now Playing

- [x] 1.1 Move `PauseMeter` to its own file with a size and base color, use it in the mini player unchanged, and in Now Playing's pause button inside the white circle. Verify in the simulator, light and dark, and with Reduce Motion

## 2. Clip waveform

- [x] 2.1 Add a `LoudnessBars` function that takes the bars for the clip's span from the editor's window bars and resamples them to a count (the loudest in each group). Verify with core tests
- [x] 2.2 Draw the fade and the bars in `ClipFrame`, all unplayed in the editor preview. Verify the preview in the simulator
- [x] 2.3 Render the frame twice (unplayed and played) and write the video at 15 frames a second, each frame the unplayed one with the played part drawn over it up to the clip's progress. Verify with a simulator clip: frames at the start, middle and end, file size, and the export time

## 3. Checks

- [x] 3.1 Remove the "Waveform in clips" backlog entry, run the core and UI tests
- [x] 3.2 Add a device check: the Now Playing meter matches the mini player's; a shared clip's waveform fills in time with the audio in Messages and WhatsApp

## Workflow follow-up

- Move the device check to `openspec/device-checks.md` before archiving.
