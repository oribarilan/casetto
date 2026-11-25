## MODIFIED Requirements

### Requirement: Follow and Star on the show page
The show page SHALL show two buttons under the header: Follow, or Following once followed, and Star, or Starred once starred. Star MUST work as in the directory: it stars the show, following it if needed, and tapping Starred removes only the star. Tapping Following MUST ask to confirm, then unfollow. The question MUST point at the Following button. The page's menu MUST NOT hold Unfollow.

#### Scenario: Star from the show page
- **WHEN** the listener follows Planet Money at the Inbox level and taps Star on its page
- **THEN** the button says Starred and the New episodes row says new episodes go to the end of the Queue

#### Scenario: Unstar from the show page
- **WHEN** the listener taps Starred on a show set to Queue
- **THEN** the button says Star and the New episodes row still says the end of the Queue

#### Scenario: Unfollow from the show page
- **WHEN** the listener taps Following on Planet Money's page and confirms Unfollow
- **THEN** Planet Money is no longer followed and its page shows Follow and Star

#### Scenario: Unfollow question points at Following
- **WHEN** the listener taps Following on Planet Money's page
- **THEN** the question "Episodes you queued stay in your Queue." opens pointing at the Following button
