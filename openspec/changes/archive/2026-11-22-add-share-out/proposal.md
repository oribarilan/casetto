# Proposal

## Why

When an episode is good, you want to send it to a friend, often on WhatsApp, whatever podcast app they use, or none. Today Casterr can only export bookmarks. Sharing out gives a link anyone can open and a short clip that plays right in the chat with the show's art.

This isn't a roadmap milestone. It adds to Now Playing (M1), the show page (M5), and the sharing capability added with sharing to Casterr.

## What Changes

- **Share Episode:** from Now Playing and from episode rows on show pages. Queue rows already use long-press to reorder, and a Queue episode is one tap from Now Playing. It sends "Episode – Show" plus the episode's own web page from its feed, or the audio link when the feed has no page for each episode. From Now Playing it adds the time as text: "from 12:34". The share sheet shows the show's art.
- **Share Show:** from the show page. It sends the show's name and its web page, or its feed address.
- **Share Clip:** from Now Playing. A small editor shows the two minutes around now as loudness bars, with a 30-second clip framed around now. You drag its edges (5 to 60 seconds) and can preview it. Clips always play at normal speed, whatever speed you listen at. Edges snap to the nearest pause between words, like Back a Beat, so a clip doesn't cut off a word. Share makes a square video of the art Now Playing shows (the show's art, or the chapter's own picture) with the clip's audio and a small badge in the top left corner, nearly opaque: the app icon and "Clipped with Casterr", and sends it with the episode's text and link as the caption.
- **Streamed episodes:** Casterr fetches just the two minutes it needs, from the same address and with the same browser identity as the player, so ad-inserting shows return the same audio as closely as possible. When that can't work (an M4A, a variable-bitrate MP3, or a server that can't send part of a file), the editor asks you to download the episode first; offline, it says so.
- **Now Playing:** a share button at the top right opens a menu with "Share Episode" and "Share Clip…".
- Files in "Shared with Casterr" have no share actions. They have no link, and they're often someone's private voice note.
- `podcast_app_concept.md` gets "Sharing from Casterr" in its sharing section.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `sharing`: new requirements for sharing an episode, a show, and a clip.

## Out of scope

- Apple Podcasts links, and links that open another app at a time. No app documents a time link anyone can build, and shows that insert ads per app put different audio at the same time.
- pod.link and a Casterr web link. pod.link's terms rule out app-made links, and a Casterr link needs a domain and a server.
- Sharing a shared file, and clips of shared files.
- Clips longer than 60 seconds, the episode's text burned into the video, and moving waveforms in the video.
- Zooming the clip editor. It always shows the two minutes around now; to clip another moment, scrub there in Now Playing first.
- Sharing from the lock screen. iOS offers no share command there.

## Impact

- `CasterrCore`: the episode's and the show's web page from the feed (a new optional field on each cached record; the feed cache is local, so it migrates automatically), the share text, the clip window math with snapping to pauses, loudness bars from audio samples, and Back a Beat's gap finder shared with the editor.
- App: the share button and menu in Now Playing, Share Episode in episode rows, Share Show on the show page, and the clip editor with its fetch, preview, and video export.
- **Risks:**
  - Shows that insert ads per request can return different audio for a second request, so a streamed clip could be off by an ad's length. Matching the player's browser identity reduces this; a clip always comes from what the player is playing (the file when the file was loaded).
  - Fetching part of a file works for MP3s at a steady bitrate, which all five tested shows use. M4A files and servers without partial requests need the episode downloaded first.
  - The badge spreads the name Casterr before its trademark check. The listener chose that knowingly; changing it later is a one-line change, but clips already sent keep the old name.
  - Whether WhatsApp keeps the caption with a shared video needs a phone check. Without it, the video alone still shows the art.
