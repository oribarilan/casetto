## 1. Spin

- [x] 1.1 Add `.spin(from:trigger:)` to `Theme.swift`: start angle and 0.6 scale without animation, then a bouncy spring to upright; no effect with Reduce Motion on. Verify: the app builds.
- [x] 1.2 Find Shows: bump a per-show counter when a tap stars or follows, and spin the star from -144 degrees and the check from -90 degrees. Verify: build, run in the simulator, tap the star and + on a row; Unstar and Unfollow swap without spinning, and opening Find Shows with followed shows doesn't spin them.
- [x] 1.3 Show page: give `ShowPageButton` a spin start angle and trigger for its icon, and bump them on Follow and Star taps. Verify: in the simulator, Follow and Star spin, Starred and Unfollow don't, and opening a followed, starred show doesn't spin.
- [x] 1.4 Make a tap that spins wait for the spin before it saves, so the app-wide reload doesn't stutter it. Verify: a frame log on the simulator shows no reload stalls inside the spin.
- [x] 1.5 Queue each show's saves instead of ignoring taps while one runs, so Follow then a quick Star keeps both. Verify: testInstantControls and testFindMoreShows pass.

## 2. Unfollow question

- [x] 2.1 Move the Unfollow `confirmationDialog` from the page onto the Following button. Verify: in the simulator, tapping Following opens the question pointing at the button, and the existing Unfollow UI test (testScreens) still passes.

## 3. Release bookkeeping

- [x] 3.1 Set `MARKETING_VERSION` to 0.5 and add a `## 0.5` CHANGELOG section with one line for the spin and one for the Unfollow question. Verify: testWhatsNew passes.
- [x] 3.2 Add the spin's feel and the question's position to `openspec/device-checks.md`. Verify: the section is there.
- [x] 3.3 Run the core tests and the UI tests. Verify: all pass, apart from the known testCapture cold-start flake.

## Workflow follow-up

- Commit 0.4.1 first, then this change as 0.5, each only when the listener says to.
- Archive after the listener approves, then run `openspec validate --specs --strict`.
