## 1. Show page description

- [x] 1.1 Measure whether the description is cut off, and show "Show more"/"Show less" only then, with the whole description as one button that toggles it. Widen the placeholder's last bar to "Show more". Verify: in the simulator, a long description shows Show more, a tap anywhere on it opens it with Show less, and a short one shows no words.
- [x] 1.2 Add a UI test check: on Planet Money's page, tapping the description shows Show less. Verify: the test passes.

## 2. Accent text

- [x] 2.1 Color the country name in the Popular now menu heading with the accent text color. Verify: in the simulator with region Israel, "Israel" is tangerine; testChartCountry passes.
- [x] 2.2 Color "What's New" in the About row with the accent text color. Verify: in the simulator, the row shows tangerine "What's New"; testWhatsNew passes.

## 3. Release bookkeeping

- [x] 3.1 Set `MARKETING_VERSION` to 0.5.1, add a `## 0.5.1` CHANGELOG section, and remove the three backlog entries. Verify: testWhatsNew passes.
- [x] 3.2 Add the three checks to `openspec/device-checks.md`, and run the core and UI tests. Verify: all pass, apart from the known testCapture cold-start flake.

## Workflow follow-up

- Commit after 0.4.1 and 0.5, only when the listener says to.
- Archive after the listener approves, then run `openspec validate --specs --strict`.
