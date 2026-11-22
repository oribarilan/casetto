import AudioToolbox
import AVFoundation
import CasterrCore
import MediaToolbox
import os
import Synchronization

/// Hears the audio as it plays. It keeps the loudness of the last 8 seconds for Back a Beat and,
/// while voice boost is on, runs the audio through Apple's dynamics processor after measuring it.
/// It taps the audio track after the speed change. A tap before it froze the player's clock in about one
/// speed change in three, even with no voice boost. The tap's times are still media times, and `setRate`
/// tells it how much media each played frame covers.
/// The tap callbacks run on a real-time audio thread: no allocation, no actors, only the unfair lock and atomics.
final class AudioTap: Sendable {
    private let ring = OSAllocatedUnfairLock(initialState: Ring())
    /// Made with the tap, on the main thread, so the prepare callback never creates an audio unit.
    private let unit = DynamicsUnit()
    private let boost = OSAllocatedUnfairLock(initialState: Boost())
    private let boostOn = Atomic<Bool>(false)
    /// The playback rate, as Double bits.
    private let rate = Atomic<UInt64>(1.0.bitPattern)
    /// The dynamics processor's latest compression in dB, as Float bits, for the debug log.
    private let compression = Atomic<UInt32>(0)

    /// An audio mix that sends `track` through this tap, or nil if the tap can't be made.
    func audioMix(for track: AVAssetTrack) -> AVAudioMix? {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: Unmanaged.passRetained(self).toOpaque(),
            init: { _, clientInfo, storage in storage.pointee = clientInfo },
            finalize: { tap in Unmanaged<AudioTap>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).release() },
            prepare: { tap, maxFrames, format in
                let me = AudioTap.from(tap), format = format.pointee
                me.ring.withLock { $0.prepare(format) }
                let ready = me.unit.prepare(format: format, maxFrames: UInt32(maxFrames))
                me.boost.withLock { $0 = Boost(ready: ready) }
            },
            unprepare: { tap in
                let me = AudioTap.from(tap)
                me.boost.withLock { $0 = Boost() }
                me.unit.unprepare()
            },
            process: { tap, frames, _, buffers, framesOut, flagsOut in
                var range = CMTimeRange()
                guard MTAudioProcessingTapGetSourceAudio(tap, frames, buffers, flagsOut, &range, framesOut) == noErr
                else { return }
                let me = AudioTap.from(tap)
                let list = UnsafeMutableAudioBufferListPointer(buffers)
                let count = Int(framesOut.pointee), start = range.start.seconds
                // Unchecked: the buffer pointer is only used inside the locks, on this thread.
                let rate = Double(bitPattern: me.rate.load(ordering: .relaxed))
                me.ring.withLockUnchecked { $0.add(list, frames: count, at: start, rate: rate) }
                let isOn = me.boostOn.load(ordering: .relaxed)
                if let amount = me.boost.withLockUnchecked({ $0.process(list, frames: count, isOn: isOn, unit: me.unit) }) {
                    me.compression.store(amount.bitPattern, ordering: .relaxed)
                }
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

    func loudness(from start: TimeInterval, to end: TimeInterval) -> [Loudness] {
        ring.withLock { $0.readings(from: start, to: end) }
    }

    func setRate(_ newRate: Double) {
        rate.store(newRate.bitPattern, ordering: .relaxed)
    }

    func setVoiceBoost(_ isOn: Bool) {
        boostOn.store(isOn, ordering: .relaxed)
    }

    /// False when the dynamics processor refused the tap's format, so the audio plays unboosted.
    var canBoost: Bool {
        boost.withLock { $0.ready }
    }

    /// How hard the dynamics processor is working, in dB. Zero when boost is off or hasn't run.
    var compressionAmount: Float {
        Float(bitPattern: compression.load(ordering: .relaxed))
    }

    private static func from(_ tap: MTAudioProcessingTap) -> AudioTap {
        Unmanaged<AudioTap>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
    }
}

/// Whether the unit is ready for the tap's format, and the running sample time it needs.
private struct Boost {
    var ready = false
    var wasOn = false
    var sampleTime: Float64 = 0

    /// Boosts the audio in place while on and returns the compression in dB, or nil when it left the audio alone.
    mutating func process(_ list: UnsafeMutableAudioBufferListPointer, frames: Int, isOn: Bool, unit: DynamicsUnit) -> Float? {
        defer { wasOn = isOn }
        guard isOn, ready, let au = unit.unit else { return nil }
        if !wasOn { AudioUnitReset(au, kAudioUnitScope_Global, 0) }
        var timeStamp = AudioTimeStamp()
        timeStamp.mFlags = .sampleTimeValid
        timeStamp.mSampleTime = sampleTime
        sampleTime += Float64(frames)
        var flags = AudioUnitRenderActionFlags()
        unit.input = list.unsafeMutablePointer
        let status = AudioUnitRender(au, &flags, &timeStamp, 0, UInt32(frames), list.unsafeMutablePointer)
        guard status == noErr else { return nil }
        var amount: AudioUnitParameterValue = 0
        AudioUnitGetParameter(au, kDynamicsProcessorParam_CompressionAmount, kAudioUnitScope_Global, 0, &amount)
        return amount
    }
}

/// Apple's dynamics processor with the values the listener approved by ear. It is made once per tap;
/// prepare and unprepare only initialize it for the tap's format and uninitialize it.
private final class DynamicsUnit: @unchecked Sendable {
    static let settings: [(AudioUnitParameterID, AudioUnitParameterValue)] = [
        (kDynamicsProcessorParam_Threshold, -38),
        (kDynamicsProcessorParam_HeadRoom, 3),
        (kDynamicsProcessorParam_AttackTime, 0.003),
        (kDynamicsProcessorParam_ReleaseTime, 0.3),
        (kDynamicsProcessorParam_OverallGain, 24),
        (kDynamicsProcessorParam_ExpansionRatio, 1),
    ]
    let unit: AudioUnit?
    /// The audio the unit renders next; its input callback reads it from here.
    fileprivate var input: UnsafeMutablePointer<AudioBufferList>?

    init() {
        var description = AudioComponentDescription(
            componentType: kAudioUnitType_Effect, componentSubType: kAudioUnitSubType_DynamicsProcessor,
            componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
        var newUnit: AudioUnit?
        if let component = AudioComponentFindNext(nil, &description) {
            AudioComponentInstanceNew(component, &newUnit)
        }
        unit = newUnit
        var callback = AURenderCallbackStruct(inputProc: feedUnit, inputProcRefCon: Unmanaged.passUnretained(self).toOpaque())
        if let newUnit {
            AudioUnitSetProperty(newUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callback, UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        }
    }

    deinit {
        if let unit { AudioComponentInstanceDispose(unit) }
    }

    /// Initializes the unit for the tap's format. False when the format can't be boosted.
    func prepare(format: AudioStreamBasicDescription, maxFrames: UInt32) -> Bool {
        guard let unit, format.mFormatFlags & kAudioFormatFlagIsFloat != 0, format.mBitsPerChannel == 32 else { return false }
        var streamFormat = format
        var frames = maxFrames
        let formatSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        let ready = AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, formatSize) == noErr
            && AudioUnitSetProperty(unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &streamFormat, formatSize) == noErr
            && AudioUnitSetProperty(unit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &frames, UInt32(MemoryLayout<UInt32>.size)) == noErr
            && AudioUnitInitialize(unit) == noErr
        guard ready else { return false }
        for (parameter, value) in Self.settings {
            AudioUnitSetParameter(unit, parameter, kAudioUnitScope_Global, 0, value, 0)
        }
        return true
    }

    func unprepare() {
        if let unit { AudioUnitUninitialize(unit) }
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

/// The unit's input: the audio the tap already fetched, copied unless the unit renders in place.
private let feedUnit: AURenderCallback = { refCon, _, _, _, _, ioData in
    let unit = Unmanaged<DynamicsUnit>.fromOpaque(refCon).takeUnretainedValue()
    guard let ioData, let input = unit.input else { return kAudioUnitErr_NoConnection }
    let from = UnsafeMutableAudioBufferListPointer(input), to = UnsafeMutableAudioBufferListPointer(ioData)
    for index in 0..<min(from.count, to.count) {
        guard let source = from[index].mData, let target = to[index].mData else { continue }
        if source != target { memcpy(target, source, Int(min(from[index].mDataByteSize, to[index].mDataByteSize))) }
    }
    return noErr
}
