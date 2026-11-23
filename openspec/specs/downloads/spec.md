# downloads Specification

## Purpose
Keeps the episodes you're about to hear on the phone, so they play without a connection.

## Requirements

### Requirement: Downloads follow the top of the Queue
The system SHALL keep the first N Queue episodes downloaded, where N is a setting with the choices Off, 1, 3, 5, and 10, and a default of 3. The system MUST delete the file of every episode outside the first N. The system SHALL check the downloads after every Queue change, after every refresh, and when the app opens.

#### Scenario: Queue longer than the setting
- **WHEN** the Queue holds 5 episodes and the setting is 3
- **THEN** the first 3 episodes are downloaded and the other 2 are not

#### Scenario: Episode pushed down
- **WHEN** the listener moves a downloaded episode from position 2 to position 5 and the setting is 3
- **THEN** its file is deleted and the episode that moved into position 3 downloads

#### Scenario: Episode played
- **WHEN** a downloaded episode is played to the end
- **THEN** its file is deleted

#### Scenario: Off
- **WHEN** the listener sets downloads to Off
- **THEN** every downloaded file is deleted and no download starts

### Requirement: Wi-Fi only
Downloads MUST NOT use cellular data, Personal Hotspot, or a network in Low Data Mode. Episodes that aren't downloaded MUST still stream on any network.

#### Scenario: On cellular
- **WHEN** a Queue episode needs a download and the phone is on cellular data
- **THEN** the download waits until Wi-Fi is available, and the episode still streams if the listener plays it

### Requirement: Downloads continue in the background
A download SHALL continue while the app is in the background or closed by the system.

#### Scenario: App closed during a download
- **WHEN** a download is running on Wi-Fi and the listener leaves the app
- **THEN** the download completes and the episode shows as downloaded the next time the app opens

### Requirement: Downloaded indicator
Every episode row in the Queue, the Inbox and on show pages SHALL say "Downloaded" in its status line when the episode's file is on the phone, "Downloading" with the percent done while it downloads, and "Waiting for Wi-Fi" when it should download but the phone isn't on a network downloads may use.

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
