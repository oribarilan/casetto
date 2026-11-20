# Tasks

Parked in the backlog (2026-11-20). The code builds and ships inert; 2.1 to 2.3 wait for a check in the simulator's CarPlay display, and real cars wait for Apple's CarPlay audio entitlement. Known bug to fix first: `templateApplicationScene(_:didDisconnect:)` matches no protocol method (the build warns), so disconnect never runs; the Swift name is `didDisconnectInterfaceController:`.

## 1. Core

- [x] 1.1 Add `PlaybackSpeed.next` (adds 0.1x, wraps from 2.0x to 1.0x), with tests

## 2. CarPlay

- [ ] 2.1 Add the scene manifest and simulator-only entitlement in `project.yml`; confirm the CarPlay display connects in the iOS Simulator and a phone build still installs
- [ ] 2.2 Build `CarPlaySceneDelegate` with the Queue list: titles, art, the playing marker, the item cap, the empty state, and live updates; check in the simulator
- [ ] 2.3 Confirm `MediaSession` drives the car's Now Playing; add the Bookmark and Speed buttons with the 2-second filled icon; check in the simulator
- [ ] 2.4 Run all core and UI tests; add the real-car check to `openspec/device-checks.md`
