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
