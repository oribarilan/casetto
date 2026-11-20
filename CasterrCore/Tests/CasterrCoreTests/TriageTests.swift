import Foundation
import Testing
@testable import CasterrCore

struct TriageLevelTests {
    @Test func eachLevelHasItsDestination() {
        #expect(TriageLevel.inbox.destination == (.inbox, .arrived))
        #expect(TriageLevel.autoQueue.destination == (.queue, .autoQueued))
        #expect(TriageLevel.playNext.destination == (.queue, .playNext))
        #expect(TriageLevel.skip.destination == (.archive(.skipped), .skipped))
    }
}

struct MoveReasonTests {
    @Test(arguments: [MoveReason.listener, .arrived, .autoQueued, .playNext, .skipped, .expired(days: 7)])
    func roundTripsThroughStoredForm(reason: MoveReason) {
        #expect(MoveReason(stored: reason.stored) == reason)
    }

    @Test(arguments: ["", "bogus", "expired:", "expired:0", "expired:x"])
    func rejectsInvalidStoredForms(stored: String) {
        #expect(MoveReason(stored: stored) == nil)
    }

    @Test func automaticMovesHaveLabelsAndUndo() {
        #expect(MoveReason.autoQueued.label == "Auto-queued")
        #expect(MoveReason.playNext.label == "Play next")
        #expect(MoveReason.skipped.label == "Skipped by show setting")
        #expect(MoveReason.expired(days: 7).label == "Removed after 7 days")
        for reason in [MoveReason.autoQueued, .playNext, .skipped, .expired(days: 3)] {
            #expect(reason.isUndoable)
        }
    }

    @Test func listenerMovesAndArrivalsHaveNoUndo() {
        #expect(MoveReason.listener.label == nil && !MoveReason.listener.isUndoable)
        #expect(MoveReason.arrived.label == nil && !MoveReason.arrived.isUndoable)
    }

    @Test func undoReturnsAnExpiryToTheInboxAndEverythingElseToNoPlace() {
        #expect(MoveReason.expired(days: 7).placeBefore == .inbox)
        #expect(MoveReason.autoQueued.placeBefore == nil)
        #expect(MoveReason.playNext.placeBefore == nil)
        #expect(MoveReason.skipped.placeBefore == nil)
    }
}

struct InboxExpiryTests {
    private let entered = Date(timeIntervalSince1970: 1_800_000_000)

    private func days(_ count: Double) -> Date {
        entered.addingTimeInterval(count * 86_400)
    }

    @Test(arguments: [3, 7, 14, 30])
    func expiresAtTheEndOfThePeriod(period: Int) {
        let expiry = InboxExpiry.days(period)
        #expect(!expiry.hasExpired(enteredAt: entered, now: days(Double(period) - 0.01)))
        #expect(expiry.hasExpired(enteredAt: entered, now: days(Double(period))))
    }

    @Test func neverExpires() {
        #expect(!InboxExpiry.never.hasExpired(enteredAt: entered, now: days(10_000)))
    }

    @Test func storesNeverAsZero() {
        #expect(InboxExpiry.never.storedDays == 0)
        #expect(InboxExpiry(storedDays: 0) == .never)
        #expect(InboxExpiry(storedDays: 14) == .days(14))
    }
}
