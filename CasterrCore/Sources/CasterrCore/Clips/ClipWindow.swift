import Foundation

/// The clip editor's times: the two minutes it shows around now, the clip in them, and the bytes to fetch.
public struct ClipWindow: Equatable, Sendable {
    public static let spanLength: TimeInterval = 120
    public static let defaultLength: TimeInterval = 30
    public static let shortest: TimeInterval = 5
    public static let longest: TimeInterval = 60
    /// Extra audio fetched on each side of the span, so the decoder can find its footing.
    public static let fetchPadding: TimeInterval = 2

    public enum Edge: Sendable {
        case start, end
    }

    public let position: TimeInterval
    public let duration: TimeInterval

    public init(position: TimeInterval, duration: TimeInterval) {
        self.position = position
        self.duration = max(duration, 0)
    }

    /// 60 s either side of the position, shifted to stay 120 s long near an edge.
    public var span: ClosedRange<TimeInterval> {
        Self.centered(on: position, length: Self.spanLength, in: 0...duration)
    }

    /// 15 s either side of the position, shifted to stay 30 s long near an edge.
    public var defaultClip: ClosedRange<TimeInterval> {
        Self.centered(on: position, length: Self.defaultLength, in: 0...duration)
    }

    /// The span with `fetchPadding` on each side, within the episode. The fetched audio starts at its lower bound.
    public var fetchSpan: ClosedRange<TimeInterval> {
        max(span.lowerBound - Self.fetchPadding, 0)...min(span.upperBound + Self.fetchPadding, duration)
    }

    /// Moves one edge of `clip` toward `time`. The clip stays 5 to 60 s long and within the span,
    /// and the other edge stays put.
    public func dragging(_ edge: Edge, of clip: ClosedRange<TimeInterval>, to time: TimeInterval) -> ClosedRange<
        TimeInterval
    > {
        switch edge {
        case .start:
            let earliest = max(span.lowerBound, clip.upperBound - Self.longest)
            let start = max(earliest, min(time, clip.upperBound - Self.shortest))
            return start...clip.upperBound
        case .end:
            let latest = min(span.upperBound, clip.lowerBound + Self.longest)
            let end = min(latest, max(time, clip.lowerBound + Self.shortest))
            return clip.lowerBound...end
        }
    }

    /// The nearest gap middle within `within` of `time`, or `time` when none is that close.
    public static func snap(_ time: TimeInterval, to gaps: [TimeInterval], within: TimeInterval = 0.5) -> TimeInterval {
        gaps.filter { abs($0 - time) <= within }.min { abs($0 - time) < abs($1 - time) } ?? time
    }

    /// The default clip with each edge snapped to a nearby gap, still 5 to 60 s long and within the span.
    public func snappedDefaultClip(to gaps: [TimeInterval]) -> ClosedRange<TimeInterval> {
        let clip = defaultClip
        let started = dragging(.start, of: clip, to: Self.snap(clip.lowerBound, to: gaps))
        return dragging(.end, of: started, to: Self.snap(clip.upperBound, to: gaps))
    }

    /// The bytes holding `fetchSpan` in a constant-bitrate file, as an inclusive range for an HTTP `Range` header.
    /// Nil when there's no duration or no audio after the ID3 tag.
    public func byteRange(totalBytes: Int, id3TagSize: Int) -> ClosedRange<Int>? {
        guard duration > 0, totalBytes > id3TagSize, id3TagSize >= 0 else { return nil }
        let bytesPerSecond = Double(totalBytes - id3TagSize) / duration
        let first = id3TagSize + Int((fetchSpan.lowerBound * bytesPerSecond).rounded(.down))
        let last = id3TagSize + Int((fetchSpan.upperBound * bytesPerSecond).rounded(.up))
        return min(first, totalBytes - 1)...min(last, totalBytes - 1)
    }

    /// `length` centered on `time`, shifted to fit `bounds`, and no longer than `bounds`.
    private static func centered(
        on time: TimeInterval, length: TimeInterval,
        in bounds: ClosedRange<TimeInterval>
    ) -> ClosedRange<TimeInterval> {
        let length = min(length, bounds.upperBound - bounds.lowerBound)
        let start = min(max(time - length / 2, bounds.lowerBound), bounds.upperBound - length)
        return start...(start + length)
    }
}
