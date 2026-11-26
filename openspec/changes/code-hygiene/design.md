# Design

## Context

See `proposal.md` for why, and `docs/backlog/code-hygiene.md` for the investigation. The toolchain is Swift 6.4.2 with Xcode 27.2. swift-format 6.4.4 ships with it (`xcrun swift-format`). The Xcode project is generated from `project.yml`, and the core is a local Swift package.

## Decisions

- **swift-format, not SwiftLint.** It ships with the toolchain, so it adds no dependency, and it both formats and lints. SwiftLint would add a Homebrew dependency for extra rules we don't need yet.
- **Config: swift-format's defaults, except 4-space indents and 120-character lines.** The code already uses 4 spaces; changing it would rewrite every line for nothing. With these two changes there are about 1,000 findings, most fixed by the formatter. If a default rule turns out to fight the code's style in many places, turn that rule off in `.swift-format` and say why in the commit, rather than rewriting the code.
- **Warnings as errors through supported settings.** `SWIFT_TREAT_WARNINGS_AS_ERRORS: YES` in `project.yml`'s base settings covers the app, the share extension and the UI tests. `.treatAllWarnings(as: .error)` in both package targets covers CasterrCore and is not an unsafe flag; SwiftPM ignores it for remote packages, so FeedKit is unaffected. No `GCC_` setting, because the repo has no C or Objective-C.
- **Fix existing warnings before turning the setting on**, so each step builds.
- **The 700-line limit is a shell check**, because swift-format has no file-length rule: `git ls-files '*.swift' | xargs wc -l | awk '$2!="total" && $1>700 {print; bad=1} END {exit bad}'`.
- **The hook lives in `.githooks/`**, and each clone runs `git config core.hooksPath .githooks` once. Git can't turn on a committed hook by itself. The hook runs only the lint and the length check (under a second); it doesn't build or test.
- **Splits move code only.** `Library` becomes an actor in `Library.swift` with `extension Library` files by area, following its `// MARK` sections. Helpers used across files change from `private` to internal (the module boundary still hides them from the app). `ScreensTests` becomes one test class per screen area, sharing helpers through a common file.
- **Order: warnings, splits, reformat, hook.** Splitting before the reformat keeps the move easy to review. The hook comes last, once the lint and the length check pass.

## Risks / Trade-offs

- Xcode builds remote packages with warnings suppressed, which can clash with warnings-as-errors. CasterrCore is a local package, so this is likely fine; the first build tells.
- Deprecation warnings from the iOS 27 SDK become errors. Fix them as they come.
- The reformat touches almost every line, so it lands in a commit of its own, and `git blame` should skip it (`.git-blame-ignore-revs`).
