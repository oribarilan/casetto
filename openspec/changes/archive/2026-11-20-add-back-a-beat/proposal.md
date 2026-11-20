# Proposal

## Why

When you pause a podcast, you stop mid-sentence. Pressing play drops you back into the middle of a word, and you've lost the thought. Back a Beat steps back a little and starts at a gap between words, so you hear the end of what was being said.

This isn't a roadmap milestone. It adds to the player from M1, after the MVP milestones.

## What Changes

- **Back a Beat:** when the listener plays again after a pause, Casterr looks at the audio from 5 s to 2 s before the pause point, finds the latest quiet gap between words, and resumes there. If no gap is quiet enough, playback resumes exactly at the pause point.
- It applies after every pause on the same episode: the Pause button, headphones, the lock screen, calls, Siri, unplugged headphones, and the sleep timer. It doesn't apply after the listener seeks, uses the skip buttons, or starts another episode.
- It's always on, with no setting. Its name appears only in the docs, not in the app.
- It works the same for downloaded and streamed episodes.
- The "Resume after pause" scenario in Saved progress changes: playback resumes at the pause point or up to 5 seconds before it.

## Capabilities

### Modified Capabilities

- `playback`: a new Back a Beat requirement, and Saved progress allows the step back.

## Out of scope

- Stepping back further after long pauses. "Back 15 seconds" covers that.
- A setting to turn it off. We add one only if the listener misses it.
- Finding word boundaries with speech recognition. Loudness only.
- Back a Beat when the app relaunches and resumes from saved progress, because no audio has played yet to search.

## Impact

- `CasterrCore`: a pure function that finds the resume point in loudness readings, and `Player` remembers the pause point and asks the engine for recent loudness when resuming. One new method on `AudioEngine`.
- App: `AVPlayerEngine` attaches an `MTAudioProcessingTap` to each item and keeps the last 8 seconds of loudness readings.
- **Risk:** the iOS 27 tap on the whole audio mix is new. Reports say older taps were unreliable on remote MP3 files and didn't work on HLS. If it gives no audio for some streams, those resume at the pause point, which is today's behavior.
