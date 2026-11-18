# Spec Delta

## Purpose

Lets the listener follow podcast shows from their public RSS feeds, keeps each show's episodes current, and gives every show and episode a stable identity that survives re-fetching.

## ADDED Requirements

### Requirement: Subscribe by RSS URL
The system SHALL let the listener subscribe to a show by entering its RSS feed URL. The system MUST fetch and parse the feed before it confirms the subscription.

#### Scenario: Valid feed URL
- **WHEN** the listener enters the URL of a valid podcast RSS feed
- **THEN** the system subscribes to the show and shows its title, artwork, and episodes

#### Scenario: URL that is not a podcast feed
- **WHEN** the listener enters a URL that does not return a parsable RSS feed with audio enclosures
- **THEN** the system does not subscribe and tells the listener that the URL is not a podcast feed

#### Scenario: Feed unreachable
- **WHEN** the feed URL cannot be fetched because of a network or server error
- **THEN** the system does not subscribe and tells the listener that the feed could not be reached

#### Scenario: Already subscribed
- **WHEN** the listener enters a feed URL for a show they already follow
- **THEN** the system does not create a second subscription and opens the existing show

### Requirement: Import subscriptions from OPML
The system SHALL let the listener import an OPML file and subscribe to every feed it lists. One bad feed MUST NOT stop the import of the others.

#### Scenario: OPML with valid feeds
- **WHEN** the listener imports an OPML file that lists 30 valid feeds
- **THEN** the system subscribes to all 30 shows

#### Scenario: OPML with some failing feeds
- **WHEN** an imported OPML file lists feeds where some cannot be fetched or parsed
- **THEN** the system subscribes to the feeds that work and lists the ones that failed with the reason for each

#### Scenario: OPML with feeds already followed
- **WHEN** an imported OPML file lists shows the listener already follows
- **THEN** the system skips them without creating duplicates

#### Scenario: File that is not OPML
- **WHEN** the listener picks a file that is not valid OPML
- **THEN** the system imports nothing and tells the listener that the file is not an OPML file

### Requirement: New subscription places no episodes
In this milestone, subscribing SHALL NOT put any episode in the Queue. The show's episodes appear on its show page.

#### Scenario: Subscribe to a show with a back catalog
- **WHEN** the listener subscribes to a show with 200 published episodes
- **THEN** the Queue is unchanged and the show page lists all 200 episodes, newest first

### Requirement: Unsubscribe
The system SHALL let the listener unsubscribe from a show. Episodes of that show that are in the Queue MUST stay in the Queue.

#### Scenario: Unsubscribe with queued episodes
- **WHEN** the listener unsubscribes from a show that has 2 episodes in the Queue
- **THEN** the show leaves the subscription list and both episodes stay in the Queue in their positions

#### Scenario: Feed stops refreshing
- **WHEN** the listener has unsubscribed from a show
- **THEN** the system no longer fetches that show's feed

### Requirement: Refresh feeds
The system SHALL refresh all subscribed feeds when the app comes to the foreground and when the listener pulls to refresh. A refresh MUST NOT block playback or the user interface, and a feed that fails MUST NOT stop the others.

#### Scenario: New episode published
- **WHEN** a subscribed feed has a new episode and the app comes to the foreground
- **THEN** the new episode appears on the show page

#### Scenario: One feed fails
- **WHEN** one subscribed feed returns an error during a refresh
- **THEN** the other feeds still refresh and the failing show displays when it last refreshed successfully

### Requirement: Stable show identity
The system SHALL identify a show by its normalized feed URL at the time of subscribing. That identity MUST NOT change afterward. When a feed declares a new feed URL, the system MUST keep the same show and the same subscription.

#### Scenario: Feed moves to a new URL
- **WHEN** a subscribed feed declares a new feed URL with `itunes:new-feed-url`
- **THEN** the system fetches the new URL from then on and the subscription and queued episodes are unchanged

#### Scenario: Same feed with a different URL form
- **WHEN** the listener subscribes to a URL that differs from an existing subscription only in scheme, letter case of the host, or a trailing slash
- **THEN** the system treats it as the same show

### Requirement: Stable episode identity
The system SHALL identify an episode within its show by the feed item's GUID, and otherwise by its audio URL. Re-fetching a feed MUST NOT create duplicate episodes or lose the listener's progress or Queue position.

#### Scenario: Publisher edits an episode
- **WHEN** a refreshed feed changes an episode's title or description but keeps its GUID
- **THEN** the system updates the episode in place and keeps its progress and Queue position

#### Scenario: Episode without a GUID
- **WHEN** a feed item has no GUID
- **THEN** the system identifies it by its audio URL

#### Scenario: Feed data wiped
- **WHEN** the cached feed data is deleted and every feed is fetched again
- **THEN** every subscription, Queue entry, and progress value still refers to the correct episode
