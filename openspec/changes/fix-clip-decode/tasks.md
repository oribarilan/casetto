## 1. Fix

- [x] 1.1 Add `MP3Header.firstFrame(in:like:)` returning the offset of the first frame that matches a reference header's version, layer, sample rate and bitrate and is followed by a second matching frame, plus the bitrate; unit-test it with bytes built like the failing ATP 718 part (a fake MPEG-2 frame at 9, real MPEG-1 frames from 140), a part that starts on a frame, and bytes with no frame; verify with `swift test`
- [x] 1.2 In `ClipFetcher.fetch`, keep the first frame's header, trim the fetched part to the first real frame, and move the clip's start by the skipped bytes; keep the new error log lines; verify on the Mac that the failing ATP 718 range, trimmed the same way, decodes in full; run `testClipEditor` 25 times and all UI tests once
