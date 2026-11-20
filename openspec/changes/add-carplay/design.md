# Design

## Scene

A `CPTemplateApplicationScene` is declared in the Info.plist scene manifest through `project.yml`. Its delegate, `CarPlaySceneDelegate`, sets a `CPListTemplate` as the root when the car connects and drops it when the car disconnects. The app may start on the car screen alone, so the delegate gets the shared `AppModel` and `Player` without needing the phone window. Whether the SwiftUI app needs an app delegate for this is checked in the simulator first; the manifest alone is the plan.

## Queue list

The list rebuilds from `Library.queue()` when the Queue or the playing episode changes, through the same `revision` and player observation the phone uses. Each `CPListItem` shows the episode title, the show title, and the show art, and marks the playing episode with `isPlaying`. Some cars cap lists at 12 items, so the list stops at `CPListTemplate.maximumItemCount`. The empty state uses the template's empty-view text.

## Now Playing

`MediaSession` from the NowPlaying framework already drives the lock screen. Apple says it keeps the system's Now Playing surfaces current, which should include CarPlay. That is confirmed in the simulator before building on it. If it isn't true, the fallback is to feed `CPNowPlayingTemplate` through MediaPlayer, recorded here with the reason.

`CPNowPlayingTemplate.shared` gets two buttons when the scene connects:

- A `CPNowPlayingImageButton` with the `bookmark` symbol calls `AppModel.bookmark()`, then swaps to `bookmark.fill` for 2 seconds through `updateNowPlayingButtons`.
- A `CPNowPlayingPlaybackRateButton` sets the show's override to `PlaybackSpeed.next` and reloads the player's speed.

The iOS 27 mini player stays on (the default).

## Entitlement

`com.apple.developer.carplay-audio` goes in a simulator-only entitlements file through `CODE_SIGN_ENTITLEMENTS[sdk=iphonesimulator*]`. Device builds stay unchanged until Apple approves the entitlement, so installing on the phone keeps working.

## Testing

`PlaybackSpeed.next` gets unit tests. XCUITest can't drive CarPlay templates, so the template code is checked by hand in the iOS Simulator's CarPlay display, with screenshots. The real-car check goes to the device checklist.
