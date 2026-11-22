## MODIFIED Requirements

### Requirement: Clear cache
Settings SHALL have a Storage section with Clear Cache, showing how much space the saved show art and popular lists take. Tapping it MUST delete them, so they download again when needed, and MUST confirm with a checkmark and "Cleared" for a moment. Downloaded episodes, bookmarks, and shared files MUST stay. The section MUST also show the space downloaded episodes take, with no action.

#### Scenario: Clear the cache
- **WHEN** the listener taps Clear Cache
- **THEN** the button shows a checkmark and "Cleared", the size shown drops within a few seconds, downloaded episodes stay, and show art downloads again the next time it appears

#### Scenario: Downloads size
- **WHEN** three Queue episodes of about 70 MB each are downloaded and the listener opens Settings
- **THEN** Storage shows "Downloaded episodes" with about 210 MB, and no button to delete them
