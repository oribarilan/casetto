## Context

`ShareText.episode` returns "Episode – Show" plus ", from 12:34" when given a position, and the episode's web page or audio link. Rows build it from `EpisodeInfo` and `ShowArt` (title and art). Now Playing and the clip editor pass the playback position. `ClipVideo.make` writes H.264 at default settings; a test clip came out at about 150 kbit/s for a 1080 by 1080 still frame. The clip editor loads the show's art from `artworkURL` at whatever size the feed serves.

## Decisions

**Podlink's feed form, built locally.** Podlink documents `https://pod.link/<base64url(feed URL)>/episode/<base64url(GUID)>` and `https://pod.link/<base64url(feed URL)>` for a show. Using the feed address avoids looking up Apple's show ID, which shows added by feed address don't have. The feed address is the show's current one (it follows feed moves), not the normalized key. Base64url uses `-` and `_` and drops `=` padding; Podlink doesn't document padding, so a device check opens one link of each length. The alternative, Apple's ID form, needs a network lookup at share time and fails for shows Apple doesn't list.

**The GUID from the key.** `EpisodeKey` already holds `guid:<GUID>` or the audio URL. A small `guid` property returns the GUID, or nil for keys built from the audio URL; nil links to the show page.

**The feed address on `ShowArt`.** `Library.showArt()` already feeds the rows; adding `feedURL` there means rows build the link with no new lookup. The show page and Now Playing have the feed address already.

**No time.** `ShareText.episode` loses its `at` parameter; every caller sends just the names.

**A sharp clip frame.** The clip editor already draws the frame from the show's full-size art. Art smaller than 1080 pixels is now scaled with high-quality interpolation instead of the default. A 4 Mbit/s target was tried: on the show's 1400-pixel art, Apple's H.264 encoder made the first frame slightly smaller than at default settings, and the default frame was already crisp, so the setting was dropped. The blur the listener saw came from WhatsApp re-compressing the video; Messages shows it sharp.

## Risks / Trade-offs

- [Podlink can't resolve a brand-new episode until it re-reads the feed] → Its help pages mention caching; the device check notes how long it takes.
- [Podlink rejects unpadded base64] → The device check catches it; the fix is one line.
- [WhatsApp re-compresses any video, even in HD] → Out of our hands for now; logged in the backlog for an experiment.
