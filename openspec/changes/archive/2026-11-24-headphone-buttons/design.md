# Design

## Context

Casterr publishes Now Playing through Apple's `NowPlaying` framework. `NowPlayingBridge.commands` registers play, pause, toggle, skip forward 30, skip back 15, and seek. AirPods send a double press as `next` and a triple press as `previous`, and the framework has both (`MediaCommand.next`, `.previous`). The throwaway build registered both on the listener's iPhone (iOS 27.2), and the lock screen and Dynamic Island kept their 15 and 30 buttons.

Settings live in one `UserSettings` record that syncs through SwiftData's automatic CloudKit store. A new field with a default value needs no migration. `Library` is an actor with a getter and setter for each setting.

## Goals / Non-Goals

**Goals:**
- The choice applies on the next press, also right after a sync from another device.
- The footer text is built in `CasterrCore`, so the core tests cover every combination.

**Non-Goals:**
- No cache of the choices in `AppModel`. A press reads them from `Library`.
- No sound file in the bundle.

## Decisions

**A `ButtonAction` type in `CasterrCore/Player/ButtonAction.swift`.** It is an enum with `skipForward`, `skipBack`, and `bookmark`, a `String` raw value, the picker title, and a static `footer(double:triple:)`. The footer uses "skips forward 30", "skips back 15", and "bookmarks, with a chime". When both match, it says "Double and triple press" with the plural verb ("skip forward 30", "bookmark, with a chime"). It ends with "Other headphones and cars do the same with their next and previous buttons." Another option was to keep the text in the view, but then only a UI test could check the nine combinations.

**Two `String` fields on `UserSettings`.** `doublePress` defaults to `"bookmark"` and `triplePress` to `"skipBack"`. `Library` gets `buttonActions() -> (double: ButtonAction, triple: ButtonAction)` and `setButtonAction(_:forDoublePress:)`, using `changeSettings`, so `updatedAt` stamps the change. A raw value that the app doesn't know falls back to the default, so a newer device's choice can't break an older build. Another option was to store an `Int`, but the strings are easier to read in the CloudKit dashboard.

**A press reads the choice when it happens.** `NowPlayingBridge` takes one closure, `onButton: (Press) async -> Void`, where `Press` is `.double` or `.triple`. `.next` calls it with `.double` and `.previous` with `.triple`. `AppModel.button(_:)` reads `library.buttonActions()` and runs the action: `player.skipForward()`, `player.skipBack()`, or `bookmark()` followed by `Chime.play()`. Reading on each press costs one fetch and always sees synced changes. Another option was to cache the choices and refresh them on a settings change and after a sync, which needs more code.

**`bookmark()` returns whether it saved.** The chime plays only when a bookmark was saved, so a press with nothing loaded stays silent.

**The chime is generated in code.** `Casterr/Playback/Chime.swift` keeps the throwaway build's two-note sine WAV (880 Hz then 1320 Hz, about a quarter second), built once in memory and played with `AVAudioPlayer` at full volume. It uses the app's playback audio session, so it plays with silent mode on. The debug print goes.

**The Settings section uses `Picker` rows** in the default menu style, like Default speed, with a `SettingsSection.buttons` id so a link can open it.

## Risks / Trade-offs

- [A later iOS might show next and previous track buttons on the lock screen once `next` and `previous` are registered] → The device check covers the lock screen and Dynamic Island. If they change, drop the registration and report it.
- [The CarPlay Dashboard and car buttons weren't checked in the throwaway build] → Device check in the car. The worst case is that car buttons follow the choice, which matches the footer.
- [The toast only shows when Casterr is on screen] → The chime is the confirmation when it isn't. The bookmark still appears in the Bookmarks tab.
