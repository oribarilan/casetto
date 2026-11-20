# Spec Delta

## ADDED Requirements

### Requirement: One word per idea
All text in the app SHALL use one word per idea: "Remove" when an episode leaves the Inbox or Queue, by the listener or automatically; "Skip" for a show whose new episodes never enter them; "Dismiss" only for Cassy's cards and tips; and "Delete" only for bookmarks. The word "archive" MUST NOT appear in the app.

#### Scenario: Removing from the Queue
- **WHEN** the listener swipes a Queue episode left
- **THEN** the action says "Remove", not "Delete"

#### Scenario: Automatic removal
- **WHEN** an Inbox episode expires after 7 days
- **THEN** its row reads "Removed after 7 days" and the refresh summary says "removed 1 old one from your Inbox"
