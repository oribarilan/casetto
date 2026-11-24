## MODIFIED Requirements

### Requirement: Wi-Fi only
Downloads MUST NOT use cellular data, Personal Hotspot, or a network in Low Data Mode unless the listener asks for that episode. Episodes that aren't downloaded MUST still stream on any network. On such a network, a row that should download but isn't SHALL offer Download in its action line, before Share. It MUST download only that episode, on the current network, Low Data Mode included, and Cassy MUST say it's on cellular, with the size when known. It SHALL add no setting.

#### Scenario: On cellular
- **WHEN** a Queue episode needs a download and the phone is on cellular data
- **THEN** the download waits until Wi-Fi is available, and the episode still streams if the listener plays it

#### Scenario: Download on Cellular
- **WHEN** the phone is on cellular, the second Queue episode says "Waiting for Wi-Fi", and the listener taps Download in its line
- **THEN** that episode downloads, its row says "Downloading" with the percent, Cassy says "Downloading on cellular, about 62 MB.", and the third episode keeps waiting for Wi-Fi

#### Scenario: Offline
- **WHEN** the phone has no network and a Queue episode is waiting for Wi-Fi
- **THEN** its line has no Download

#### Scenario: On Wi-Fi
- **WHEN** the phone is on Wi-Fi
- **THEN** no line has Download

### Requirement: Downloaded indicator
Every episode row in the Queue, the Inbox and on show pages SHALL say "Downloaded" in its status line when the episode's file is on the phone, "Downloading" with the percent done while it downloads, and "Waiting for Wi-Fi" when it should download but the phone isn't on a network downloads may use. The loaded episode, playing or paused, MUST NOT say "Waiting for Wi-Fi".

#### Scenario: Downloaded episode in the Queue
- **WHEN** a Queue episode's download is complete
- **THEN** its Queue row says "Downloaded"

#### Scenario: Downloaded episode on its show page
- **WHEN** the listener opens the show page of a downloaded Queue episode
- **THEN** its row reads "Queued · Downloaded"

#### Scenario: Download in progress
- **WHEN** a Queue episode's download is 45% done
- **THEN** its row says "Downloading 45%", and the number rises as it downloads

#### Scenario: Away from Wi-Fi
- **WHEN** the phone is on cellular and the second Queue episode isn't downloaded yet
- **THEN** its row says "Waiting for Wi-Fi"

#### Scenario: Streaming on cellular
- **WHEN** the phone is on cellular and the listener plays an Inbox episode that isn't downloaded
- **THEN** its Queue row reads "Playing" with no download words, and its line offers Download
