# Design

## Context

Back a Beat added `LoudnessTap`: an `MTAudioProcessingTap` attached to each item's audio track after the item is ready, before the speed change (PreEffects), keeping recent loudness readings in a fixed ring buffer. Its callbacks run on a real-time audio thread, so they never allocate or touch actors. An audio track takes one tap, so voice boost must live in the same tap.

Speed already has the shape voice boost needs: `UserSettings.speed` is the global default, `Subscription.speedOverride` is an optional per-show value, `Library.effectiveSpeed(for:)` combines them, and `Player.reloadSpeed()` reapplies after a change. User data follows the CloudKit rules (every property optional or defaulted), and sync merges whole records.

The sound was settled by ear on real clips, rendered offline with the same Apple audio unit this design uses (see proposal.md, Why).

## Goals / Non-Goals

**Goals:**
- One tap per item that measures loudness for Back a Beat, then boosts when asked.
- Switching on or off without rebuilding the audio mix, so it's instant.
- Voice boost settings that mirror speed's code paths, so there's nothing new to learn.

**Non-Goals:**
- Unit-testing the sound itself. The tested values come from listening, and a phone listening check covers them.

## Decisions

**Apple's dynamics processor inside the tap.** The tap sets up `kAudioUnitSubType_DynamicsProcessor` in its prepare callback, for the tap's processing format, and tears it down in unprepare. The process callback fetches the source audio, measures loudness, and then, when boost is on, renders the dynamics processor over the same buffers. The values are constants next to the tap: threshold −38 dB, headroom 3 dB, attack 3 ms, release 300 ms, overall gain +24 dB, expansion ratio 1 (off).
- Rejected: our own leveler in `CasterrCore`. It would be unit-testable, but we'd own the sound quality, and a homemade leveler tends to make background noise rise and fall. Apple's unit already sounded right to the listener.
- Rejected: our own audio pipeline (`AVAudioEngine`). It would allow audio effects natively, but it's a rewrite of playback and streaming.
- Rejected: iOS's Enhance Dialogue. iOS turns it on only for movie playback on some hardware, and the listener controls it in Control Center, not per show.

**Measure first, then boost.** Loudness readings come from the source audio before the dynamics processor runs, so Back a Beat's gaps and threshold don't change with boost on.

**One tap, renamed `AudioTap`.** It now does two jobs, so `LoudnessTap` becomes `AudioTap`. The loudness ring buffer stays as it is.

**An atomic on/off flag, read on each callback.** `AudioTap` holds an `Atomic<Bool>` from the Synchronization library. The engine sets it and the audio thread reads it, with no lock and no rebuild of the audio mix. When the flag turns on, the callback resets the audio unit so it starts without the previous envelope. The engine remembers the flag, so each new item's tap starts in the right state.

**Unsupported format means no boost.** If the tap's format isn't 32-bit float, or the audio unit won't accept the format, the tap still measures loudness and the audio passes through untouched.

**Data mirrors speed.** `UserSettings.voiceBoost: Bool = false` and `Subscription.voiceBoostOverride: Bool?`, with nil following the default. `Library` gets `globalVoiceBoost()`, `setGlobalVoiceBoost(_:)`, `voiceBoostOverride(_:)`, `setVoiceBoostOverride(_:to:)`, and `effectiveVoiceBoost(for:)`. Both fields are optional or defaulted, so CloudKit needs no migration and the whole-record merge rules already cover them.

**Player.** `Player` gets `public private(set) var voiceBoost: Bool`, set from `effectiveVoiceBoost` when an episode starts, and `reloadVoiceBoost()`, which re-reads it after a choice changes, like `reloadSpeed()`. `AudioEngine` gains `func setVoiceBoost(_ on: Bool)`. Tests use `FakeEngine`.

**Now Playing menu.** A `VoiceBoostMenu` built like `SleepTimerMenu`: a `Menu` whose label is the `waveform` SF Symbol in a round control, white (`roundControl(on:)`) while `player.voiceBoost` is true. The menu's title is "Voice boost: evens out loud and quiet voices". Its items are "On for this show", "Off for this show", and "Use my default (Off)" or "(On)", with a checkmark on the current choice. It reads the show's choice and the default when it opens. VoiceOver reads "Voice boost" with a value such as "On, for this show" or "Off, your default". The row becomes speed, voice boost, bookmark, and sleep timer.

**Settings.** A "Voice boost" toggle in the Playback section, under Default speed. It saves the default and calls `player.reloadVoiceBoost()`. The footer becomes "A show can have its own speed and voice boost from Now Playing."

**A debug log line to verify it runs.** When boost turns on, the engine logs the dynamics processor's read-only compression amount, at debug level in the existing "backABeat" logger category renamed to "audioTap". It proves the unit runs on the simulator without listening.

## Risks / Trade-offs

- [The dynamics processor refuses the tap's format on some streams] → Those episodes play unboosted, and the debug log says so. Back a Beat is unaffected.
- [The tap gets no audio for some streams, as reported for HLS] → No boost and no Back a Beat on those, which is today's behavior.
- [Turning boost on jumps the level by several dB at once] → The spec asks for an immediate switch. A short fade can come later if it bothers the listener.
- [Rendering an audio unit on the tap's thread] → The dynamics processor is real-time safe. Setup and teardown happen in prepare and unprepare, not in process.
- [+24 dB gain on an already loud show] → In testing on וויקלי סינק, only 4 samples reached full scale, which is inaudible.
