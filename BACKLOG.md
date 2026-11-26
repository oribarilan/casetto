# Backlog

Work we started and parked, and ideas we haven't started. Each entry says why it waits and where to pick it up.

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

## Listening sessions (added 2026-11-24)

The listener says how long they have ("I have 25 minutes") and Casterr plays Queue episodes that fit. Not started. It's on the after-MVP list in `podcast_app_concept.md`. Nothing blocks it.

## Transcripts (added 2026-11-24)

Show the episode's transcript in Now Playing. Use the feed's transcript when it has one; Apple's speech recognizer could fill in English shows that don't. Not started. It's on the after-MVP list.

## Topic-aware learning (added 2026-11-24)

Let rule cards judge an episode by its topic, using Apple's on-device model. Today learning uses behavior only. Not started. It waits for Smart bookmarks, which shows how fast and reliable the model is on the phone.

## Apple Watch (added 2026-11-24)

Control playback and bookmark from the watch. Not started. It's on the after-MVP list.

## App Store name check (added 2026-11-24)

Check the name Casterr for trademarks and on the App Store before launch. Not started. It's an open question in `podcast_app_concept.md` and must be settled before the public release.

## Long press actions (added 2026-11-26)

Support long press on items, for example in the Inbox, the Queue, and Shows, to open their actions. Not started. Findings: [docs/backlog/long-press.md](docs/backlog/long-press.md).

## Clear a show when unfollowing (added 2026-11-26)

When the listener unfollows a show, offer to clear it from Casterr, for example to remove its episodes from the Queue. Not started. The flow and design are still open. Findings: [docs/backlog/unfollow-clear.md](docs/backlog/unfollow-clear.md). On 2026-11-26 the app froze once around an unfollow and needed a force close; it didn't happen again, and the findings say what to capture next time.

## Small files and a pre-push hook (added 2026-11-26)

Keep files small and give each file and class a single responsibility. Add guidance to `AGENTS.md` with a limit, for example 700 lines at most, and a git pre-push hook that checks it. Not started. Two files are over 700 lines today: `CasterrUITests/ScreensTests.swift` (1122) and `CasterrCore/Sources/CasterrCore/Storage/Library.swift` (891). Findings: [docs/backlog/code-hygiene.md](docs/backlog/code-hygiene.md).

## Strict formatters and linters (added 2026-11-26)

Add strict formatters and linters, and treat warnings as errors. Not started. Findings: [docs/backlog/code-hygiene.md](docs/backlog/code-hygiene.md).

## Bug reports from Settings (added 2026-11-26)

Add a way to make a bug report from Settings, with guidance on how to get the file, so the listener can share it in a GitHub issue. The app should give that guidance and link to the issues page. Update the GitHub issue template (`.github/ISSUE_TEMPLATE/bug.yml` exists already) to say what to include and how to attach the file. The report must be anonymous, and the app and the template must tell the listener clearly what it contains and that it carries nothing personal. Not started.

## Flaky UI tests at cold start (added 2026-11-26)

Two UI test steps sometimes fail on the first run after the simulator starts, and pass when run again: testCapture, and tapping "Add by Feed Address" in the Shows tab's Add menu (seen in testInboxSwipeTip and testInboxCard). In the second case, the button isn't found in the menu yet. Not started. A fix could wait for the menu to finish opening before tapping, and find out why testCapture fails on a cold start.
