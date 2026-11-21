# Proposal

## Why

On many podcasts one voice is much quieter than another: a caller, a remote guest, a host far from the microphone. In the car or on the street you keep reaching for the volume. Voice boost evens out loud and quiet voices, so every voice is easy to hear.

This isn't a roadmap milestone. It's an item from the "After the MVP" list and adds to the player from M1. The listener heard real clips with it off and on, including an episode of וויקלי סינק, and approved the sound.

## What Changes

- **Voice boost:** while it's on, Casterr turns loud passages down and raises the whole level, so quiet voices come up and loud ones come down. It uses Apple's dynamics processor with the settings the listener approved by ear.
- It works the same for downloaded and streamed episodes. Turning it on or off takes effect right away while playing, with no pause or skip.
- **Default and per-show override, like speed:** Settings gets a Voice boost switch in the Playback section, under Default speed. It's off by default. A show without its own choice follows the default.
- **Now Playing:** a fourth round button with a waveform symbol, white while boost is on. Tapping it opens a menu like the sleep timer's, titled "Voice boost: evens out loud and quiet voices", with "On for this show", "Off for this show", and "Use my default (Off)" or "(On)".
- Back a Beat keeps measuring the audio before the boost, so it finds the same gaps either way.
- `podcast_app_concept.md` gets a Voice boost bullet in the Player section, and voice boost leaves the "After the MVP" list.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `playback`: new requirements for voice boost and for its default and per-show override.
- `settings`: the global defaults include voice boost.

## Out of scope

- Skip silences. It's parked in `BACKLOG.md`.
- A strength setting. Voice boost is on or off.
- A ceiling that stops peaks from reaching full scale. In testing only 4 samples of a whole episode reached it, which is inaudible.
- Setting voice boost from the show page. It lives in Now Playing, like speed.
- Fading between off and on. The switch is immediate.

## Impact

- `CasterrCore`: user data gains an optional voice boost choice on `Subscription` and a voice boost default on `UserSettings`. Both are optional or defaulted, so CloudKit sync needs no migration and the existing merge rules cover them. `Library` gets the read and write methods, and `Player` applies the effective choice when an episode starts and when a choice changes. `AudioEngine` gains one method.
- App: the audio tap that measures loudness for Back a Beat also runs the dynamics processor when boost is on. Now Playing gets the new button and menu, and Settings gets the switch.
- **Risk:** running an audio unit inside the tap is new to this app. If the dynamics processor can't be set up for an item's audio format, that item plays without boost, as it does today.
