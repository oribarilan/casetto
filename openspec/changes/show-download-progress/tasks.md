## 1. State

- [x] 1.1 Report each download's fraction from `Downloader` and keep `downloadProgress` in `AppModel`, throttled, cleared when the file is saved or the task ends
- [x] 1.2 Watch the network with `NWPathMonitor` using the session's rules, and keep the wanted keys from the last download sync
- [x] 1.3 Add one `AppModel` helper that gives an episode's download state: downloaded, downloading with a fraction, waiting, or none

## 2. Rows

- [ ] 2.1 Replace `downloaded` with a download state in `EpisodeRow`: "Downloaded", "Downloading 45%" (whole percents, rounded down; no number without a size), "Waiting for Wi-Fi". Pass it from the Queue, Inbox and show page. Verify in the simulator with a download running
- [x] 2.2 Remove the backlog entry "Download status in the Queue"

## 3. Tests

- [x] 3.1 Add a core or unit test for the state helper's rules, and run the core and UI tests
- [x] 3.2 Add a device check: start the app on cellular, then join Wi-Fi; the top Queue rows go from "Waiting for Wi-Fi" to "Downloading N%" to "Downloaded"

## Workflow follow-up

- Move the device check to `openspec/device-checks.md` before archiving.
