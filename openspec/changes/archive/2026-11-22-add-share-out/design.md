# Design

## Context

`FeedParser` (FeedKit) reads each item's title, GUID, enclosure, date, duration and description, but not its `<link>`, and not the channel's `<link>`. `EpisodeRecord` and `ShowRecord` live in the local feed cache. Now Playing is a sheet with no toolbar. `EpisodeRow` is used in the Queue, the Inbox and show pages. `ShareLink` is already used for the Markdown and OPML exports. Downloaded files come from `DownloadStore.localFile`; streamed episodes play from their audio URL.

A helper measured these on 2026-11-21:
- 12 of 14 real feeds give every recent item its own `<link>`. Two NYT shows point every item at the show page.
- All 5 tested audio servers answer HTTP range requests with 206, and all 5 files were constant-bitrate MP3s.
- Cutting a 45-second clip of a local MP3 with `AVAssetExportSession` takes 0.13 to 0.25 s on a Mac.
- A 1080×1080, 1 fps H.264 plus AAC video of a still picture takes 0.5 to 0.75 s and is about 1.1 MB.
- `AVAssetExportSession` fails on a remote URL (-11838).
- A range-fetched MP3 chunk of about 53 s cut within about 0.2 s of the target.

## Goals / Non-Goals

**Goals:**
- Sharing an episode or a show needs no network.
- The clip pipeline (fetch, cut, video) runs off the main thread, and the editor stays responsive.

**Non-Goals:**
- Exact clips on shows that insert ads per request, when streaming.

## Decisions

**Web pages from the feed.** `ParsedEpisode.webPage` and `ParsedShow.webPage` come from the item and channel `<link>`. The parser drops an item's link when it equals the channel's link or appears on more than one item, so "every item points to the show page" becomes nil. That's pure and unit-tested. They're stored as optional `webPage` fields on `EpisodeRecord` and `ShowRecord`. The feed cache is local, so adding optional fields migrates automatically. They're exposed on `EpisodeInfo` and `ShowInfo`.

**Share text in CasterrCore.** `ShareText.episode(_:show:at:)` returns the message ("Episode – Show", plus ", from 12:34" when given a time) and the link (web page, else audio URL). `ShareText.show(_:feedURL:)` does the same for a show. Both are pure and unit-tested. The app shows them with `ShareLink(item: link, message: Text(text), preview: SharePreview(text, image: art))`, with the show's art loaded through the URL cache.

**Clip window math in CasterrCore.** `ClipWindow` takes the position and duration and gives:
- the visible span: 60 s either side of now, clamped to the episode, and shifted to stay 120 s long when near an edge
- the default clip: 15 s either side of now, clamped and shifted the same way
- dragging rules: 5 to 60 s, kept within the span

It also turns the visible span into a byte range for a constant-bitrate file (bytes per second from `Content-Length` over the duration, with 2 s padding). That's pure and unit-tested.

**Snapping to pauses.** `BackABeat`'s gap detection (quiet runs of at least 0.15 s below 20% of the stretch's median, from 10 ms `Loudness` readings) becomes a shared function, `QuietGaps.find(in:)`, returning each gap's middle. `BackABeat.resumePoint` keeps its behavior and its tests on top of it. The editor computes 10 ms readings for the whole span from the decoded samples once. It judges quiet against a moving two-second neighborhood rather than one median for all two minutes, so a loud stretch doesn't hide gaps in a quiet one. `ClipWindow.snap(_:to:within:)` moves an edge to the nearest gap middle within 0.5 s, or returns it unchanged. Dragging snaps when the finger's position is within 0.5 s of a gap and frees the edge once it's beyond. The default clip snaps both edges, keeping the 5 to 60 s limits. The tick is `.sensoryFeedback(.selection, trigger:)` on the snapped gap.

**Loudness bars in CasterrCore.** A pure function turns mono float samples into N RMS bars on a decibel scale, unit-tested. The app decodes the span with `AVAssetReader` (linear PCM, mono) and draws 120 bars.

**Getting the audio.**
The clip comes from the URL the engine actually loaded: the player exposes it (it already keeps `loadedURL` for chapters).
- **A local file was loaded:** that file.
- **A stream was loaded, MP3:** a ranged `GET` for `bytes=0-1` gives the total size from `Content-Range` (and proves partial requests work), then the first 10 bytes give the ID3 tag size and the first frame after it is checked for a Xing or VBRI header, which marks variable bitrate. Then a ranged `GET` of the span goes into a temporary `.mp3`. The decoded chunk's time zero is placed at the span's start. Every request sends AVPlayer's own User-Agent (`AppleCoreMedia/…`, built from the system version, matching what the helper observed), because ad-inserting servers vary the file by User-Agent.
- **Otherwise** (an M4A, no 206, variable bitrate, or no duration): the "download this episode" message. A network failure shows the offline message.

The span is fetched once when the editor opens, and the preview and the export both use it.

**Video.** Clips are at normal speed: a straight cut, with no time-pitch step. `AVAssetExportSession` cuts the clip to AAC (`AppleM4A`). `AVAssetWriter` then writes a 1080×1080 H.264 track of one still frame, one frame a second. The frame is the art Now Playing shows (the current chapter's picture, else the show's art, else Cassy on tangerine) with a badge 40 px from the top left corner: a dark capsule at 85% opacity, holding the app icon at 64 px and "Clipped with Casterr" in heavy rounded white type, about a quarter of the width. The frame is rendered once with `ImageRenderer` from a SwiftUI view, so the editor's preview uses the same view. The app icon image comes from the asset catalog's AppIcon. plus the cut audio, into a temporary `.mp4`. It runs in a detached task. The file is deleted when the share sheet closes.

**Editor UI (E1).**
- A sheet from Now Playing's share menu:
  - the video frame preview (the same view as the exported frame, badge included), with the clip times below it
  - the bars with the tangerine frame and a white "now" line
  - the span's start and end times, and the clip length
  - Share
- Each edge is a drag handle snapped to 0.1 s.
- Preview pauses the episode (`player.pause()`) and plays the clip with an `AVAudioPlayer` on the fetched chunk.
- VoiceOver: each edge is an adjustable element with a value such as "Starts at 12:04"; increment and decrement move it 1 s.

**Now Playing share menu.** A `Menu` with `square.and.arrow.up` at the top trailing corner of Now Playing, with "Share Episode" (a `ShareLink`) and "Share Clip…". It's hidden for episodes of the built-in shared show. Episode rows on show pages get a "Share Episode" context menu item, except built-in episodes. Queue rows don't, since long-press reorders them. The show page gets a share button in its toolbar, except on the built-in show.

## Risks / Trade-offs

- [Ad-inserting shows give a different file per request] → The clip uses the player's own session defaults. A small offset is accepted and noted in the phone checks.
- [Big ID3 tags (chapter art) at the start of an MP3 skew the byte estimate] → Read the ID3 tag size from the first 10 bytes and add it to the offset. If the decoded chunk is shorter than expected, show the message instead of a wrong clip.
- [WhatsApp may drop the caption] → It's a phone check. The video still carries the show's art.
- [Memory while writing video] → One still frame repeated, streamed to disk by `AVAssetWriter`.
