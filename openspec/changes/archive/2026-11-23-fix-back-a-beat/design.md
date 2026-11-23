## Context

`BackABeat.resumePoint(pausedAt:readings:)` filters readings to [P-5, P-2) and returns the middle of the last gap `QuietGaps.find` reports, where quiet means below 20% of the stretch's median. `Player` keeps a `pausedInPlace` flag and reads the live `position` on resume. The app's audio tap keeps 8 s of readings. See proposal.md for the defects.

## Decisions

**Anchor at where speech stopped.** Read readings from P-10 to P. If the readings just before P are quiet, walk back to where that quiet run starts and call it the anchor; otherwise the anchor is P. Choose the latest gap that reaches into [anchor-5, anchor-2] and resume at its middle, moved into that range when the middle is outside it, which still lands inside the gap. The anchor's own quiet run never counts, so playback always goes back to an earlier gap. A silence that started more than 10 s before P has no anchor inside the readings, and playback stays at P.

**Find first, choose second.** Quiet runs are found on the whole read stretch, and the 0.15 s minimum applies to a gap's full length; the window only decides which gaps count. This fixes gaps cut at the edges. A first try chose gaps by their middle alone, but that skipped a one-second pause starting just before the window and left playback where it paused.

**Louder parts as the reference.** Quiet means below 20% of the stretch's 90th-percentile level instead of its median. The median sits at the quiet level once pauses fill half the stretch; the 90th percentile stays on speech. The moving-median path used by the clip editor is left as it is.

**One pause point.** `pausePoint: TimeInterval?` replaces `pausedInPlace`. `pause()` sets it from `position` only when `isPlaying` was true; seek, skip, start and unload clear it; `resume()` runs Back a Beat when it is set and then clears it. A second pause while paused does nothing, and a late position report can't move a pause point that's already stored.

**Contiguity.** Two readings belong to the same run when they are under 25 ms apart, so one dropped 10 ms slice doesn't split a gap.

**Exact seek for Back a Beat only.** `AudioEngine` gets `seek(to:exact:)`; Back a Beat asks for exact, slider drags and skips keep the default tolerance so they stay fast. `AVPlayerEngine` opens file URLs with `AVURLAssetPreferPreciseDurationAndTimingKey`. Whether streamed MP3s land exactly is checked on the device.

**Ring size.** The audio tap keeps 15 s of readings so the 10 s read stretch is always there, even with audio rendered ahead.

## Risks / Trade-offs

- [The 90th percentile misjudges music beds] → Music under voices still has no quiet gaps, so playback stays at the pause point, as today.
- [An exact seek on a long stream takes longer] → It runs once per resume; the device check covers it.
