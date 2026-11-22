## MODIFIED Requirements

### Requirement: Page of a show you don't follow
The page of a show the listener doesn't follow, reached from a shared episode in Now Playing or from Find Shows, SHALL show the show header, the Follow and Star buttons, and the show's episodes, fetching its feed without following it when the device doesn't have it. It MUST NOT show the new-episode settings. Following MUST work like following from the directory.

#### Scenario: Subscribe from a shared episode
- **WHEN** the listener plays a shared ATP episode, taps "Accidental Tech Podcast" in Now Playing, and taps Follow
- **THEN** ATP is followed, its page shows the new-episode settings, and the shared episode keeps its place in the Queue

## ADDED Requirements

### Requirement: Follow and Star on the show page
The show page SHALL show two buttons under the header: Follow, or Following once followed, and Star, or Starred once starred. Star MUST work as in the directory: it follows the show at the Auto-queue level, and tapping Starred returns it to the Inbox level. Tapping Following MUST ask to confirm, then unfollow. The page's menu MUST NOT hold Unfollow.

#### Scenario: Star from the show page
- **WHEN** the listener follows Planet Money at the Inbox level and taps Star on its page
- **THEN** the button says Starred and the New episodes row says new episodes go to the end of the Queue

#### Scenario: Unfollow from the show page
- **WHEN** the listener taps Following on Planet Money's page and confirms Unfollow
- **THEN** Planet Money is no longer followed and its page shows Follow and Star
