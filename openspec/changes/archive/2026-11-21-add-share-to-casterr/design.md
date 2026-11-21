# Design

## Context

Casterr is one app target plus `CasterrCore`, built with XcodeGen. `Library` keeps two SwiftData stores: `FeedCache` (shows and episodes, local only) and `UserData` (subscriptions, episode state including Queue positions, settings, and bookmarks, synced through CloudKit when the app has a container). Episodes are keyed by `EpisodeKey(show:guid:audioURL:)`, which starts with the show key. The player plays `localFile(key, audioURL) ?? audioURL`, where `localFile` asks `DownloadStore`. `Directory` already calls Apple's lookup and search endpoints. `ShowView` assumes a followed show today. `AppModel.episodes(_:)` already skips Queue keys with no episode record, but `Library.queue().first` is still used to pick what plays next and to fill the up-next bar.

Tested against Apple's lookup on 2026-11-21:
- `lookup?id=<episode id>` returns nothing.
- `lookup?id=<show id>&entity=podcastEpisode&limit=200` returns the show (with `feedUrl`) and its recent episodes, each with `trackId`, `episodeGuid`, `episodeUrl`, and `trackName`.
- For ATP it returns the feed `https://cdn.atp.fm/rss/public?wtvryzdm`, which differs from `atp.fm/rss`.

## Goals / Non-Goals

**Goals:**
- The extension stays small: it accepts the item, validates it, writes a note to a drop folder, and shows the card. All library changes happen in the app.
- No change to where the existing stores live, and no migration.

**Non-Goals:**
- Background processing while Casterr isn't running. Items wait in the drop folder until the app runs.

## Decisions

**Share extension target `CasterrShare`.** It's a `app-extension` target with a SwiftUI view hosted in the extension's view controller. It depends on `CasterrCore` for link parsing and the lookup. Its activation rule accepts up to 10 attachments conforming to `public.audio` or the Ogg types (`org.xiph.ogg-audio`, `org.xiph.opus`, which WhatsApp and Telegram voice notes use and Apple's player plays, tested on macOS 27), and at most 1 `public.url`. It rejects other links in code, with the card. For a file, it checks `AVURLAsset.isPlayable` and reads the title tag, so the card can show the real title or say the file can't play. Bundle id `com.oribarilan.Casterr.Share`. It compiles `Casterr/Screens/CassyView.swift` (and the theme colors it needs) as part of its own sources, and uses Cassy's success face.
- Rejected: a document-type handler ("Open in Casterr"). Share sheets in WhatsApp and Telegram offer share extensions, and an extension can show the card.

**App Group `group.com.oribarilan.Casterr` with a drop folder.** The extension writes each item to `<group>/Inbox/<uuid>/`: `item.json` (kind, title, and for links the feed URL, episode GUID and episode audio URL; for files the original file name) plus, for files, the audio file itself. It writes `item.json` last, so the app ignores half-written folders. Then it posts a Darwin notification, `com.oribarilan.Casterr.shared`. The App Group goes in the simulator entitlements file, in a new device entitlements file with only the App Group (`Casterr/Casterr-Device.entitlements`, set as `CODE_SIGN_ENTITLEMENTS[sdk=iphoneos*]`; the iCloud file keeps its placeholder container and stays unused on device), and in the extension's own entitlements file.
- Rejected: moving the SwiftData stores into the App Group so the extension writes directly. That means migrating the existing stores and CloudKit setup, and two processes writing one store.

**Links are resolved in the extension, episodes are queued in the app.** The extension parses `podcasts.apple.com/.../id<show>?i=<episode>`, calls `Directory.episodes(ofShow:)` (new, the lookup above), and finds the `trackId`. That gives the card the real title, and lets it report "not found" or "couldn't reach Apple Podcasts" honestly. The app then:
1. Looks in the feed cache for an episode key ending in `|guid:<episodeGuid>`. If one exists, from any followed show, it uses that.
2. Otherwise it fetches the feed with `FeedFetcher`, saves it with `Library.saveFeed(_:for:)` under `ShowKey(feedURL:)` without a subscription, records the feed address on the `ShowRecord` (a new optional `feedURL`, so Subscribe works later; the feed cache is local, so adding an optional field migrates automatically), and finds the episode by GUID, falling back to the audio URL.
3. It places the episode in the Queue with the Play next reason.

If the episode still isn't in the feed, the app drops the item and logs it. The card already said "Added" in that rare case. That's accepted rather than adding app-to-extension messaging.

**Shared files in the app.** On pickup, the app moves the file to `Application Support/Shared/<stem>.<ext>`, excluded from backup, where `<stem>` is the SHA-256 of the episode key, like `DownloadStore`. The episode's key uses the built-in show key `casterr:shared` and the guid `shared-<uuid>`. Its `audioURL` is `casterr-shared:///<stem>.<ext>`, a stable address independent of the app container's path, which can change across restores. A `SharedStore`, a sibling of `DownloadStore`, resolves it to the file, and the player's `localFile` closure asks it first. Title and duration come from `AVURLAsset` (`commonIdentifierTitle`, `load(.duration)`), read again in the app. There's no per-episode art: the built-in show's `artworkURL` points to a Cassy PNG that the app renders once from `CassyView` with `ImageRenderer` into `Application Support/Shared/cassy.png`, so every place that shows show art (lists, mini player, Now Playing, lock screen, CarPlay) shows Cassy with no other change.

**The built-in show.** A `ShowRecord` with key `casterr:shared` and title "Shared with Casterr", created on the first shared file and kept in `FeedCache`, so it never syncs. It has no `Subscription`. The Shows grid lists it after the followed shows when it has at least one episode. `FeedService` refresh never sees it, because refresh walks subscriptions. Played shared episodes move to the archive like any episode and stay listed on its page. `ShowView` checks for the built-in key and shows a Delete action on each row (swipe and context menu) instead of the new-episode settings, and hides the Unsubscribe menu. `Library.wipeFeedCache()` keeps the built-in show and its episodes, since they can't be fetched again. Delete removes the file, the art, the `EpisodeRecord`, and the `EpisodeState` (leaving the Queue).

**Pickup.** `SharedInbox` (app) scans the drop folder when the scene becomes active and when the Darwin notification arrives. It processes folders that have `item.json`, oldest first, and deletes each folder after it's imported. It runs on the main actor through `AppModel.change`, so screens reload.

**Queue limited to known episodes.** `Library.playableQueue()` returns `queue()` without keys whose `EpisodeRecord` is missing from the feed cache. The records and the states are in different stores, so it's two fetches and a set lookup. Moves from the Queue screen go through `movePlayable(_:to:)`, which turns a position in the playable list into the matching position in the full one. The Play next position counts from the first episode this device has, so a hidden item 1 doesn't push Play next above the visible Now Playing. The Queue screen, the up-next bar, downloads, CarPlay, and `Player` (resume and what plays next) use it. `queue()` keeps the full order, so moves, merges and storage tests are unchanged.

**Downloads skip shared files.** The download sync leaves episodes of the built-in show out of its plan. Shared episodes are already local.

**Subscribe on an unfollowed show's page.** The show name in Now Playing already opens any show's page. `ShowView` shows a Subscribe button (the app's word for following) in place of the new-episode settings row, and hides Unsubscribe, when there's no subscription and the show isn't the built-in one. It calls the same path as subscribing from the directory, with the `feedURL` recorded on the `ShowRecord`. `subscribe` places the newest episode by the level as today. The shared episode keeps its Queue place, because "one place per episode" already holds it there.

**Bookmarks on shared files.** Bookmarking works as usual and the bookmark syncs. The Bookmarks list disables a bookmark's play button when its audio URL uses `casterr-shared:` and `SharedStore` has no such file.

**The confirmation card.** A SwiftUI view in the extension: `CassyView` (success face), the message, and the title. Accepted items call `completeRequest` after 1.5 s. Errors show a Done button. Text:
- Accepted: "Up next in your Queue".
- Wrong kind: "Casterr takes audio files and Apple Podcasts episode links."
- Unplayable file: "Casterr can't play this kind of audio file."
- Not found: "Casterr couldn't find that episode on Apple Podcasts."
- Offline: "Casterr couldn't reach Apple Podcasts. Check your connection and share again."

## Risks / Trade-offs

- [A share extension has tight memory limits] → It copies files with `FileManager` (no loading into memory) and does one lookup request. Feeds are fetched in the app.
- [Apple's lookup lists only the most recent 200 episodes] → Older episodes get the "not found" card.
- [The app is suspended in the background while playing, so the Darwin notification may wait] → A playing app runs and receives it. A suspended one picks items up when it comes to the front. That meets "next opens or comes to the front".
- [The App Group needs registering for device builds] → Automatic signing with `-allowProvisioningUpdates` registers it. The team ID stays on the command line.
- [A shared file's `EpisodeState` still syncs to other devices] → Those devices skip it through the Queue filter. It's a small invisible record.
- [UI-testing a share extension is awkward] → Core tests cover link parsing, GUID matching, the built-in show and the Queue filter. A UI test feeds the drop folder directly through a `-uiTesting` launch hook that copies a fixture into the inbox. The share sheet itself is a phone check.
