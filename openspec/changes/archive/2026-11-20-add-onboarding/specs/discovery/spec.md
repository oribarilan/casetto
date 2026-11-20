# Spec Delta

## Purpose

Helps a new listener find and follow shows without knowing any feed address.

## ADDED Requirements

### Requirement: Top shows
The system SHALL list Apple's top podcasts for the listener's country, in chart order, from Apple's documented chart. Shows without a feed address MUST be left out.

#### Scenario: Browse top shows
- **WHEN** the listener opens the top shows
- **THEN** the list shows each show's title, author, and artwork in chart order

#### Scenario: Directory unreachable
- **WHEN** the chart can't be loaded
- **THEN** the system says the top shows couldn't be loaded and search still works

### Requirement: Search
The system SHALL search podcasts by name through the iTunes Search API from the Shows tab. A search MUST wait until typing pauses, so it stays within the API's rate limit.

#### Scenario: Search by name
- **WHEN** the listener types "planet money" and pauses
- **THEN** matching shows appear, each with a subscribe button

### Requirement: Subscribe and star from the directory
Each directory show SHALL offer Subscribe, which starts the show at the Inbox level, and Star, which subscribes at the Auto-queue level. Tapping Star again MUST return the show to the Inbox level. Tapping a subscribed show's Subscribe button again MUST unsubscribe.

#### Scenario: Star a show
- **WHEN** the listener stars a show they don't follow
- **THEN** the system subscribes to it at the Auto-queue level and its newest episode is in the Queue

#### Scenario: Subscribe without a star
- **WHEN** the listener subscribes to a show from search
- **THEN** its level is Inbox and its newest episode is in the Inbox

### Requirement: Onboarding
On first launch the system SHALL show a skippable screen with top shows and search. Whenever the listener follows no shows, the Shows tab SHALL show the same top shows and search.

#### Scenario: First launch
- **WHEN** the app launches for the first time
- **THEN** the onboarding screen shows, and Done or Skip closes it

#### Scenario: Unsubscribed from everything
- **WHEN** the listener follows no shows and opens the Shows tab
- **THEN** it shows the top shows and search
