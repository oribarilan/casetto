# Design

## Split

The decision lives in `CasterrCore`, where it can be unit tested. The audio work lives in the app's `AVPlayerEngine`.

- `AudioEngine` gets one method: `loudness(from:to:) -> [Loudness]`, the readings the engine heard in that stretch of media time. An empty array means "not available". The test fake returns fixture readings.
- `Loudness` is a value type: a media time and an RMS level, one per 10 ms of audio.
- `BackABeat.resumePoint(pausedAt:readings:) -> TimeInterval` is a pure function. It returns the pause point when it finds no gap.

## Finding the gap

Take the readings from `pausedAt - 5` to `pausedAt - 2`. The reference level is the median RMS of that stretch, so a quiet show and a loud show are judged the same way. A gap is a run of at least 150 ms where every reading is below 20% of the reference (about 14 dB down). The resume point is the middle of the latest gap, clamped to 0 or later.

Tuning (task 2.3) used about 13 minutes each of three episodes: solo talk (The Bible in a Year), an interview (The Ezra Klein Show), and voices over music (The Daily), with a simulated pause every 5 seconds. With these values a gap is found on 84%, 87%, and 79% of pauses. Shorter minimums find more gaps but also catch the silences inside words from stop consonants (p, t, k), which are usually under about 130 ms; pauses between phrases are usually longer. Apple's on-device speech recognizer was tried as ground truth for word boundaries, but its word timings swallow 40 to 70% of real silences of 200 ms or more, so it can't score the resume points. Whether the result feels right is a listening check on the phone.

## Player

`pause()` sets a `pausedInPlace` flag. `seek(to:)` (which the skip buttons use) and `start(_:)` clear it, so a seek, a skip, or a new episode turns Back a Beat off. `resume()` uses Back a Beat only while the flag is set, with the current position as the pause point, then clears it. Interruptions and the sleep timer already go through `pause()` and `resume()`, so they get it for free. A relaunch resumes through `start(_:)`, which has no readings, so it resumes at the saved position.

## Audio tap

When an `AVPlayerItem` is ready to play, the engine loads its audio track and gives the item an `AVAudioMix` with an `MTAudioProcessingTap` on that track, made with the `PreEffects` flag. PreEffects means the tap sees audio before the speed change, so its timestamps are media time at any speed.

The process callback runs on a real-time thread. It computes one RMS per 10 ms and writes it, with its media time from the source time range, into a ring of 800 slots (8 seconds). The ring is a struct inside an `OSAllocatedUnfairLock`, with fixed arrays; no actor or main-actor code runs in the callback, and nothing allocates there.

When the source time jumps, the ring drops only the readings at or after the new time. Readings are keyed by media time, so earlier ones stay true. This matters because a pause makes AVPlayer render the last tenth of a second again; clearing the whole ring there would lose everything Back a Beat needs.

`AVPlayerEngine.pause()` reports `currentTime()` right away, because the periodic time can be a second old and Back a Beat needs the exact pause point.

This is one path for downloaded and streamed episodes. Checked in the simulator (task 2.1): a downloaded MP3 and a streamed MP3 both fill the ring. The iOS 27 tap on the whole mix (`AVAudioMixInputParametersTrackMixID` with `MTAudioProcessingTapCreateWithPreferredFormat`) was created and attached but never received audio in the simulator, so it was dropped for the per-track tap. HLS items usually have no loadable audio track (not checked); without one they get no tap and resume at the pause point. None of the top 100 US shows use M4A enclosures, so M4A was not checked.

AirPlay buffers ahead, so the tap can hear audio before the listener does. The readings are keyed by media time and the pause point is the player's media time, so the stretch is still the right one.

## Rejected

- A ranged HTTP fetch of the seconds before the pause: mapping time to bytes is unreliable for VBR MP3, and it spends data on audio already played.
- Reading AVPlayer's cache: no public API.
- `AVPlayerItemSampleBufferOutput`: HLS only.
- Replacing AVPlayer with AVAudioEngine or a resource loader: a large rewrite of buffering, seeking, and background playback.
- Speech recognition for word boundaries: heavier, and loudness should be enough.
