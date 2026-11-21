## ADDED Requirements

### Requirement: Queue shows episodes this device has
A device's Queue SHALL list only the queued episodes whose show and episode that device knows. An episode queued on another device, such as a shared file or an episode of a show the listener doesn't follow, MUST be skipped in the list, in the up-next bar, and when choosing what plays next. The others MUST keep their order, and moving an episode or choosing Play next MUST count only the episodes the device shows.

#### Scenario: Shared file queued on another device
- **WHEN** the phone's Queue is a shared file, then two episodes of followed shows, and the listener opens the iPad
- **THEN** the iPad's Queue lists the two episodes in order, and pressing play starts the first of them
