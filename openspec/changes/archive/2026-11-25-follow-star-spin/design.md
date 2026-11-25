## Context

Find Shows draws the star and + as icon-only buttons in each row (`DiscoverView.row`). The show page draws Follow and Star with `ShowPageButton`, a label with a symbol. Since 0.4.1 both screens show the new state at the tap, from a pending value, and then from the saved state. Both screens also load the saved state after they appear, so "the value turned on" happens on load too, not only on a tap.

## Goals / Non-Goals

**Goals:** one spin effect shared by both screens; spin only on a tap that turns something on.

**Non-Goals:** new symbols, haptics, or changes to how saving works.

## Decisions

**A tap counter starts the spin, not the on/off value.** Each button bumps a counter when a tap turns it on, and the spin runs when the counter changes. Watching the on/off value instead would also spin every followed show when Find Shows finishes loading, and Following and Starred each time a show page opens. Find Shows keeps the counters in one dictionary keyed by show and button; the show page keeps two.

**A small modifier in `Theme.swift`.** `.spin(from: Angle, trigger: Int)` sets the icon to the start angle at 0.6 scale with no animation, then springs it to upright at full scale (a bouncy spring, about 0.6 s). The star starts at -144 degrees (two points of the star, so it lands upright), and the check at -90 degrees. When Reduce Motion is on, it does nothing. It goes on the icon only, so on the show page the title doesn't turn. The symbol swap itself stays as it is today.

Alternatives: Apple's `.symbolEffect(.rotate)` spins continuously and can't land on a set angle; `.bounce` is option A, which the listener didn't pick.

**A tap that spins waits for the spin before it saves.** Every save makes all screens reload, and on the phone the reload made the spin stutter. Measured on the simulator, the reload stalled the screen for 60 to 130 ms inside the 0.6 s spin; with the save waiting 0.6 s, the spin runs clean and the reload comes after it. The button already shows the new state at the tap, so the wait isn't visible; a newly followed show's episodes arrive 0.6 s later. With Reduce Motion on there's no spin, so there's no wait. One `spinSeconds` value sets both the spin and the wait.

The wait made a second tap more likely to land while a save was still running, and both screens ignored such taps: Follow then a quick Star dropped the star. Now no tap is dropped. Each show's saves run one after another, and the buttons show the latest choice until the last save lands.

Alternative: make the reload cheaper. It's the real cost, but it touches every screen, and the instant-controls change left it out of scope.

**The Unfollow question moves onto the Following button.** On iOS 27 a confirmation dialog opens as a bubble pointing at the view it is attached to. It is attached to the page's List today; attaching it to the Following button makes it point there. Nothing else about the question changes.

## Risks / Trade-offs

- [The spin replays if a save fails and the button goes back and forth] → It only replays on a tap that turns the button on, so a failed save just swaps back quietly.
- [A modifier inside a List row might animate during the row's own insert animation] → Find Shows rows aren't inserted while you tap; check on the phone.
