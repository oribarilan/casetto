## 1. Timing

- [x] 1.1 Replace `CassyAnimation.pause` and `firstPause` with one `pause` range of 0.7 to 1.2 seconds and use it in `CassyView.playIdleLoops` before the first loop and after each one; update `CassyAnimationTests` so it checks the pause stays at most 1.2 seconds; verify with `swift test`
- [x] 1.2 Update the Cassy line in `podcast_app_concept.md` if it states the old timing; run all UI tests, and screen-record the welcome screen in the simulator to confirm she starts within 1.2 seconds and rarely sits still
