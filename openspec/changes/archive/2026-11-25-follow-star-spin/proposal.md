# Proposal

## Why

Following and starring a show are the two choices that shape what the listener hears, and today the icon just fades from one state to the other. The listener wants these moments to feel a bit more fun. They picked option C, "Spin", from the motion page.

On the show page, tapping Following opens the Unfollow question ("Episodes you queued stay in your Queue.") as a bubble that floats near the bottom of the page instead of pointing at the button. The question is attached to the whole page, so iOS points it there.

This is a backlog fix, not a numbered roadmap milestone.

## What Changes

- **Spin on Star:** the star turns as it fills, in Find Shows and on the show page.
- **Spin on Follow:** the + turns a quarter turn into the check, in Find Shows and on the show page.
- Only following and starring spin. Unfollow and Unstar keep today's quick swap.
- A screen that opens or reloads with a show already followed or starred does not spin.
- With Reduce Motion on, nothing spins.
- On the show page, the Unfollow question points at the Following button.
- Version 0.5. It ships after 0.4.1 (instant controls), which isn't committed yet.

## Out of scope

- Removing the one-time star tip in Find Shows. The listener may decide that separately.
- Haptics.
- Animating other controls, such as the Queue, Inbox or episode row buttons.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `look-and-feel`: a new requirement for the Follow and Star spin.
- `show-page`: the Unfollow question points at the Following button.

## Impact

- `Casterr/Screens/Theme.swift`: one shared spin effect.
- `Casterr/Screens/DiscoverView.swift`: the row's star and + use it.
- `Casterr/Screens/ShowView.swift`: Follow and Star use it; the Unfollow question moves onto the Following button.
- `CHANGELOG.md` and `project.yml`: version 0.5.
- `openspec/device-checks.md`: how the spin feels and where the question points.
