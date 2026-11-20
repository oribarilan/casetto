# Proposal

## Why

After M3, a show's level only changes when you change it. This change is roadmap milestone **M4: Rule cards**, the learning half of the bet: Casterr notices how you treat a show and offers a one-tap change, so the levels tune themselves without a settings screen.

## What Changes

- **Two cards**, shown at the top of the Inbox for shows at the Inbox level:
  - **Auto-queue:** you started each of the show's last 4 episodes within a day of release. Accepting sets the show to Auto-queue.
  - **Ignored:** the show's last 3 episodes expired unplayed. You can Skip the show or Unsubscribe from it.
- Every card also offers **Not now** (hidden for 30 days) and **Never** (hidden for this show for good).
- The **"New (N)"** row counts cards as well as Inbox episodes.
- Each episode records when you **first started playing** it, which the Auto-queue card needs.

## Capabilities

### New Capabilities

- `rule-cards`: the two cards, how they are computed, and accepting or hiding them.

### Modified Capabilities

- `triage`: the "New (N)" count includes cards.

## Out of scope

- Filters by length or title words. Cards only change a show's level or unsubscribe.
- Cards for shows at other levels, and learning from topics.
- Settings for the thresholds. They are constants.

## Impact

- `CasterrCore`: a pure function that decides a show's card, `EpisodeState.firstPlayedAt`, and two hide dates on `Subscription`, all optional under the CloudKit rules.
- App: a suggestions section at the top of the Inbox, and the new count.
- No new dependencies.
- **Order:** archive M2 (`add-inbox-triage`) before this change, because this change modifies its `triage` requirement.
