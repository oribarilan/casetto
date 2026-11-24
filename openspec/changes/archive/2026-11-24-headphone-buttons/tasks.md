# Tasks

## 1. Core

- [x] 1.1 Add `ButtonAction` with titles and `footer(double:triple:)`, with tests for the defaults, a changed press, and both presses the same
- [x] 1.2 Add `doublePress` and `triplePress` to `UserSettings` and the `Library` getter and setter, with tests for the defaults, a change, `updatedAt`, and an unknown stored value

## 2. App

- [x] 2.1 Replace the throwaway code: `NowPlayingBridge` takes `onButton`, `next` and `previous` send `.double` and `.triple`, and `AppModel.button(_:)` runs the chosen action
- [x] 2.2 Make `bookmark()` return whether it saved, play the chime only then, and remove the chime's debug print
- [x] 2.3 Add the Headphone and car buttons section after Playback, with the two pickers and the footer, and a UI test that changes Triple press and reads the footer

## 3. Docs and version

- [x] 3.1 Add the Player line to `podcast_app_concept.md`
- [x] 3.2 Set `MARKETING_VERSION` to 0.3 and add the 0.3 section to `CHANGELOG.md`
- [x] 3.3 Add the phone checks (AirPods presses, lock screen and Dynamic Island, silent mode, car buttons and CarPlay Dashboard, sync to another device) to `openspec/device-checks.md`
- [x] 3.4 Run the core and UI tests, and install on the phone
