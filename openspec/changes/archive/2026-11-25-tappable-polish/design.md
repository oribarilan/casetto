## Context

The show page header draws the description with `lineLimit(2)` and a separate "More"/"Less" button, always. SwiftUI doesn't say whether a `Text` was cut off.

## Decisions

**Find out whether the description is cut off by measuring it twice.** Behind the two-line text, an invisible copy of the full text with the same width and font measures its own height. If the full height is taller than the two-line height, the description is cut off. Both heights come from `onGeometryChange`, so a rotation or a Dynamic Type change measures again.

Alternative: count characters. A guess that breaks with Hebrew, big type, and narrow phones.

**The whole description is one button when it's cut off.** The text and the "Show more" words sit inside one plain-style button, so the whole area takes the tap and VoiceOver reads one button. The words keep the accent color; the text keeps its own color. When the description fits, it's plain text with no button.

**Accent color = `tangerine`, the tint.** The country name, "What's New" and "Show more" use the same tangerine as the chevron beside the country and as other tappable text, such as Clear Cache. The darker `tangerineText` shade was tried first: it passes text contrast, but next to the chevron the two oranges didn't match.

## Risks / Trade-offs

- [A short description is one line shorter than its placeholder, so the episodes move up a line when it arrives] → Accepted. The placeholder can't know the length ahead of time, and one line is a small move.
