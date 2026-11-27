import Testing

@testable import CasterrCore

struct PlaybackSpeedTests {
    @Test func defaultIsNormalSpeed() {
        #expect(PlaybackSpeed.normal.value == 1.0)
    }

    @Test func clampsToOneThroughTwo() {
        #expect(PlaybackSpeed(0.5).value == 1.0)
        #expect(PlaybackSpeed(3.0).value == 2.0)
    }

    @Test func roundsToTenths() {
        #expect(PlaybackSpeed(1.34).value == 1.3)
        #expect(PlaybackSpeed(1.35).value == 1.4)
    }

    @Test func nextAddsATenthAndWraps() {
        #expect(PlaybackSpeed(1.3).next == PlaybackSpeed(1.4))
        #expect(PlaybackSpeed(1.9).next == PlaybackSpeed(2.0))
        #expect(PlaybackSpeed(2.0).next == .normal)
    }

    @Test func showWithoutOverrideFollowsGlobal() {
        #expect(PlaybackSpeed.effective(global: PlaybackSpeed(1.3), override: nil) == PlaybackSpeed(1.3))
    }

    @Test func overrideWins() {
        #expect(PlaybackSpeed.effective(global: PlaybackSpeed(1.3), override: .normal) == .normal)
    }

    @Test func globalChangeReachesShowsWithoutOverride() {
        let override: PlaybackSpeed? = nil
        #expect(PlaybackSpeed.effective(global: PlaybackSpeed(1.5), override: override) == PlaybackSpeed(1.5))
    }
}

struct PlayedRuleTests {
    @Test func sixtyOneSecondsLeftIsNotPlayed() {
        #expect(!PlayedRule.isPlayed(position: 539, duration: 600))
    }

    @Test func exactlySixtySecondsLeftIsNotPlayed() {
        #expect(!PlayedRule.isPlayed(position: 540, duration: 600))
    }

    @Test func fiftyNineSecondsLeftIsPlayed() {
        #expect(PlayedRule.isPlayed(position: 541, duration: 600))
    }

    @Test func unknownDurationIsNeverPlayed() {
        #expect(!PlayedRule.isPlayed(position: 10_000, duration: nil))
    }

    @Test func episodeShorterThanAMinuteIsPlayedOnceStarted() {
        #expect(PlayedRule.isPlayed(position: 1, duration: 45))
    }
}
