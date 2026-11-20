# Proposal

## Why

Much of podcast listening happens in the car. Casterr's idea is that you decide at home and the app just plays, so the car needs only the Queue and a good Now Playing screen.

## What Changes

- **Queue in the car:** one list, the Queue in play order, with episode title, show title, and art. Tapping an episode plays it and opens Now Playing. An empty Queue says so, without telling the driver to use the phone (Apple's CarPlay rule). No triage, Inbox, Shows, or Bookmarks in the car.
- **Now Playing in the car:** play, pause, skip back 15, skip forward 30, plus two buttons:
  - **Bookmark:** saves the moment without a note. The icon fills for 2 seconds to confirm.
  - **Speed:** each tap adds 0.1x, from 2.0x back to 1.0x. The new speed becomes the show's own speed, the same as setting it on the phone.

## Capabilities

### New Capabilities

- `carplay`: the car's Queue list and Now Playing screen.

## Out of scope

- Inbox, Shows, Bookmarks, search, and voice control in the car.
- The sleep timer in the car.
- Playback progress bars on the car's Queue rows.

## Impact

- `CasterrCore`: `PlaybackSpeed.next`.
- App: a CarPlay scene delegate, the scene manifest in `project.yml`, and a simulator-only CarPlay entitlement.
- **Apple approval:** running in a real car or the CarPlay Simulator needs the CarPlay audio entitlement. The listener requests it at developer.apple.com/carplay. Apple gives no timeline; reports range from days to weeks.
