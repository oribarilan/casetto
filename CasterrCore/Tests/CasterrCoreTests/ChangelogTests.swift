import Testing

@testable import CasterrCore

struct ChangelogTests {
    private let text = """
        # Changelog

        ## 0.5
        - Five.

        ## 0.4
        - Four, first.
        - Four, second.

        ## 0.3
        - Three.
        """

    @Test func parsesVersionsAndLines() {
        let changelog = Changelog(text)
        #expect(changelog.releases.map(\.version) == ["0.5", "0.4", "0.3"])
        #expect(changelog.releases[1].lines == ["Four, first.", "Four, second."])
    }

    @Test func listsSkippedVersionsNewestFirst() {
        #expect(Changelog(text).releases(after: "0.2").map(\.version) == ["0.5", "0.4", "0.3"])
        #expect(Changelog(text).releases(after: "0.4").map(\.version) == ["0.5"])
        #expect(Changelog(text).releases(after: "0.5").isEmpty)
    }

    @Test func comparesPartByPart() {
        #expect(Changelog.isNewer("0.10", than: "0.9"))
        #expect(Changelog.isNewer("0.3.1", than: "0.3"))
        #expect(!Changelog.isNewer("0.3", than: "0.3.0"))
        #expect(!Changelog.isNewer("0.2", than: "0.10"))
    }
}
