# Design

## Context

`ShowView.load()` reads every episode and its state in one go, which stays fast (80 to 150 ms for 2,787 episodes). The body filters `episodes` twice per draw, once for played and once for the rest, and hands every row to the `List`. The open and scroll cost grows with the row count.

## Decisions

**Limit the rows, not the read.** Two `@State` counts, `shownEpisodes` and `shownPlayed`, start at 30. The body splits `episodes` into played and unplayed once, then draws `prefix(shown…)` of each. Reading everything keeps the Played count, the row actions and the Queue links right with no extra queries. Another option, paging the database read, would need new `Library` queries and a total count for Played, for a read that already takes a tenth of a second.

**A plain row at the end of each list.** "Show older episodes" is a `Button` row styled like the list's other text buttons, with the accent color. A tap adds 30 inside `withAnimation` so the new rows slide in under the old ones. It's absent when nothing is left. Another option, loading more when the last row appears, is common but less predictable and harder to test.

**Each visit starts at 30.** The counts are view state, so they reset when the page is opened again. The listener's place within one visit is kept.

**Batch size is a constant,** `ShowView.batch = 30`, so it's easy to tune from real use.

## Risks / Trade-offs

- [An episode the listener wants is older than 30] → One or more taps on "Show older episodes". Search within a show isn't part of this change.
- [The simulator numbers are rough] → After the change, the same Joe Rogan measurement runs again for a before and after, and the phone check covers the feel.
