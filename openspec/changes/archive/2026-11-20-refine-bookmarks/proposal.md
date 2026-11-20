# Proposal

## Why

The walkthrough of Bookmarks found that it was the only list without show art, that nothing said a tap plays a bookmark, and that editing a note was hidden behind a swipe and an alert. There was also no way to take all your notes out of the app at once. The decisions were picked from labeled mockups (A2 and B2).

## What Changes

- **Episode cards (A2):** each episode is one card, headed by the show art, the episode title, the show name, and its share button.
- **Play and edit in place (B2):** the time is a play button. Tapping the note edits it in the row; an empty note says "Add a note". The leading swipe and the note alert go away. Swipe left still deletes.
- **Gone episodes:** a bookmark whose episode left the feed shows a grey time, and a line under its card says it can't play.
- **Export All:** a share button in the title bar shares the listed bookmarks as one Markdown file.

## Capabilities

### Modified Capabilities

- `capture`: optional note, Bookmarks tab, and Markdown export.

## Out of scope

- Storing the show key on a bookmark. Art comes from the feed cache, so a bookmark whose episode is gone shows the show's initial.

## Impact

- `CasterrCore`: `BookmarkMarkdown.render(episodes:)` and `fileName(episodes:)`.
- App: `BookmarksView`.
