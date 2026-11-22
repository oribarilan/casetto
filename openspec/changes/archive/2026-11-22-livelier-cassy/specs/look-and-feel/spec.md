## MODIFIED Requirements

### Requirement: Idle loops
When Cassy has no job to show, she SHALL play one of eight idle loops (blink, wink, look around, breathe, reel twitch, hum, yawn, peek) at random, 0.7 to 1.2 seconds after appearing and then 0.7 to 1.2 seconds after each loop ends, never the same loop twice in a row, so she moves most of the time. Reduce Motion MUST stop the loops.

#### Scenario: Rule card avatar
- **WHEN** a rule card stays on screen for a minute
- **THEN** Cassy plays many different loops with pauses of at most 1.2 seconds between them

#### Scenario: Welcome screen
- **WHEN** the welcome screen appears
- **THEN** Cassy starts a loop within 1.2 seconds and is moving most of the time she's on screen
