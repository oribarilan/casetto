## ADDED Requirements

### Requirement: Voice boost
While voice boost is on, the system SHALL even out loud and quiet voices: it turns loud passages down and raises the whole level, so quiet voices come up and loud ones come down. Turning it on or off MUST take effect right away while playing, with no pause, skip, or change of position. It SHALL work for downloaded and streamed episodes. Back a Beat MUST judge quiet gaps from the audio before the boost.

#### Scenario: Quiet caller
- **WHEN** voice boost is on and a caller is much quieter than the host
- **THEN** the caller and the host play at closer loudness than with boost off

#### Scenario: Switch while playing
- **WHEN** the listener turns voice boost on at 12:30 while an episode plays
- **THEN** the boost is heard right away and playback continues from 12:30 without a pause

#### Scenario: Streamed episode
- **WHEN** voice boost is on and the listener streams an episode that isn't downloaded
- **THEN** the episode plays with the boost

#### Scenario: Back a Beat with boost on
- **WHEN** voice boost is on and the listener pauses and plays again
- **THEN** playback resumes at the same gap it would with boost off

#### Scenario: Boost can't start
- **WHEN** voice boost is on but the system can't process an episode's audio
- **THEN** the episode plays without the boost

### Requirement: Voice boost default and per-show override
Voice boost SHALL have a global default, off until the listener turns it on in Settings. The listener SHALL be able to turn it on or off for each show from Now Playing. A show without its own choice MUST follow the global default, including after the default changes. Now Playing MUST NOT change the global default.

#### Scenario: Show follows the default
- **WHEN** the global default is on and a show has no choice of its own
- **THEN** that show's episodes play with voice boost

#### Scenario: Show with its own choice
- **WHEN** a show is set to off and the global default is on
- **THEN** that show's episodes play without voice boost

#### Scenario: Global default changes
- **WHEN** the listener turns the global default on
- **THEN** every show without its own choice plays with voice boost, and shows with their own choice are unchanged

### Requirement: Voice boost in Now Playing
Now Playing SHALL show a round voice boost button with a waveform symbol, white while boost is on for the playing episode. Tapping it MUST open a menu titled "Voice boost: evens out loud and quiet voices" with "On for this show", "Off for this show", and "Use my default" followed by the default in parentheses. A check MUST mark the current choice. A choice applies right away, with no Done button.

#### Scenario: Turn it on for a show
- **WHEN** the default is off and the listener chooses "On for this show"
- **THEN** the episode plays with voice boost right away, the button turns white, and other shows keep the default

#### Scenario: Follow the default again
- **WHEN** a show is set to on, the default is off, and the listener chooses "Use my default (Off)"
- **THEN** the show's own choice is removed, the boost stops, and the button turns back from white

#### Scenario: Menu shows the default
- **WHEN** the global default is on and the listener opens the menu
- **THEN** the last item reads "Use my default (On)"
