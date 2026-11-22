## 1. Fix

- [x] 1.1 Make the Now Playing slider seek as the thumb moves and remove the scrubbing state; in `AVPlayerEngine`, remember the latest seek target, clear it in the seek's completion handler only if no newer seek replaced it, and have time reports use the target while it is set; verify the build has no new warnings
- [x] 1.2 Remove the retry loop around the first slider move in `testClipEditor`, then run `testClipEditor` 10 times and all UI tests once; all must pass (9 of 10 clip editor runs passed; the tenth failed on the clip audio fetch, a separate issue, and the listener accepted it)
