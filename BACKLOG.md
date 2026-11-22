# Backlog

Work we started and parked. Each entry says why it waits and where to pick it up.

## CarPlay (parked 2026-11-20)

The code is in the active change `openspec/changes/add-carplay`. It builds and ships inert. It waits for a check in the simulator's CarPlay display, and real cars wait for Apple's CarPlay audio entitlement. Fix this first: `templateApplicationScene(_:didDisconnect:)` matches no protocol method, so disconnect never runs. The Swift name is `didDisconnectInterfaceController:`.

## Smart bookmarks (parked 2026-11-21)

When the listener taps Bookmark, transcribe the audio around the tap on the device and have Apple's on-device model write a one-line essence. It waits because Apple's on-device model was still downloading on the test phone, so we couldn't measure speed or the background limit there.

Decided so far:

- The essence and the note are one field. The model fills it, the listener can edit it, and a note the listener typed is never overwritten.
- No audio is stored. The bookmark jumps to the moment.
- The essence appears quietly in Bookmarks, with no alert.
- In the Markdown export, the essence is the heading and the transcript goes under it.
- English first. Hebrew isn't supported by Apple's speech recognizer (SpeechTranscriber) or model, so it gets the fallback.
- Fallbacks: with no Apple Intelligence, save the transcript only. With an unsupported language, save no transcript and let the listener type the essence.

Found in testing on the Mac:

- Transcription is fast: 2.5 minutes of audio in about 1.5 seconds.
- The model can't find where a thought starts and ends. Use a fixed window of 45 seconds before the tap to 15 seconds after, for both the transcript and the essence. On 8 taps it wrote 7 right essences and 1 close one. A rule that cuts at questions did worse, and ±30 seconds pulled in the next topic.
- Prompt: "You get a passage from a podcast. Write its main claim as one plain headline sentence of at most 15 words, in your own words. Use only what the passage says. Reply with the sentence only." Use `SystemLanguageModel(useCase: .general, guardrails: .permissiveContentTransformations)`, greedy sampling, a plain String reply, and strip `*`. Don't put an example in the prompt: the model copied it word for word. Don't use `@Generable`: Apple's content filter blocks it on news.
- A streamed episode needs the last 45 seconds of audio kept in memory (about 4 MB as mono 16-bit at 48 kHz) from the audio tap Back a Beat already uses. A downloaded episode can read the file.

Next: on a phone with the model downloaded, measure transcription and essence time, and check whether the model still answers while Casterr plays audio in the background on battery. Apple rate-limits the model for apps in the background. Then write the OpenSpec proposal.

## Skip silences (parked 2026-11-21)

Shorten long pauses while an episode plays. It waits because Apple's player (AVPlayer) can't drop audio: the audio tap must return as much sound as it receives. Two ways to try later. One is to raise the speed briefly while a pause plays; first test on the simulator how far ahead of the speaker the tap hears the sound, because a late speed change clips words. The other is our own audio pipeline (AVAudioEngine), which can really cut pauses but is a big rewrite and makes streaming harder.


## Bookmark toast and Add Note (logged 2026-11-22)

A bug the listener found on the phone, to discuss before fixing. After tapping Bookmark in Now Playing, the toast's Add Note button asks for the note right there in Now Playing, and that is buggy: the note's input line is pushed partly off the top of the screen. Even working well, a note field in Now Playing feels unnatural to them; the note belongs in Bookmarks. What they want instead:

- Add Note opens that bookmark in Bookmarks with its note field focused, as if they had gone there and tapped it themselves.
- A tap anywhere else on the toast opens that bookmark in Bookmarks.

## Speed sheet redesign (logged 2026-11-22)

The Now Playing speed sheet (`SpeedSheet` in `NowPlayingView.swift`) is misleading. Today the slider shows only after "Use my default" is turned off, so the listener has to flip a switch before they can change the speed. What they want instead:

- The speed control is always there. Moving it away from the default turns "Use my default" off by itself.
- Turning "Use my default" on jumps the speed back to the default.
- At the default speed, the switch can be turned on or off freely.

Before building, show the listener a few designs that solve this, as images with a key on each option.

## Versions, changelog and What's New (logged 2026-11-22)

To do, not started. Today every build is version 0.1 (1), and nothing tells the listener what changed.

- Semantic versioning (major.minor.patch) for the app's version.
- A changelog in the repository, one entry per version.
- A What's New screen in the app after an update, drawn from the changelog.
- The version shown in Settings.

Before building, decide how a release is cut (who bumps the version, and when) and what What's New shows, then write an OpenSpec proposal.

## Sharing fixes (logged 2026-11-22)

Found on the phone:

- The share should show only the show name and the episode name.
- The artwork in a shared clip is very low quality.
- "Share Clip…" should lose its three dots: "Share Clip".
- Share Episode should share the whole episode with the show name, the episode name, and an Apple Podcasts link or something like it.

## Waveform in clips (logged 2026-11-22)

A shared clip video has no waveform today. Add one.

## Handle on Now Playing (logged 2026-11-22)

The Now Playing sheet shows no grab handle. Nobody chose that: it's a plain full-height sheet, and iOS shows the handle by default only on sheets that stop at more than one height. Swiping down still closes it. Showing the handle is one line in `RootView.swift`: `.presentationDragIndicator(.visible)` on the Now Playing sheet.

## Speed, voice boost and sleep timer controls (logged 2026-11-22)

- The three Now Playing controls (speed, voice boost, sleep timer) don't look or work alike. Make them uniform.
- When the episode has chapters, the sleep timer offers "After current chapter (3 min)", with the time left in the chapter.

## Download status in the Queue (logged 2026-11-22)

Show each Queue episode's download status and progress in the Queue view.

## Cassy's entrance and exit while the Queue loads (logged 2026-11-22)

While the Queue loads, Cassy pops in and then vanishes. Explore a nicer animation for her appearing and disappearing.

## Find Shows card reacts to this visit (logged 2026-11-22)

Cassy's card in Find Shows should react to what the listener does during this visit. Today it says "Nice pick!" whenever any followed show is starred, so once you've ever starred a show it always cheers (`starred` in `DiscoverView.swift` checks every subscription).

## Download space next to Keep downloaded (logged 2026-11-22)

Show how much space the downloads take where the listener picks Keep downloaded, for example "about 210 MB" under the current choice, estimated by adding up the file sizes the feed lists for the top N Queue episodes. Decided against a separate megabyte cap: two limits need a rule for which wins, and an episode that silently doesn't download would need explaining in the Queue.
