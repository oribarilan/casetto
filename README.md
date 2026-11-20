# Casterr

A podcast inbox that triages itself. Casterr is a free, open-source iOS podcast player that sorts new episodes for you, explains every move it makes, and lets you undo any of them. No accounts, no server, no tracking.

It's early. Read [the concept](podcast_app_concept.md) for what it does and the roadmap. Planned work lives in [`openspec/`](openspec/).

Licensed under the [Mozilla Public License 2.0](LICENSE).

## Building

You need Xcode 27 and [XcodeGen](https://github.com/yonaskolb/XcodeGen). The Xcode project is generated from `project.yml` and isn't checked in.

```sh
brew install xcodegen
xcodegen generate
open Casterr.xcodeproj
```

Run the core tests (domain logic, feeds, storage) on your Mac:

```sh
swift test --package-path CasterrCore
```

Build the app from the command line:

```sh
xcodebuild -project Casterr.xcodeproj -scheme Casterr -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build
```

Run the UI tests on the simulator. They need a network connection, because they subscribe to a real public feed and stream an episode. The Inbox test launches with `-fastClock`, where one second counts as one day, so it can test expiry. The simulator downloads episodes but has no background refresh, so check that on a phone:

```sh
xcodebuild -project Casterr.xcodeproj -scheme Casterr -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

## iCloud sync

Without setup, Casterr keeps everything on the device. To sync subscriptions, the Queue, settings, and bookmarks through your private iCloud database, you need a paid Apple Developer account:

1. In `project.yml`, add your team under the `Casterr` target's `settings.base`: `DEVELOPMENT_TEAM: <your team ID>`.
2. In `Casterr/Casterr.entitlements`, replace `iCloud.REPLACE-WITH-YOUR-CONTAINER` with your container, for example `iCloud.com.yourname.Casterr`. Container IDs can't be deleted once created.
3. Under the same `settings.base`, add `CODE_SIGN_ENTITLEMENTS: Casterr/Casterr.entitlements`.
4. Run `xcodegen generate` and build to a phone signed in to iCloud. Xcode creates the container on the first signed build.
5. Check the records in the [CloudKit dashboard](https://icloud.developer.apple.com/dashboard), in the container's private database. Before a TestFlight build, deploy the schema from the Development to the Production environment there.
