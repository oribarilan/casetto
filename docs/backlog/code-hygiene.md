# Small files, strict linters and a pre-push hook: findings

Investigated 2026-11-26. Repo facts and tool versions were checked on this Mac. The linter was run read-only to count findings and time it. The app and package were not built, so today's warning count is unknown. The file splits are proposals read from the files' outlines.

## Recommendation

Use Apple's swift-format, which ships with the toolchain, to format and to lint with `--strict`. Add a short `wc -l` check for the 700-line limit, `SWIFT_TREAT_WARNINGS_AS_ERRORS` in `project.yml`, `.treatAllWarnings(as: .error)` in `Package.swift`, and a pre-push hook in `.githooks/`. None of it adds a dependency.

## Today (verified)

- No formatter or linter config and no hooks: there's no `.swift-format`, `.swiftlint.yml` or `.githooks`, `core.hooksPath` is unset, and `.git/hooks` holds only Git's samples.
- `scripts/` holds only `testflight.sh`.
- Toolchain: Swift 6.4.2 and Xcode 27.2 (27B52). `Package.swift` uses swift-tools-version 6.4.

## Formatter and linter

- **swift-format** 6.4.4 ships with the toolchain (`xcrun --find swift-format`) and runs as `swift format`. It formats and lints, and `lint --strict` turns every finding into an error ([swift-format](https://github.com/swiftlang/swift-format)).
- **SwiftLint** 0.65.1 is already on this Mac through Homebrew, but it's an extra dependency that `CONTRIBUTING.md` doesn't mention. It lints only, and has a `file_length` rule.
- **SwiftFormat** (Nick Lockwood) does the same job as swift-format, so skip it.
- **Pick swift-format alone.** Add SwiftLint later only if its extra rules are wanted.
- **Config:** the code uses 4-space indents. swift-format's defaults (2 spaces, 100 characters a line) give 13,508 findings. With 4 spaces and 120 characters there are about 1,000: 388 indentation, 258 blank lines, 249 line length, 59 semicolons, and fewer for other rules. Most fix themselves. Plan one commit that only reformats (`swift format -i -r -p .`), then fix the rest by hand.

## Warnings as errors

- **`project.yml`:** add `SWIFT_TREAT_WARNINGS_AS_ERRORS: YES` under the top-level `settings.base`, so every target gets it. The repo has no C or Objective-C files, so `GCC_TREAT_WARNINGS_AS_ERRORS` isn't needed.
- **`Package.swift`:** add `.treatAllWarnings(as: .error)` to both `swiftSettings` lists. It needs PackageDescription 6.2 and is checked in the toolchain. It isn't an unsafe flag ([SE-0480](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0480-swiftpm-warning-control.md)), and SwiftPM ignores it for remote packages, so FeedKit isn't affected. Don't use `unsafeFlags(["-warnings-as-errors"])`.
- **Risks:** Xcode builds remote packages with warnings suppressed, and that clashes with warnings-as-errors ([Swift Forums](https://forums.swift.org/t/warnings-as-errors-in-sub-packages/70810)). A local package like CasterrCore is probably fine, but the first build will tell. Deprecation warnings from the iOS 27 SDK will also become errors. The first step is to build the app and run `swift build` on the package, then fix whatever fails.

## The 700-line limit

swift-format has no file-length rule. SwiftLint's `file_length` would work. Without SwiftLint, this check takes 0.01 seconds and today flags exactly the two large files:

```sh
git ls-files '*.swift' | xargs wc -l | awk '$2!="total" && $1>700 {print; bad=1} END {exit bad}'
```

## Pre-push hook

- Commit `.githooks/pre-push`. Git can't turn on a hook by itself after a clone, so each clone runs `git config core.hooksPath .githooks` once. Add that line to "Build your own copy" in `CONTRIBUTING.md`.
- The hook runs `xcrun swift-format lint --strict --parallel` on the tracked Swift files (about 0.25 seconds for 106 files) and the length check (0.01 seconds). SwiftLint would add about 0.3 seconds.
- Don't build or run tests in the hook. That takes minutes.

## Splitting the two large files

**`Library.swift`** (891 lines) is one actor with `// MARK` sections. Split it into `extension Library` files:

- `LibraryTypes.swift`: the value types (lines 4 to 79).
- `Library.swift`: opening, the clock, thresholds (81 to 130), and the shared private helpers.
- `Library+Subscriptions.swift` (131 to 230), `Library+Triage.swift` for triage, rule cards and the Inbox (231 to 364), `Library+Queue.swift` for the Queue and episode state (365 to 559), `Library+Settings.swift` (560 to 634), `Library+Bookmarks.swift` (667 to 705), and `Library+Feeds.swift` for sync and the feed cache (the rest of 635 to 891).
- Helpers used across files change from `private` to internal, because `private` doesn't reach other files.

**`ScreensTests.swift`** (1122 lines) is one test class with 24 tests. Split it by area:

- `UITestSupport.swift`: the element helpers and `subscribe`, `choose`, `snapshot` and `feed`, in a shared base class or extension.
- `InboxTests.swift`: testInbox, testRuleCard, testInboxCard, testInboxSwipeTip.
- `NowPlayingTests.swift`: testCapture, testChapters, testShareMenu, testClipEditor and their helpers, testHeadphoneButtons.
- `ShowsTests.swift`: testScreens, testShowOlderEpisodes, testInstantControls, testFindMoreShows, testChartCountry and its helpers.
- `OnboardingTests.swift`: testOnboarding, testStarTip, testWhatsNew.
- `SharingTests.swift`: testSharedFile, testSharedLinkAndSubscribe.
- `SettingsTests.swift`: testClearCache, testTabTaps.

A commit that only reformats or splits files changes nothing the listener sees, so it needs no version bump.
