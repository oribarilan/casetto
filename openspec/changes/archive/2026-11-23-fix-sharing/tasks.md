## 1. Text and link

- [x] 1.1 Add `EpisodeKey.guid`, and `feedURL` to `ShowArt` from the show's current feed address. Verify with core tests
- [x] 1.2 Make `ShareText.episode` return "Episode – Show" with no time and the Podlink link (feed and GUID in unpadded base64url), or the show's Podlink link with no GUID. Verify with core tests, including a GUID whose length needs padding
- [x] 1.3 Pass the feed address from rows, the show page, Now Playing and the clip editor, and drop the time everywhere. Verify the app builds and the share UI tests pass with the new text

## 2. Clip quality

- [x] 2.1 Draw small art with high-quality scaling; check the clip's sharpness against the source art (a 4 Mbit/s target was tried and dropped, see design). Verified: the frame is crisp, and the listener confirmed it looks great in Messages

## 3. Checks

- [x] 3.1 Remove the "Sharing fixes" backlog entry, run the core and UI tests
- [x] 3.2 Add a device check: share an episode and a clip to Messages and WhatsApp; the text is "Episode – Show", the Podlink link opens that episode (try a new episode and a GUID whose base64 needs padding), and the clip's art looks sharp in both apps

## Workflow follow-up

- Move the device check to `openspec/device-checks.md` before archiving.
