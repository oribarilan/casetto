import AVFoundation
import CasterrCore
import MediaToolbox
import os
import Synchronization

/// Hears the audio as it plays and keeps the loudness of the last 8 seconds, for Back a Beat.
/// It taps the audio after the speed change: with the tap before it, Apple's player could freeze its clock
/// when the speed changed. `setRate` keeps the readings' times in episode time at any speed.
/// The tap callbacks run on a real-time audio thread: no allocation, no actors, only the unfair lock.
final class LoudnessTap: Sendable {
    private let ring = OSAllocatedUnfairLock(initialState: Ring())
    /// The playback speed, as Double bits. The tap hears audio after the speed change, so one played
    /// frame covers `rate` frames of the episode.
    private let rate = Atomic<UInt64>(1.0.bitPattern)

    /// An audio mix that sends `track` through this tap, or nil if the tap can't be made.
    func audioMix(for track: AVAssetTrack) -> AVAudioMix? {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: Unmanaged.passRetained(self).toOpaque(),
            init: { _, clientInfo, storage in storage.pointee = clientInfo },
            finalize: { tap in Unmanaged<LoudnessTap>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).release() },
            prepare: { tap, _, format in
                let format = format.pointee
                LoudnessTap.from(tap).ring.withLock { $0.prepare(format) }
            },
            unprepare: nil,
            process: { tap, frames, _, buffers, framesOut, flagsOut in
                var range = CMTimeRange()
                guard MTAudioProcessingTapGetSourceAudio(tap, frames, buffers, flagsOut, &range, framesOut) == noErr
                else { return }
                let list = UnsafeMutableAudioBufferListPointer(buffers)
                let count = Int(framesOut.pointee), start = range.start.seconds
                // Unchecked: the buffer pointer is only used inside the lock, on this thread.
                let me = LoudnessTap.from(tap)
                let rate = Double(bitPattern: me.rate.load(ordering: .relaxed))
                me.ring.withLockUnchecked { $0.add(list, frames: count, at: start, rate: rate) }
            }
        )
        var tap: MTAudioProcessingTap?
        guard MTAudioProcessingTapCreate(nil, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap) == noErr,
              let tap
        else {
            Unmanaged.passUnretained(self).release()
            return nil
        }
        let input = AVMutableAudioMixInputParameters(track: track)
        input.audioTapProcessor = tap
        let mix = AVMutableAudioMix()
        mix.inputParameters = [input]
        return mix
    }

    func setRate(_ newRate: Double) {
        rate.store(newRate.bitPattern, ordering: .relaxed)
    }

    func loudness(from start: TimeInterval, to end: TimeInterval) -> [Loudness] {
        ring.withLock { $0.readings(from: start, to: end) }
    }

    private static func from(_ tap: MTAudioProcessingTap) -> LoudnessTap {
        Unmanaged<LoudnessTap>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
    }
}

/// The last 800 readings (8 seconds), in fixed arrays so the audio thread never allocates.
private struct Ring {
    static let capacity = 800
    private var times = [TimeInterval](repeating: 0, count: capacity)
    private var levels = [Float](repeating: 0, count: capacity)
    private var count = 0
    private var next = 0

    private var sampleRate: Double = 0
    private var isFloat = false
    private var isInt16 = false
    /// The slice being summed: its start time, sum of squares, and frames so far.
    private var sliceStart: TimeInterval = 0
    private var sliceSum: Double = 0
    private var sliceFrames = 0
    private var expected: TimeInterval = -1

    mutating func prepare(_ format: AudioStreamBasicDescription) {
        sampleRate = format.mSampleRate
        isFloat = format.mFormatFlags & kAudioFormatFlagIsFloat != 0 && format.mBitsPerChannel == 32
        isInt16 = format.mFormatFlags & kAudioFormatFlagIsSignedInteger != 0 && format.mBitsPerChannel == 16
        count = 0
        next = 0
        expected = -1
    }

    /// Measures played audio that starts at episode time `start` and plays at `rate`.
    mutating func add(_ list: UnsafeMutableAudioBufferListPointer, frames: Int, at start: TimeInterval, rate: Double) {
        guard sampleRate > 0, rate > 0, isFloat || isInt16, frames > 0, start.isFinite else { return }
        if abs(start - expected) > Loudness.slice {
            // A seek, or a pause that renders the last moment again. Readings are keyed by media time,
            // so the earlier ones still hold; drop only those at or after the new start.
            while count > 0, times[(next - 1 + Self.capacity) % Self.capacity] >= start {
                next = (next - 1 + Self.capacity) % Self.capacity
                count -= 1
            }
            sliceStart = start
            sliceSum = 0
            sliceFrames = 0
        }
        let perSlice = max(Int((sampleRate * Loudness.slice / rate).rounded()), 1)
        for frame in 0..<frames {
            var sum: Double = 0
            var channels = 0
            for buffer in list {
                guard let data = buffer.mData else { continue }
                let width = Int(buffer.mNumberChannels)
                for channel in 0..<width {
                    let index = frame * width + channel
                    let sample = isFloat
                        ? Double(data.assumingMemoryBound(to: Float.self)[index])
                        : Double(data.assumingMemoryBound(to: Int16.self)[index]) / Double(Int16.max)
                    sum += sample * sample
                }
                channels += width
            }
            guard channels > 0 else { return }
            sliceSum += sum / Double(channels)
            sliceFrames += 1
            if sliceFrames == perSlice {
                append(Loudness(time: sliceStart, level: Float((sliceSum / Double(sliceFrames)).squareRoot())))
                sliceStart = start + Double(frame + 1) * rate / sampleRate
                sliceSum = 0
                sliceFrames = 0
            }
        }
        expected = start + Double(frames) * rate / sampleRate
    }

    func readings(from start: TimeInterval, to end: TimeInterval) -> [Loudness] {
        (0..<count)
            .map { (next - count + $0 + Self.capacity) % Self.capacity }
            .map { Loudness(time: times[$0], level: levels[$0]) }
            .filter { $0.time >= start && $0.time < end }
    }

    private mutating func append(_ reading: Loudness) {
        times[next] = reading.time
        levels[next] = reading.level
        next = (next + 1) % Self.capacity
        count = min(count + 1, Self.capacity)
    }
}
