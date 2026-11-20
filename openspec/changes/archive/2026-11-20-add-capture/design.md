# Design

## Context

User data lives in the synced store under the CloudKit rules: no unique attributes, every property optional or defaulted, no relationships. Bookmarks sync in M8 like the rest.

## Decisions

### D1. One flat model

`Bookmark` in the user store: `id: UUID`, `episodeKey`, `position`, `note` (empty means none), `createdAt`, and the snapshot fields `showTitle`, `episodeTitle`, and `audioURL`. No relationship to episodes, so the bookmark survives the feed cache and unsubscribing. `Library` hands out `BookmarkInfo` values.

### D2. Library operations

- `addBookmark(_ episode:, showTitle:, at:) -> UUID`
- `setNote(_:for:)` and `deleteBookmark(_:)`
- `bookmarks(matching:)` returns everything, or the bookmarks whose note, episode title, or show title contains the text, using `localizedStandardContains`. Filtering happens in memory: a listener has hundreds of bookmarks, not millions.

The view groups the results by episode key.

### D3. Markdown as a pure function

`BookmarkMarkdown.render(_:)` takes one episode's bookmarks and returns the file text:

```
# Episode title

Show title
<audio address>

- 12:34 great point
- 40:02
```

`BookmarkMarkdown.fileName(_:)` is "Show - Episode.md" with characters that file systems reject replaced. The share item is a `Transferable` with the Markdown type when the system knows it, otherwise plain text.

### D4. Capture flow

`AppModel.bookmark()` saves the Player's episode and position and sets `lastBookmark`. `RootView` shows a toast for 4 seconds with Add Note, which opens a note sheet. The bookmark buttons call `AppModel.bookmark()` and never touch playback.

### D5. Play from a bookmark

`Player.play(_:)` then `Player.seek(to:)`. When the episode isn't in the feed cache, the row shows "Not in the feed" and doesn't play.

## Risks / Trade-offs

- [The audio address in the snapshot can expire] → It's for reference in the export, not for playback.

## Migration Plan

A new model with defaults. Lightweight migration adds the table.
