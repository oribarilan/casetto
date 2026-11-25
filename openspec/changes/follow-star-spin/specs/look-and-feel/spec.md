## ADDED Requirements

### Requirement: Follow and Star spin
When the listener follows or stars a show, in Find Shows or on the show page, the button's icon SHALL spin into its new state: the star MUST turn as it fills, and the plus MUST turn a quarter turn into the check. Unfollow and Unstar MUST NOT spin. An icon MUST NOT spin when a screen opens or reloads with a show already followed or starred. With Reduce Motion on, the icons MUST change without spinning.

#### Scenario: Star in Find Shows
- **WHEN** the listener taps the star on Planet Money in Find Shows
- **THEN** the star turns as it fills

#### Scenario: Follow on the show page
- **WHEN** the listener taps Follow on Planet Money's page
- **THEN** the plus turns into the check and the button says Following

#### Scenario: Unstar stays quiet
- **WHEN** the listener taps Starred on Planet Money's page
- **THEN** the icon changes to the empty star without spinning

#### Scenario: Opening a followed show
- **WHEN** the listener opens the page of a show they already follow and starred
- **THEN** Following and Starred show without spinning

#### Scenario: Reduce Motion
- **WHEN** Reduce Motion is on and the listener stars a show
- **THEN** the star fills without spinning
