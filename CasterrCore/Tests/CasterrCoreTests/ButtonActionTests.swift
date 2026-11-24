import Testing
@testable import CasterrCore

struct ButtonActionTests {
    @Test func footerForTheDefaults() {
        #expect(ButtonAction.footer(double: .doublePressDefault, triple: .triplePressDefault)
            == "Double press bookmarks, with a chime. Triple press skips back 15. Other headphones and cars do the same with their next and previous buttons.")
    }

    @Test func footerForAChangedPress() {
        #expect(ButtonAction.footer(double: .bookmark, triple: .skipForward)
            .hasPrefix("Double press bookmarks, with a chime. Triple press skips forward 30."))
    }

    @Test func footerJoinsMatchingPresses() {
        #expect(ButtonAction.footer(double: .skipForward, triple: .skipForward)
            .hasPrefix("Double and triple press skip forward 30. Other"))
        #expect(ButtonAction.footer(double: .bookmark, triple: .bookmark)
            .hasPrefix("Double and triple press bookmark, with a chime. Other"))
    }

    @Test func storedValuesAreStable() {
        #expect(ButtonAction.allCases.map(\.rawValue) == ["skipForward", "skipBack", "bookmark"])
    }
}
