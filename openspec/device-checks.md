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
