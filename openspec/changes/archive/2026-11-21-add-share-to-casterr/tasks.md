# Tasks

## 1. Core

- [x] 1.1 Add Apple Podcasts link parsing (show id and episode id from `podcasts.apple.com/<country>/podcast/<slug>/id<show>?i=<episode>`, nil for anything else) and `Directory.episodes(ofShow:)` with a lookup fixture; verify with unit tests for a valid link, a show link without `i=`, a non-Apple link, and decoding feed URL, GUID, audio URL and title from the fixture
- [x] 1.2 Add `Library.playableQueue()`, the Queue limited to episodes in the feed cache, and use it for the Queue screen, the up-next bar, downloads, CarPlay, and choosing what plays next (`queue()` keeps the full order for storage); verify with storage tests that an unknown key is skipped, the others keep their order, and `Player.resume()` starts the first known episode
- [x] 1.3 Add the built-in show (`casterr:shared`, "Shared with Casterr"): adding a shared episode with title, duration and `casterr-shared:` audio URL as Play next, listing them newest first, deleting one (episode record and state), keeping it through `wipeFeedCache()`, `movePlayable(_:to:)`, and Play next counted from the first known episode; verify with storage tests, including that the built-in show never appears in subscriptions, a share lands right after Now Playing, and moves and Play next skip hidden items
- [x] 1.4 Add queuing a looked-up episode: reuse an existing episode with the same GUID from any show, else save the fetched feed without subscribing (recording its feed address on the show) and find the episode by GUID or audio URL, then place it as Play next; verify with tests for the reuse case (different feed address), the new-show case (show stays unfollowed), and not found (nothing changes)

## 2. Extension and pickup

- [x] 2.1 Add the App Group to the simulator entitlements, a new device entitlements file with only the App Group, and the `CasterrShare` extension target with its own entitlements in `project.yml`; verify the app and extension build for the simulator and a device build signs with automatic provisioning (simulator verified; the device build needs an Apple account in Xcode, so that check moved to `openspec/device-checks.md`)
- [x] 2.2 Build the extension: accept the first audio file or an Apple Podcasts link, copy or resolve it, write the drop folder note last, post the Darwin notification, and show the confirmation card with the five messages (checking a file plays and reading its title tag); verify in the simulator by sharing an MP3 and an Ogg Opus voice note from Files and an Apple Podcasts link from Safari, and checking the drop folder contents and the card
- [x] 2.3 Build `SharedInbox` and `SharedStore` in the app: pick up on becoming active and on the notification, copy files into `Application Support/Shared`, read title and duration, render Cassy as the built-in show's art, queue them, and resolve `casterr-shared:` URLs for the player; skip non-http URLs in `Downloader`; verify with a UI test that uses a `-uiTesting` hook to place a fixture file in the drop folder, then sees it first in the Queue with its tag title, and plays it

## 3. Screens

- [x] 3.1 Show "Shared with Casterr" in the Shows grid and its page with Delete on each row; verify with a UI test that the show appears after a share, Delete removes the episode from the page and the Queue, and the file is gone
- [x] 3.2 Add Subscribe to the page of a show you don't follow and hide Unsubscribe there and on the built-in show; disable a bookmark's play button when its shared file isn't on the device; verify with a UI test that queues an ATP episode through the drop-folder hook, opens its show from Now Playing, subscribes, and sees the new-episode settings
- [x] 3.3 Run all core and UI tests; add a "Sharing to Casterr" section, a data-table row, and shared files to the "Delete" row of the Words table in `podcast_app_concept.md`; add phone checks to `openspec/device-checks.md` (share from Files, WhatsApp, and Telegram; an Apple Podcasts link from Messages; sharing while Casterr plays; and a second device not showing shared files)

## Workflow follow-up

- Archive the change after the listener approves the result, then run `openspec validate --specs --strict`.
