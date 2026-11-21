# Proposal

## Why

Good audio doesn't only come from feeds you follow. A friend sends a voice memo or an MP3 on WhatsApp, or an Apple Podcasts link to one episode they loved. Today there's no way to get either into Casterr. Sharing to Casterr puts it next in the Queue, right after what's playing.

This isn't a roadmap milestone. It adds to the Queue (M1) and to subscriptions and discovery (M5).

## What Changes

- **A Casterr share extension:** Casterr appears in the share sheet of other apps for audio files (MP3, M4A, WhatsApp and Telegram voice notes, and other audio Apple's player plays) and for Apple Podcasts episode links.
- **Shared audio files:** Casterr keeps its own copy and plays the episode next: right after Now Playing, or first when the Queue is empty, like Play next. Its title comes from the file's title tag, or else the file name. Every shared file shows Cassy as its art. You can bookmark a shared file; the bookmark syncs, but only this phone can play it.
- **"Shared with Casterr":** a built-in show for shared files. It appears in the Shows grid once you've shared a file, and its page lists every shared file, newest first. A file stays until you delete it on that page. The show can't be followed or unfollowed, has no new-episode settings, and never refreshes.
- **Apple Podcasts episode links:** Casterr finds the show's feed and that episode through Apple's lookup API, which search already uses, and plays it next. The show isn't followed. If you already follow the show, the episode is the one you already have. The show's page offers Subscribe for a show you don't follow.
- **The confirmation:** a small card with Cassy, "Up next in your Queue" and the episode's title, which closes by itself after about 1.5 seconds. When Casterr can't take what was shared, or can't play the file, the card says why and waits for Done.
- **This phone only:** shared files exist only on the phone you shared them to. A device's Queue shows only episodes that device has, so a shared file, or an episode of a show you don't follow, queued on one device doesn't appear on the others.
- `podcast_app_concept.md` gets a "Sharing to Casterr" section, a "Shared with Casterr" row in its data table, and "Delete" in the Words table covers shared files too.

## Capabilities

### New Capabilities

- `sharing`: the share extension, shared audio files, the built-in show, Apple Podcasts links, and the confirmation card.

### Modified Capabilities

- `queue`: a device's Queue shows only the episodes it has.
- `show-page`: the page of a show you don't follow offers Subscribe.

## Out of scope

- Links to audio files on the web, and links from other podcast apps (Overcast, Pocket Casts, Spotify).
- Video, YouTube, and web pages.
- Syncing shared files, or showing them as unavailable on other devices.
- Choosing where a shared episode lands. It always plays next.
- Sharing several files at once. Casterr takes the first audio file.
- A shared file's own embedded picture. Every shared file shows Cassy.
- Editing a shared file's title.
- Opening Casterr from the share sheet. iOS doesn't allow a share extension to open its app.

## Impact

- Project: a new share extension target, and an App Group shared by the app and the extension. Device builds get an entitlements file with only the App Group, since the iCloud one still has a placeholder container. The team ID stays out of `project.yml`.
- `CasterrCore`: parsing an Apple Podcasts link, the lookup of a show's episodes, finding an episode by GUID across followed shows, the built-in show and its episodes in the feed cache, deleting a shared episode, a feed address on cached shows, and a playable Queue limited to episodes this device has (with moves and Play next counted in it).
- App: picking up shared items from the App Group when the app opens, comes to the front, or gets a signal from the extension; copying files into app storage; reading a file's title and duration; the built-in show's page with Delete; Subscribe on the page of a show you don't follow; and a disabled play button on bookmarks whose shared file isn't on this device.
- **Risks:**
  - Apple's lookup lists only a show's most recent 200 episodes, so an older episode can't be found. The card then says so.
  - Apple's feed address can differ from the one you follow (ATP's lookup gives `cdn.atp.fm/rss/public…`, not `atp.fm/rss`). Matching by GUID across followed shows avoids queuing a duplicate.
