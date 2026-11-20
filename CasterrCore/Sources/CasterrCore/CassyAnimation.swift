/// Every animation Cassy has. Idle loops play at random when she has no job; functional
/// animations each belong to a job (see `CassyJob`) and never join the random rotation.
/// The app draws them; this catalog decides which one plays.
public enum CassyAnimation: String, CaseIterable, Sendable {
    // Idle loops: played once each, at random.
    case blink
    case wink
    case lookAround
    case breathe
    case reelTwitch
    case hum
    case yawn
    case peek

    // Functional: they repeat for as long as their job lasts.
    case bounce
    case jog
    case dozing
    case cheer
    case dizzy

    public var isIdleLoop: Bool {
        switch self {
        case .blink, .wink, .lookAround, .breathe, .reelTwitch, .hum, .yawn, .peek: true
        case .bounce, .jog, .dozing, .cheer, .dizzy: false
        }
    }

    /// One play of an idle loop, in seconds. Nil for functional animations, which repeat.
    public var duration: Double? {
        switch self {
        case .blink: 0.35
        case .wink: 0.7
        case .lookAround: 3
        case .breathe: 3.2
        case .reelTwitch: 0.9
        case .hum: 2.8
        case .yawn: 2.4
        case .peek: 3
        case .bounce, .jog, .dozing, .cheer, .dizzy: nil
        }
    }

    public static var idleLoops: [CassyAnimation] { allCases.filter(\.isIdleLoop) }

    /// The quiet time before the next idle loop, in seconds.
    public static let pause: ClosedRange<Double> = 8...15

    /// The first loop starts sooner, so a freshly shown Cassy doesn't look frozen.
    public static let firstPause: ClosedRange<Double> = 2...5

    /// A random idle loop that isn't the one just played.
    public static func nextIdleLoop(after previous: CassyAnimation?, using generator: inout some RandomNumberGenerator) -> CassyAnimation {
        idleLoops.filter { $0 != previous }.randomElement(using: &generator)!
    }
}

/// What Cassy is doing on a screen. Each job shows one of its functional animations, picked at random
/// when she appears; `idle` plays the random loops instead.
public enum CassyJob: String, CaseIterable, Sendable {
    case idle
    case loading
    case asleep
    case success
    case error

    /// The functional animations this job picks from. Empty for idle.
    public var animations: [CassyAnimation] {
        switch self {
        case .idle: []
        case .loading: [.bounce, .jog]
        case .asleep: [.dozing]
        case .success: [.cheer]
        case .error: [.dizzy]
        }
    }

    /// One of the job's animations, or nil for idle.
    public func animation(using generator: inout some RandomNumberGenerator) -> CassyAnimation? {
        animations.randomElement(using: &generator)
    }
}
