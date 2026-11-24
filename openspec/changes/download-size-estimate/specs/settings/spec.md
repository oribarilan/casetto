## ADDED Requirements

### Requirement: Download size
Under the Keep downloaded picker, Settings SHALL say how much space the current choice takes: "About 210 MB for the top 3." It MUST add up the sizes the feeds list for that many top Queue episodes, downloaded or not, and estimate an episode at 128 kbps from its length when its feed gives no plausible size. Shared files MUST NOT count. Off, or nothing to count, MUST show no line.

#### Scenario: Pick a choice
- **WHEN** the Queue starts with three episodes of 70 MB each and the listener picks 3
- **THEN** the line reads "About 210 MB for the top 3"

#### Scenario: Tap another choice
- **WHEN** the listener taps 10 with only five episodes in the Queue
- **THEN** the line adds up those five and still says "for the top 10"

#### Scenario: No size in the feed
- **WHEN** an episode's feed lists no file size and the episode is 60 minutes long
- **THEN** it counts as about 58 MB

#### Scenario: Off
- **WHEN** the listener picks Off
- **THEN** no size line shows
