# Device checks

Checks that need a real iPhone. They came from changes that are otherwise done and archived. Tick each one here after running it on a phone.


## M1 · Player core

- [ ] 5.3 Handle interruptions and route changes (pause during a call, resume when the system says to, pause when headphones disconnect), and verify on a device against the background-audio spec scenarios
- [ ] 5.4 Integrate system controls with the Now Playing framework (`MediaSession`): metadata, play, pause, skip 30 seconds forward and 15 back, seek. Verify the lock screen, Control Center, and headphone scenarios on a device. Switch to the MediaPlayer APIs only if a scenario is blocked, and record why in design.md
- [ ] 6.3 Build the OPML import flow (file picker, then a report sheet listing failed feeds and reasons), and verify by hand with the fixture OPML files
- [ ] 7.1 On a real device, import a real OPML export with 20+ shows, queue 5 episodes, listen with the phone locked, take a call, force-quit, and reopen. Verify that every M1 spec scenario holds, and list any failures as new tasks

## M3 · Downloads and refresh

- [ ] 3.2 Device check (needs the listener's phone): a download completes after leaving the app, a downloaded episode plays in airplane mode, a played or removed episode loses its file (the icon moves to the next episode), a cellular-only phone starts no download, and a background refresh triggered from the debugger logs "Background refresh started" and queues and downloads a new Auto-queue episode

## M8 · CloudKit sync

- [ ] 3.1 Phone check (needs the listener's setup): subscribe on a set-up phone and see the record in the CloudKit dashboard; queue an episode in the dashboard or on a second device and see it after reopening the app; reinstall and see the data return

## From the redesign

- [ ] Dizzy Cassy on a failing feed, and the end-of-Queue offer after the last episode finishes (not reachable in the UI tests).
- [ ] The exported OPML file arrives in Files or another app through the share sheet.

## Now Playing and Bookmarks

- [ ] A 15-minute sleep timer counts down on the moon button with the phone locked and unlocked, and playback pauses when it reaches 0:00.
- [ ] Export All and an episode's export arrive in Files or a notes app as Markdown files through the share sheet.

## CarPlay

- [ ] Needs Apple's CarPlay audio entitlement on the App ID first. In a real car or a CarPlay head unit: the Queue list shows with art and the playing marker, tapping an episode plays it and opens Now Playing, the car's play, pause, and skip controls work, Speed steps by 0.1x and is saved for that show, and Bookmark fills for 2 seconds and the bookmark appears on the phone.

## Back a Beat

- [ ] With headphones, pause a talk show mid-sentence about 10 times (Pause button, headphones, lock screen, and once with a phone call) and resume each time. Playback restarts at a pause between phrases, not inside a word, a few seconds back. Do it once on a downloaded episode and once on a streamed one, and once at 1.5x.
- [ ] At 2x, pause mid-sentence and resume a few times: Back a Beat still restarts between phrases. Then drag the speed slider from 1.0x to 2.0x and back while playing: the elapsed time keeps moving and never freezes.

- [ ] After the Back a Beat fix: pause a few times during a silence between phrases, once a few seconds into a long silence, and once right after moving the slider and unplugging the headphones. Each resume goes back to an earlier gap (or stays put after the slider move), and never lands later than the pause. Do it on a streamed MP3 (for example Planet Money), on a downloaded one, and at 2x.

## Voice boost

- [ ] With headphones, play a show with a quiet guest or caller (for example וויקלי סינק) and switch voice boost on and off from Now Playing while it plays: the quiet voice gets close to the loud one, the switch is immediate, and nothing distorts. Do it once streamed and once downloaded. With boost on, change speed from 1x to 2x and back: the elapsed time keeps moving. Pause and resume with boost on: Back a Beat still restarts between phrases.

## Chapters

- [ ] Play an ATP or Connected episode (chapters in the file), streamed and downloaded: the pill shows the chapter and fills as it plays, the list marks played chapters and shows the time left in the playing one, a tap jumps there, and a chapter with its own picture shows it in place of the show art. Then play a וויקלי סינק episode (chapters from the show notes): the Hebrew titles line up on the right and jumping works.

## Sharing to Casterr

- [ ] Needs an Apple account signed in to Xcode first (App Groups need an explicit App ID). Share an MP3 from Files, a voice note from WhatsApp and one from Telegram, and an Apple Podcasts episode link from Messages: each shows the "Up next in your Queue" card with the right title and lands right after Now Playing. Share once while Casterr plays in the background: it arrives within a few seconds without interrupting. Delete a shared file on the Shared with Casterr page. On a second device, the shared file doesn't appear, and its bookmark shows with play disabled.

## Sharing from Casterr

- [ ] After the sharing fix: share an episode and a clip to Messages and to WhatsApp. The text is just "Episode – Show". The pod.link link opens that episode and lets you pick an app; try a brand-new episode and an older one, and note if a new one takes a while to appear. The clip's art looks sharp in both apps.
- [ ] Share a clip to WhatsApp: the video plays inline with the art and the badge, and check whether the caption with the link arrives. Make one clip of a streamed episode and one of a downloaded one, and listen that each starts and ends between words and matches what you heard (try an ad-inserting show such as Planet Money). Share Episode to Messages and check its preview, and Share Show. Check the loudness bars make pauses easy to see on a calm show, and tune `LoudnessBars.range` if not.

## Episode rows

- [ ] In the Queue, the Inbox and a show page, tap rows quickly one after another: the action line opens under each, moves smoothly, the buttons spring in, and nothing jumps. With Reduce Motion on, the buttons appear without the bounce. With VoiceOver, a row reads its status words and "Shows actions", and every button in the line is reachable. Share from a line opens the share sheet with the show's art.

## Stars

- [ ] Star and unstar shows from Find Shows and a show page, then change a starred show's New episodes setting: it stays starred and stays at the top of the Shows tab under Starred. With VoiceOver, an episode of a starred show in the Queue starts with "Starred".

## Refresh progress

- [ ] With all your shows, open the app from closed and pull to refresh on the Queue: the thin line under the title fills in steps as shows are checked, fills to the end, and fades out, and the list never moves. With VoiceOver, the line reads "Checking for new episodes" with a percentage.

## Download progress

- [ ] Open the app on cellular with Keep downloaded at 3 and new episodes at the top of the Queue: those rows say "Waiting for Wi-Fi". Join Wi-Fi: they change to "Downloading N%", the number rises, and then they say "Downloaded". The same words show for those episodes in the Inbox and on their show pages.

## Restoring the paused episode

- [ ] Play an episode for a minute, force quit Casterr, and reopen it: the mini player shows that episode paused (with no bookmark button), tapping it opens Now Playing at the same spot, and play resumes there without jumping back. Queue a brand-new episode at the top instead: the bar says "Up next · from your Queue" and opens the Queue.

## Waveforms

- [ ] Play a talk show with Now Playing open: the big pause button's bars fill with tangerine and move with the mini player's. With Reduce Motion on, both are plain pause icons. Share a 30-second clip to Messages and WhatsApp: the waveform along the bottom fills tangerine in time with the audio, and making the clip takes no more than a few seconds longer than before.

## Download on cellular

- On cellular, play an Inbox episode that isn't downloaded: its Queue row reads "Playing" with no "Waiting for Wi-Fi", and its line offers Download.
- On cellular, tap Download on the second Queue row: Cassy says "Downloading on cellular" with the size, only that row says "Downloading" with a rising percent, the third keeps "Waiting for Wi-Fi", and the file finishes.
- On Wi-Fi, and in Airplane Mode, no line offers Download.

## Download size

- In Settings, Keep downloaded shows "About … MB for the top 3." Tap 1, 5 and 10: the line follows, and for the current choice it's close to "Downloaded episodes" in Storage once the downloads finish.

## What's New

- Install a TestFlight build with a higher version over an older one: about a second after launch Cassy says "I learned some new tricks." and See opens What's New with only the new versions. Relaunch: no toast.
- Settings ends with About, "Version …" and the build number as the TestFlight build number; tapping it lists every version.

## Headphone and car buttons

- With AirPods in and an episode playing, double press: a chime plays over the episode, playback continues, and the bookmark is in Bookmarks. Triple press: playback goes back 15. Repeat with silent mode on: the chime still plays.
- While an episode plays, the lock screen and Dynamic Island show the 15 and 30 buttons, not next and previous track.
- In Settings, set Triple press to Skip forward 30: the next triple press skips forward. On a second iPhone on the same iCloud account, the choice arrives after a sync.
- In the car: the steering wheel's next and previous buttons follow the two choices, and the CarPlay Dashboard still shows 15 and 30.

## Show page while loading

- On cellular, open a show from Find Shows that you don't follow: its name, host and art show at once, the description and four episode rows shimmer, and then they fill in without the Follow button or the Episodes heading moving. The art doesn't flash or reload. Repeat in dark mode and with Reduce Motion on (the placeholders stay still).

## Long episode lists

- Open a show you follow with a long history (The Joe Rogan Experience has about 2,800 episodes): the page opens without a pause, scrolling is smooth, and the list ends after 30 episodes with "Show older episodes". Tap it: 30 more appear below without the list jumping. Open Played on a show with many played episodes: it works the same, and its count still counts all of them.

## Instant controls

- On a show page, open the new episodes settings and tap each tile, "Use my default", and a day: each lights up the moment you tap, on a show with a long history too.
- Follow a big show from Find Shows and from its page: the button says Following at once, and the episodes arrive a few seconds later. In Airplane Mode, Follow goes back to Follow. Star and Unstar flip at once in both places.
- In Settings, tap a new value for Remove unplayed episodes after, Keep downloaded, and Default speed: each shows at once.

## Follow and Star spin

- In Find Shows, tap the star on a show you don't follow: the star turns as it fills and the + turns into the check. Tap the + on another show: only the check turns in. Unstar and Unfollow swap without spinning.
- On a show page, tap Follow, then Star: each icon spins in. Tap Starred: no spin. Go back and open the page again: Following and Starred show without spinning.
- With Reduce Motion on (Settings > Accessibility > Motion), Follow and Star change without spinning.
- In light and dark mode, Following looks the same as before: a pale tangerine capsule with tangerine text.
- Tap Following: the Unfollow question opens pointing at the button.

## Tappable polish

- Open a show with a long description: two lines, then Show more. Tap anywhere on the text: it opens, with Show less. Tap again: it folds.
- Open a show whose description fits in two lines: no Show more, and tapping it does nothing.
- On Find Shows with the phone's region outside the United States, the country in "Popular now" is tangerine, like the chevron.
- In Settings, "What's New" in the About row is tangerine. In light and dark mode, all three are easy to read.
