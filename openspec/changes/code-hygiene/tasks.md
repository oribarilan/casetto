## 1. Warnings as errors

- [ ] 1.1 Build the app for the simulator and run `swift build` in CasterrCore, and list every warning. Verify: the list is written in this task's notes below.
- [ ] 1.2 Fix the warnings from 1.1 without changing behavior. Verify: both builds show no warnings, and the core tests pass.
- [ ] 1.3 Add `SWIFT_TREAT_WARNINGS_AS_ERRORS: YES` to `project.yml` and `.treatAllWarnings(as: .error)` to both targets in `Package.swift`. Verify: `xcodegen`, the app build and `swift build` succeed.

## 2. Split the large files

- [ ] 2.1 Split `Library.swift` into `Library.swift` and `extension Library` files by area (types, subscriptions, triage, Queue, settings, bookmarks, feeds), moving code only. Verify: every file is under 700 lines, and the core tests pass.
- [ ] 2.2 Split `ScreensTests.swift` into test files by screen area with a shared helper file, moving code only. Verify: every file is under 700 lines, and every UI test still runs and passes (apart from the known cold-start flakes).

## 3. Format and lint

- [ ] 3.1 Add `.swift-format` with 4-space indents and 120-character lines, and reformat every Swift file with `swift format -i -r -p`. Verify: the app builds and the core tests pass.
- [ ] 3.2 Fix the remaining `swift format lint --strict` findings in CasterrCore by hand. Verify: lint is clean there, and the core tests pass.
- [ ] 3.3 Fix the remaining findings in the app, the share extension and the UI tests. Verify: `swift format lint --strict -r -p .` is clean and the app builds.
- [ ] 3.4 Add `.git-blame-ignore-revs` naming the reformat commit, once it exists. Verify: `git blame --ignore-revs-file .git-blame-ignore-revs` skips it.

## 4. Hook and guidance

- [ ] 4.1 Add `.githooks/pre-push`, which runs the strict lint and the 700-line check and stops the push when either fails. Verify: it passes on a clean tree, and fails with a file over 700 lines and with a lint error.
- [ ] 4.2 In `CONTRIBUTING.md`, add a "Code style" part to "Build your own copy": the one-time `git config core.hooksPath .githooks`, the format command (`swift format -i -r -p .`), the lint command (`swift format lint --strict -r -p .`), what the pre-push hook checks, that warnings are errors, and the 700-line limit. Verify: the steps work on a fresh clone.
- [ ] 4.3 Add a "Code style" section to `AGENTS.md` in ASD-STE100 style: format with swift-format and keep the lint clean (the commands, and that `.swift-format` holds the config); fix every warning, because warnings are errors; keep each Swift file under 700 lines, and give each file and each type one responsibility, splitting a type with extensions when it grows; turn on the hook after a clone; do not skip the hook with `--no-verify`. Verify: the section is in AGENTS.md and an agent can follow it without other files.
- [ ] 4.4 Run the core tests and the UI tests. Verify: all pass, apart from the known cold-start flakes.

## Workflow follow-up

- Start only after the tab-home change (0.8) is committed, because the reformat touches its files.
- Commit in steps, only when the listener says to: warnings, the splits, the reformat on its own, the hand fixes, then the hook and guidance. No version bump.
- Archive after the listener approves, then run `openspec validate --specs --strict`.
