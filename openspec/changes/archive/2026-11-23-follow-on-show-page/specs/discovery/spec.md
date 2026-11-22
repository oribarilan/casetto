## MODIFIED Requirements

### Requirement: Subscribe and star from the directory
Each directory show SHALL offer Follow, which starts the show at the Inbox level, and Star, which follows it at the Auto-queue level. Tapping Star again MUST return the show to the Inbox level. Tapping a followed show's Follow button again MUST unfollow. Tapping the rest of the row MUST open the show's page.

#### Scenario: Star a show
- **WHEN** the listener stars a show they don't follow
- **THEN** the system follows it at the Auto-queue level and its newest episode is in the Queue

#### Scenario: Subscribe without a star
- **WHEN** the listener follows a show from search with Follow
- **THEN** its level is Inbox and its newest episode is in the Inbox

#### Scenario: Open a show from Find Shows
- **WHEN** the listener taps the title of a show they don't follow in Find Shows
- **THEN** the show's page opens with its episodes, and the show stays unfollowed

### Requirement: Find Shows after onboarding
The Shows tab's + menu SHALL offer Find Shows as its first item. It MUST open the onboarding's Find Shows screen, with the top shows, search, Follow and Star, as a sheet without the welcome screen, closed with Done.

#### Scenario: Open from the + menu
- **WHEN** the listener follows shows and picks Find Shows from the + menu
- **THEN** a sheet titled "Find Shows" shows the top shows and search, and Done closes it
