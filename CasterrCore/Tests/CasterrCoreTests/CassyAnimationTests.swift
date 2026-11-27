import Testing

@testable import CasterrCore

/// A seeded generator, so random picks repeat across runs.
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}

struct CassyAnimationTests {
    @Test func catalogSplitsIdleLoopsFromFunctionalAnimations() {
        #expect(CassyAnimation.idleLoops == [.blink, .wink, .lookAround, .breathe, .reelTwitch, .hum, .yawn, .peek])
        for animation in CassyAnimation.allCases {
            #expect((animation.duration != nil) == animation.isIdleLoop)
        }
    }

    @Test func randomPicksAreIdleLoopsAndNeverRepeat() {
        var generator = SeededGenerator(state: 42)
        var previous: CassyAnimation?
        var seen: Set<CassyAnimation> = []
        for _ in 0..<500 {
            let next = CassyAnimation.nextIdleLoop(after: previous, using: &generator)
            #expect(next.isIdleLoop)
            #expect(next != previous)
            seen.insert(next)
            previous = next
        }
        #expect(seen == Set(CassyAnimation.idleLoops))
    }

    @Test func everyJobButIdleHasFunctionalAnimations() {
        var generator = SeededGenerator(state: 3)
        #expect(CassyJob.idle.animations.isEmpty)
        #expect(CassyJob.idle.animation(using: &generator) == nil)
        for job in CassyJob.allCases where job != .idle {
            #expect(!job.animations.isEmpty)
            #expect(job.animations.allSatisfy { !$0.isIdleLoop })
        }
    }

    @Test func loadingPicksBounceOrJog() {
        var generator = SeededGenerator(state: 11)
        let picks = Set((0..<100).compactMap { _ in CassyJob.loading.animation(using: &generator) })
        #expect(picks == [.bounce, .jog])
    }

    @Test func pausesBetweenLoopsAreShort() {
        #expect(CassyAnimation.pause.lowerBound > 0)
        #expect(CassyAnimation.pause.upperBound <= 1.2)
    }
}
