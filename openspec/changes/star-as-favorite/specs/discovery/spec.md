## MODIFIED Requirements

### Requirement: Subscribe and star from the directory
Each directory show SHALL offer Follow, which starts the show at the Inbox level, and Star, which follows it starred, with new episodes going to the Queue. Tapping Star again MUST remove only the star. Tapping a followed show's Follow button again MUST unfollow. Tapping the rest of the row MUST open the show's page.

#### Scenario: Star a show
- **WHEN** the listener stars a show they don't follow
- **THEN** the system follows it starred, at the Auto-queue level, and its newest episode is in the Queue

#### Scenario: Subscribe without a star
- **WHEN** the listener follows a show from search with Follow
- **THEN** its level is Inbox and its newest episode is in the Inbox

#### Scenario: Open a show from Find Shows
- **WHEN** the listener taps the title of a show they don't follow in Find Shows
- **THEN** the show's page opens with its episodes, and the show stays unfollowed
