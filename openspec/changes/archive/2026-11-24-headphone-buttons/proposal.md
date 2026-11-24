# Proposal

## Why

The listener wants to bookmark a moment without taking out the phone: while walking with AirPods in, or while driving, where the CarPlay screen has no Bookmark button. A throwaway build on the listener's iPhone showed that AirPods double and triple presses reach Casterr as the next and previous commands, that the lock screen and Dynamic Island keep their 15 and 30 buttons, and that a chime plays with silent mode on.

This is after-MVP work, not a numbered roadmap milestone.

## What Changes

- A new Settings section, "Headphone and car buttons", right after Playback, with two pickers: Double press and Triple press. Each offers Skip forward 30, Skip back 15, and Bookmark. The defaults are Bookmark for double press and Skip back 15 for triple press.
- The section's footer says what each press does now and that other headphones and cars do the same with their next and previous buttons.
- Casterr answers the next and previous commands with the chosen action. Wired EarPods, other headphones, and car buttons that send next and previous follow the same choices.
- A bookmark from a button saves like the Now Playing Bookmark, keeps playing, and plays a short chime that sounds even with silent mode on.
- The two choices are settings, so they sync with the other settings.
- The concept's Player section gets a line for this.
- The throwaway build's code is replaced.

## Out of scope

- Single press and press and hold. iOS keeps those (play and pause, and noise control or Siri).
- Other actions, such as next chapter or speed.
- Changing the skip lengths. They stay 30 and 15.
- A setting for the chime. It always plays for a button bookmark.
- Casterr's own CarPlay screen, which still waits for Apple's entitlement.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `playback`: a new requirement for what the next and previous commands do, including the chime for a bookmark.
- `settings`: a new requirement for the Headphone and car buttons section, its choices, defaults, and footer.

## Impact

- `CasterrCore`: `UserSettings` gets two fields with defaults (no migration; they sync with CloudKit like the other settings). A small `ButtonAction` type with the footer text, tested in the core tests.
- `Casterr/Playback/NowPlaying.swift`: registers next and previous, and runs the chosen action.
- `Casterr/AppModel.swift` and a chime player in `Casterr/Playback/`.
- `Casterr/Screens/SettingsView.swift`: the new section.
- `project.yml` and `CHANGELOG.md`: version 0.3.
- `podcast_app_concept.md`: one line in Player.
