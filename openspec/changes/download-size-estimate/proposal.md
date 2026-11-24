## Why

When the listener picks how many Queue episodes to keep downloaded, nothing says how much space that takes. Ten long episodes can be a gigabyte.

## What Changes

- Under the Keep downloaded picker, a gray line says how much the choice takes: "About 210 MB for the top 3." It changes as the listener taps another choice.
- The number adds up the file sizes the feeds list for the top Queue episodes, downloaded or not. When a feed gives no size or an implausible one, Casterr estimates from the episode's length at 128 kbps. Shared files don't count; they're already on the phone.
- Off, or an empty Queue, shows no line.
- No megabyte cap, as decided in the backlog: two limits would need a rule for which wins.
- The backlog entry goes.

## Capabilities

### New Capabilities

### Modified Capabilities
- `settings`: a new requirement for the download size line.

## Impact

`FeedParser` reads the enclosure's length, `EpisodeRecord` and `EpisodeInfo` keep it (a new optional field; existing episodes fill in on the next refresh), a size estimate in CasterrCore with tests, a Library query for the top Queue episodes, and the Settings Downloads row.
