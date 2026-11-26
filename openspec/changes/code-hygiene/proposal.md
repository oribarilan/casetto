# Proposal

## Why

Two files have grown past 700 lines (`Library.swift` at 891, `ScreensTests.swift` at 1122), and nothing checks formatting, lint, or warnings. The listener asked for small files with one responsibility each, strict formatters and linters, warnings treated as errors, and a pre-push hook that enforces it. Doing it now is cheapest: the files only grow, and every later change lands formatted and within the limit. The investigation is in `docs/backlog/code-hygiene.md`.

This is a backlog item, not a numbered roadmap milestone.

## What Changes

- **Warnings are errors** in every Xcode target (`project.yml`) and in the CasterrCore package (`Package.swift`). Existing warnings are fixed first.
- **Apple's swift-format** formats and lints the code, with a config that keeps today's 4-space indents and allows 120-character lines. `lint --strict` turns every finding into an error. One step reformats everything; the rest is fixed by hand.
- **The two large files split by responsibility**: `Library.swift` into `extension Library` files by area, and `ScreensTests.swift` into test files by screen with a shared helper file.
- **A pre-push hook** in `.githooks/pre-push` runs the strict lint and a check that no Swift file is over 700 lines. `CONTRIBUTING.md` says to run `git config core.hooksPath .githooks` once after cloning.
- **AGENTS.md and CONTRIBUTING.md** document it all: the format and lint commands, the config file, warnings as errors, the 700-line limit with one responsibility for each file and type, and turning on the hook after a clone. AGENTS.md also tells agents not to skip the hook.
- No change the listener can see, so no version bump and no CHANGELOG section.

## Out of scope

- SwiftLint or any other new dependency.
- Linting in CI. The repo has no CI.
- Refactoring beyond moving code between files: no renames, no behavior changes, no new abstractions.
- Splitting files that are under 700 lines.
- The flaky UI tests at cold start, which have their own backlog entry.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. The change touches tooling and file layout only, so it has no spec delta.

## Impact

- `project.yml`, `CasterrCore/Package.swift`: warnings as errors.
- `.swift-format` (new): the formatter and linter config.
- Every Swift file: reformatted.
- `CasterrCore/Sources/CasterrCore/Storage/Library.swift`: split into several files in the same folder.
- `CasterrUITests/ScreensTests.swift`: split into several files in the same folder.
- `.githooks/pre-push` (new), `CONTRIBUTING.md`, `AGENTS.md`.
