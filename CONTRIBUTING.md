# Contributing

Casterr is made by one person in their spare time. Here's how to help in a way that fits.

## Report a bug

[Open a bug report](../../issues/new?template=bug.yml). Say what you did, what you expected, and what happened instead. Include your iPhone model, your iOS version, and the Casterr version from Settings. The show's name and a screenshot or screen recording help a lot.

## Suggest an idea

[Open an idea](../../issues/new?template=idea.yml). Start with the problem you have, not only the feature you'd like. Casterr's first rule is simplicity, so the best ideas make the app easier to use or add as little as possible. Some good ideas won't fit, and that's okay.

## Pull requests

Casterr doesn't take pull requests. Writing every line myself keeps the app small and consistent, and keeps review from eating the few hours a week I have for it. You're welcome to fork it under the [license](LICENSE).

## Build your own copy

You need a Mac with Xcode 27 and [XcodeGen](https://github.com/yonaskolb/XcodeGen). The Xcode project is generated from `project.yml` and isn't checked in.

```sh
brew install xcodegen
xcodegen generate
open Casterr.xcodeproj
```

The simulator needs no setup. To run on your own iPhone, change the bundle IDs and the App Group in `project.yml` and the `.entitlements` files from `sh.oribi` to your own, then pick your team in Xcode's Signing settings.

Run the core tests (feeds, storage, triage) on your Mac:

```sh
swift test --package-path CasterrCore
```

Run the UI tests on a simulator. They need a network connection, because they follow a real public feed and stream an episode:

```sh
xcodebuild -project Casterr.xcodeproj -scheme Casterr -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

### Code style

The code is formatted and linted with swift-format, which comes with Xcode. Its settings are in `.swift-format`: the defaults, with 4-space indents and 120-character lines.

```sh
swift format -i -r -p .              # format every Swift file in place
swift format lint --strict -r -p .   # list what's left; every finding is an error
```

Warnings are errors in every target, so a build with a warning fails. Fix the warning rather than silencing it.

Keep each Swift file under 700 lines, and give each file and each type one job. When a type grows, split it into extensions in their own files, the way `Library` is split in `CasterrCore/Sources/CasterrCore/Storage/`.

A pre-push hook checks the lint and the 700-line limit before every push. Turn it on once after cloning, and have `git blame` skip the commit that formatted the whole codebase:

```sh
git config core.hooksPath .githooks
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

### iCloud sync

Sync is built but off until you give it your own iCloud container, which needs a paid Apple Developer account:

1. In `Casterr/Casterr.entitlements`, replace `iCloud.REPLACE-WITH-YOUR-CONTAINER` with your container, for example `iCloud.com.yourname.Casterr`. Container IDs can't be deleted once created.
2. Copy the App Group from `Casterr/Casterr-Device.entitlements` into `Casterr/Casterr.entitlements`.
3. In `project.yml`, point the `iphoneos` `CODE_SIGN_ENTITLEMENTS` line at `Casterr/Casterr.entitlements`.
4. Run `xcodegen generate` and build to a phone signed in to iCloud. Xcode creates the container on the first signed build.
5. Check the records in the [CloudKit dashboard](https://icloud.developer.apple.com/dashboard). Before a TestFlight build, deploy the schema from Development to Production there.

## How the project is laid out

- `Casterr/` is the app, `CasterrShare/` the share extension, and `CasterrUITests/` the UI tests.
- `CasterrCore/` is a Swift package with the logic that doesn't need UIKit, and most of the tests.
- `podcast_app_concept.md` holds the product decisions.
- `openspec/` holds a spec for every behavior and the history of each change.
- `AGENTS.md` lists the rules the code follows, written for coding agents and useful for people too.
- `CHANGELOG.md` is what the app shows in What's New.
