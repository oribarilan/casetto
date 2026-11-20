# Proposal

## Why

Find Shows opened with Cassy saying "These are popular right now." right above a "Popular now" heading, and nothing explained how Casterr works. Its idea (an Inbox you triage, one Queue that plays, starring for shows you never miss) isn't something a new listener guesses. The decisions were picked from labeled mockups (O1 with O3's card, and bullet option C, three steps).

## What Changes

- **Welcome screen (O1):** on first launch, Cassy introduces herself and three numbered steps (follow shows, queue the episodes you want, press play), with one button, "Let's add some shows", that opens Find Shows. It's the only intro screen.
- **Cassy's card (O3):** "Let's add some shows!" with "Tap + to follow one, or search for a show you love."
- **Heading:** "Popular now · United States", from the phone's region, or "Popular now" without one.
- **Agent rule:** `AGENTS.md` allows this one welcome screen and keeps every other lesson as a just-in-time tip.

## Capabilities

### Modified Capabilities

- `discovery`: top shows and onboarding.

## Impact

- App: `WelcomeView`, `OnboardingView`, and Find Shows' card and heading.
- UI tests: the onboarding test taps through the welcome screen.
