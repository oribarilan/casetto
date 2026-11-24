## Why

Playing an Inbox episode on cellular moves it to the top of the Queue, inside the download range, so its row says "Waiting for Wi-Fi" while it streams fine. The words suggest something is wrong with the episode that's playing.

And when the listener needs a download away from Wi-Fi, for example at the gate before a flight, there's no way to get it. That need is always for the moment, so it belongs on the episode, not in a setting that has to be turned off again.

## What Changes

- The loaded episode (Playing or Paused) never says "Waiting for Wi-Fi", on any screen. It still says "Downloaded" or "Downloading 45%". Every other row keeps "Waiting for Wi-Fi".
- On cellular or another network downloads can't use, a row that should download but isn't offers **Download** in its action line, before Share. It downloads that one episode on the current network, Low Data Mode included, and Cassy says "Downloading on cellular, about 62 MB." The loaded episode offers it too.
- No new setting. The file follows the usual rule: it goes when the episode leaves the top of the Queue.
- The backlog entry "Waiting for Wi-Fi on the episode that's streaming" goes.

## Capabilities

### New Capabilities

### Modified Capabilities
- `downloads`: Wi-Fi only gains the per-episode Download; the Downloaded indicator leaves out "Waiting for Wi-Fi" on the loaded episode.

## Impact

`DownloadState.of` gains a loaded flag. `Downloader` gets a second background session that may use any network. `AppModel` tracks whether the phone has a network downloads can't use and starts a cellular download. The Queue and show page action lines gain the action. `DownloadTests` covers the new cases.
