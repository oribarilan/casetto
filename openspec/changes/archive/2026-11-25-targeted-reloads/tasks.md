## 1. Measure first

- [x] 1.1 Record an optimized build on the listener's phone with Instruments (Animation Hitches) while they tap Star, Unstar, Follow and Unfollow on a busy show's page. Verify: the trace is saved in the scratchpad and the hitches per tap are written down in this file's notes.

Notes, 2026-11-25, iPhone 17 Pro Max, Release build:
- Before (0.5.1): 7 hitches over about 12 taps, 133 ms in all; six of 16.7 ms and one of 33 ms.
- After the targeted reloads (5.1 and 5.2 not yet in): Star is smooth. Follow and Unfollow: 8 hitches, 717 ms in all, the worst 217 ms. In that one, `knownEpisodeKeys()` (every episode record, loaded twice) took 56% of the main-thread samples and `episodes(of:)` 18%. All library work ran on the main thread.

- After 5.1 and 5.2: the listener reports that the whole app is much smoother. Two later recordings failed: the recorder could not attach, and a launched recording stopped getting data after 14 s.
- Without the 0.6 s wait: the listener reports that the Star and Follow spin is smooth.

## 2. Areas

- [x] 2.1 Replace `revision` with `DataRevisions` and `DataArea` in `AppModel`; `change` takes areas, defaulting to `.all`; refresh, bookmark, download and sync bumps name their areas. Verify: the app builds, and every screen still reloads (all call sites still use `.all`).
- [x] 2.2 Add `.reload(on:)` and move every screen and CarPlay to it, each on the areas it shows. Verify: core tests and the full UI suite pass.
- [x] 2.3 Name the areas at each `model.change` call site. Verify: the full UI suite passes.

## 3. Show page

- [x] 3.1 Split the show page's reload into its follow part and its episode part. Verify: a log during Star shows only the follow part runs; testScreens, testInstantControls and testShowOlderEpisodes pass.
- [x] 3.2 Make a finished download bump only `downloads`, and have screens with download words redraw on it. Verify: a show page row turns to Downloaded when its download lands, with no episode reload in the log.

## 5. Library work

- [x] 5.1 Make `playableQueue` and the Play next position fetch only the Queue's episode records. Verify: core tests pass.
- [x] 5.2 Give the library its own executor on a private serial queue. Verify: a core test shows a library opened on the main actor works off the main thread; core tests and the full UI suite pass.
- [x] 5.3 Check Follow and Unfollow on the phone again. Verify: the listener reports them smooth, written in the notes.

## 4. Wait and rule

- [x] 4.1 Try Star and Unstar on the phone without the 0.6 s wait; remove it if smooth. Verify: the listener reports the spin smooth.
- [x] 4.2 Add the rule to AGENTS.md. Verify: the section is there.
- [x] 4.3 Check the same taps as 1.1 and compare. Verify: the listener's report, written in the notes.
- [x] 4.4 Run the core tests and the full UI suite. Verify: all pass, apart from the known testCapture flake.

## Workflow follow-up

- Commit after the earlier versions, only when the listener says to.
- Archive after the listener approves.
