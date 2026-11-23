## Why

Three problems the listener found sharing from the phone (backlog: "Sharing fixes"):

1. The share text carries more than the names: "718: The Warp Zone – Accidental Tech Podcast, from 12:34". The listener wants only the episode and show names.
2. The art in a shared clip looks low quality. Testing found the clip file itself sharp: it looks great in Messages, and the show's art encoded on a Mac with the same Apple encoder stays crisp at the default settings. WhatsApp re-compresses videos heavily, even in HD, which is where the blur comes from. Shows can also have art smaller than the video, which today is scaled without smoothing.
3. Share Episode links to the episode's page from its feed, or its audio file. The listener wants a link that opens the episode in whatever podcast app the reader uses, and picked Podlink.

This is not a roadmap milestone. It is a fix from daily use after the MVP.

## What Changes

- **BREAKING:** the share text is "Episode – Show" everywhere: Share Episode from a row or Now Playing, and a clip. The "from 12:34" goes away.
- Share Episode and clips link to the episode on Podlink, `https://pod.link/<feed>/episode/<episode>`, where both parts are URL-safe base64: the show's current feed address and the episode's GUID. Podlink builds a page from the feed with no sign-up, and lets the reader pick a podcast app. An episode with no GUID links to the show on Podlink. Shared files still offer no share.
- A clip goes out with the same text and link.
- Share Show links to the show on Podlink, `https://pod.link/<feed>`, so every share opens in the reader's podcast app.
- Art smaller than the 1080 by 1080 video is scaled smoothly. A higher bitrate was tried and dropped: Apple's encoder gave the still picture no more detail. WhatsApp's compression is logged in the backlog for a later experiment.

Calls made while writing this, open to correction: the base64 has no `=` padding, which Podlink doesn't document and a device check confirms; the feed form of Podlink links needs no Apple ID lookup.

Out of scope: a time in the link, and the waveform in clips (its own backlog entry).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `sharing`: the share text drops the time, episode, clip and show links are Podlink's, and the clip's art stays sharp.

## Impact

- `CasterrCore/Sources/CasterrCore/ShareText.swift`: the text without the time, and the Podlink link from the feed address and GUID. Core tests.
- `EpisodeKey`: a way to read the GUID it was built from.
- `ShowArt` gains the show's current feed address, so rows can build the link with no extra lookup.
- `ClipEditor.swift`: smooth scaling for small art.
- UI tests that check the share text.
- `BACKLOG.md`: the "Sharing fixes" entry is removed.
