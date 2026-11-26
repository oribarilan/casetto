# Casterr

Casterr is a native iOS podcast player. The product decisions are in `podcast_app_concept.md`. Read that file before you plan or change behavior.

Simplicity is the top rule. Choose the simplest design that meets the current milestone. If a decision can be made simpler, tell the user and propose the simpler option, even when the user already approved the complex one.

Use the words in the "Words" section of `podcast_app_concept.md` for all text in the app. Use one word for each idea. Do not show the word "archive" in the app.

Do not use emoji anywhere in the app. Use SF Symbols for icons. If no SF Symbol fits, draw the icon in SwiftUI.

For onboarding, suggest just-in-time tips. Use the `CassyTip` component (`Casterr/Screens/CassyTip.swift`). Show a tip on the control that the listener needs, at the moment that they first need it. Each tip shows one time. The welcome screen on first launch (`Casterr/Screens/WelcomeView.swift`) is the only intro screen. Do not suggest other intro screens, banners, tutorials, or tips about things that are not on the screen yet.

When you show the user design alternatives as images, put each option's key (a number or a letter, and a short name) on the image itself, so that the user can refer to it. Use the same keys in your message. Show only the alternatives for the open question.

Plan work with OpenSpec. Each roadmap milestone is one change in `openspec/changes/`. Do not implement a change until the user approves its proposal.

Keep the specs current:

- When the user decides a behavior, write it as a requirement with scenarios in the active change's specs at that time. Do not record it only in the design or the tasks.
- Do not edit a change after it is done. Make a new change that modifies the requirement.
- When a modified requirement drops or renames a scenario, keep the old scenario name. OpenSpec refuses to archive a change that drops a scenario.
- Archive a change when its tasks pass and the user approves the result. Move checks that need a real iPhone to `openspec/device-checks.md` before you archive.
- The current specs are in `openspec/specs/`. Run `openspec validate --specs --strict` after an archive.

## Changes and reloads

A tap must show its result at once. Do not make the listener wait for a save.

Save with `model.change(areas) { … }`. Name only the areas that the change touches, from `DataArea` (`Casterr/DataArea.swift`). If you are not sure, use `.all`.

A screen loads its data with `.reload(on: model.revision(areas)) { … }` (`Casterr/Screens/Reload.swift`). Use only the areas that the screen shows. Do not use `.task(id:)` with a revision. The exception is a screen that also shows data that no area tracks, for example the cache size in Settings: it can use `.task(id: model.revision(areas))`, which loads each time the screen shows. If a screen shows two parts that change for different reasons, give each part its own `.reload`.

When you add a library method that changes data, decide which areas it touches. When you add a screen, decide which areas it shows.

## Smooth animations

Do not do database work on the main thread. `Library` runs its work on its own serial queue through `LibraryExecutor` (`CasterrCore/Sources/CasterrCore/Storage/LibraryExecutor.swift`). Do not change `Library` back to `@ModelActor`. The default SwiftData executor runs each job on the thread that calls it, so calls from the main actor run on the main thread and stop animations. If you add a new model actor, give it the same executor. `LibraryThreadTests` checks this.

In the library, read only the records that you need. To find which of a few keys exist, fetch with a predicate on those keys (`keys.contains($0.key)`) and `propertiesToFetch`. Do not fetch all records of a type to make a set.

A library call goes to another queue and comes back later. In a test, do not wait for library work with `Task.yield()` only. Wait for a library call, as `settle()` in `PlayerTests` does.

Do not start a repeating animation (`repeatForever`) with `withAnimation`. `withAnimation` gives the animation to all changes in the same update, and a List that changes in that update moves forever. Put `.animation(_:value:)` on the view that repeats, as `Shimmer` does.

To animate a control between two looks, use one view and change its modifiers (for example `.tint(on ? a : b)`). Do not put two views in `if`/`else` branches. SwiftUI makes a new view for each branch, and the animation stops.

A button in a List row that adds List rows must not change the state in its action. In that case the List adds the rows without animation. Change the state in a `Task` that the action starts, as `act` in `ShowView` does.

When one row view has two looks, put the `if` inside the row, for example in the button label, as `EpisodeRow` does for the Inbox card. Do not put an `if` or a conditional modifier around the whole row. If you do, a List that adds rows above a visible row scrolls to keep that row in view.

The simulator does not show most stalls. To check that an animation is smooth, measure a Release build on the listener's iPhone:

1. Build and install: `xcodebuild build -scheme Casterr -configuration Release -destination "id=<phone>" -derivedDataPath <dir> -allowProvisioningUpdates DEVELOPMENT_TEAM=<team>`, then `xcrun devicectl device install app --device <phone> <app>`.
2. Ask the listener to open the screen, then attach the recorder: `xcrun xctrace record --device <phone> --template 'Animation Hitches' --instrument 'Time Profiler' --attach Casterr --output <file>.trace`. Ask the listener to tap, then stop the recorder with SIGINT.
3. Export the `hitches` and `time-profile` tables with `xcrun xctrace export`. Find the hitches. Count the Casterr functions in the main-thread samples during each hitch.

Measure before and after a change, with the same taps on the same show.

## Versions and What's New

The app version is `MARKETING_VERSION` in `project.yml`. It is the only place for the version. `CHANGELOG.md` has one section for each version, newest first. The app bundles `CHANGELOG.md` and shows its sections in What's New, so every line in it is text that the listener reads.

When a commit changes what the listener sees or hears, do these steps in that commit:

1. Increase `MARKETING_VERSION`. For new or changed behavior, increase the minor number and set the patch to zero (0.3.1 to 0.4). For bug fixes only, increase the patch number (0.3 to 0.3.1).
2. Add a section at the top of `CHANGELOG.md`, below the introduction. The heading is `## ` and the new version, for example `## 0.4`. Put an empty line after the heading.
3. Under the heading, write one line for each change that the listener can notice. Start each line with `- `.

Rules for the changelog lines:

- Write one sentence for each line. Say what the listener can now do or see, not how the code works.
- Use the words from the "Words" section of `podcast_app_concept.md`. Do not use code names, file names, or OpenSpec change names.
- Do not use emoji or em dashes.
- Do not change a section after you commit it, except to correct a spelling error. A later change gets its own version and section.

Do not change the version or `CHANGELOG.md` when a commit changes only specs, the backlog, tests, scripts, or agent instructions.

`scripts/testflight.sh` stops before it archives if the newest `CHANGELOG.md` section is not the `MARKETING_VERSION`. If it stops, correct the version or the changelog in a commit, then run it again.

The code is licensed under MPL-2.0.
