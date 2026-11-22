## Why

About one clip in 25 of a streamed episode fails with "Download this episode to make a clip", though the server sent the bytes fine. The fetched part starts mid-frame, and sometimes the bytes just after the cut look like the start of an MP3 frame of a different format. Apple's decoder locks onto that fake frame and stops with "Cannot Decode". It reproduces on the Mac with ATP 718, bytes 23049720 to 24041711: 0.03 s decoded. Cut to the first real frame, 140 bytes in, the same part decodes all 124 s.

## What Changes

- Before decoding a fetched part, the clip editor skips to the first real frame: one whose format matches the episode's first frame (which it already reads) and that is followed by a second matching frame at the right distance.
- The clip's start time moves by the skipped bytes at the stream's bitrate, a few milliseconds, so clip edges stay exact.
- Each way the fetch or decode can fail now writes an error line to the "clips" log.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `sharing`: Share a clip says a fetched part decodes from its first real frame, with a scenario for a part that starts with a fake frame.

## Impact

`MP3Header` in CasterrCore gets a function that finds the first real frame and its bitrate, with unit tests built like the failing bytes. `ClipFetcher.fetch` in `Casterr/Playback/ClipAudio.swift` trims the part before writing it.
