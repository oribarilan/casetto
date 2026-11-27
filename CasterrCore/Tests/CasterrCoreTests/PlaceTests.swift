import Testing

@testable import CasterrCore

struct PlaceTests {
    @Test(arguments: [
        Place.inbox, .queue, .archive(.played), .archive(.dismissed), .archive(.expired),
        .archive(.skipped), .archive(.unsubscribed),
    ])
    func roundTripsThroughStoredForm(place: Place) throws {
        let stored = place.stored
        #expect(try Place(storedPlace: stored.place, archiveReason: stored.archiveReason) == place)
    }

    @Test func noStoredPlaceMeansNoPlace() throws {
        #expect(try Place(storedPlace: nil, archiveReason: nil) == nil)
    }

    @Test func rejectsQueueWithAReason() {
        #expect(throws: Place.StoredFormError.self) {
            try Place(storedPlace: "queue", archiveReason: "played")
        }
    }

    @Test func rejectsArchiveWithoutAReason() {
        #expect(throws: Place.StoredFormError.self) {
            try Place(storedPlace: "archive", archiveReason: nil)
        }
    }

    @Test func rejectsAReasonWithoutAPlace() {
        #expect(throws: Place.StoredFormError.self) {
            try Place(storedPlace: nil, archiveReason: "played")
        }
    }

    @Test func rejectsUnknownValues() {
        #expect(throws: Place.StoredFormError.self) {
            try Place(storedPlace: "later", archiveReason: nil)
        }
        #expect(throws: Place.StoredFormError.self) {
            try Place(storedPlace: "archive", archiveReason: "lost")
        }
        #expect(throws: Place.StoredFormError.self) {
            try Place(storedPlace: "inbox", archiveReason: "played")
        }
    }
}
