import Testing
@testable import CasterrCore

struct PlaceTests {
    @Test(arguments: [Place.queue, .archive(.played)])
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
            try Place(storedPlace: "inbox", archiveReason: nil)
        }
        #expect(throws: Place.StoredFormError.self) {
            try Place(storedPlace: "archive", archiveReason: "dismissed")
        }
    }
}
