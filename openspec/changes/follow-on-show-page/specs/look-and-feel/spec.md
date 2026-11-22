## MODIFIED Requirements

### Requirement: Cassy presents rule cards
Rule cards SHALL show Cassy beside a short question with the show name in accent text and the reason underneath. The card MUST offer one accept button. A small ✕ and a swipe left MUST dismiss the card for 30 days. A "…" menu MUST hold "Never ask about this show" and, on the Ignored card, Unfollow.

#### Scenario: Auto-queue card
- **WHEN** the Auto-queue card applies to Tape Hiss
- **THEN** the card asks "Queue new Tape Hiss episodes for you?" with "You play it the day it drops." underneath and a Queue Them button

#### Scenario: Swipe to dismiss
- **WHEN** the listener swipes a card left
- **THEN** the card is gone for 30 days
