import AVFoundation
import CasterrCore
import UIKit
import os

/// A file holding a clip's audio. Its time zero is `start` in the episode.
struct ClipAudio: Sendable {
    let file: URL
    let start: TimeInterval
    /// A fetched part of a stream, deleted when the editor closes.
    let isTemporary: Bool
}

/// The clip editor's audio: the file, and the span's bars and quiet gaps.
struct ClipSpan: Sendable {
    let audio: ClipAudio
    let bars: [Float]
    let gaps: [TimeInterval]
}

/// Why the editor can't make a clip.
enum ClipProblem: Error {
    /// An M4A, a variable-bitrate MP3, a server that can't send part of a file, or no duration.
    case needsDownload
    case offline
}

/// Gets the editor's two minutes from what the player loaded: the downloaded file, or a ranged fetch of a
/// constant-bitrate MP3 stream with AVPlayer's own User-Agent.
enum ClipFetcher {
    static let barCount = 120
    private static let sampleRate = 44_100.0
    private static let log = Logger(subsystem: "sh.oribi.Casterr", category: "clips")

    static func span(of url: URL, window: ClipWindow) async throws(ClipProblem) -> ClipSpan {
        guard window.duration > 0 else { throw .needsDownload }
        let started = Date.now
        let audio: ClipAudio
        if url.isFileURL {
            audio = ClipAudio(file: url, start: 0, isTemporary: false)
        } else {
            do {
                audio = try await fetch(url, window: window)
            } catch let problem as ClipProblem {
                throw problem
            } catch let error as URLError {
                log.error("Clip fetch failed: \(error.localizedDescription, privacy: .public)")
                throw .offline
            } catch {
                log.error("Clip fetch failed: \(error.localizedDescription, privacy: .public)")
                throw .needsDownload
            }
        }
        do {
            let span = try await Task.detached { try await decode(audio, window: window) }.value
            log.debug(
                "Bars ready in \(Date.now.timeIntervalSince(started), format: .fixed(precision: 2)) s from the \(url.isFileURL ? "file" : "stream")"
            )
            return span
        } catch {
            log.error("Clip decode failed: \(error.localizedDescription, privacy: .public)")
            if audio.isTemporary { try? FileManager.default.removeItem(at: audio.file) }
            throw .needsDownload
        }
    }

    // MARK: Fetching

    /// The fetch span of a constant-bitrate MP3, into a temporary file.
    private static func fetch(_ url: URL, window: ClipWindow) async throws -> ClipAudio {
        let started = Date.now
        // One request for the first 10 bytes proves partial requests work, gives the total size,
        // and holds the ID3 header.
        let (head, response) = try await get(url, bytes: 0...9)
        guard isMP3(url, response), let total = totalBytes(response),
            let tagSize = MP3Header.id3TagSize(head)
        else {
            log.error(
                "Can't clip this stream: type \(response.mimeType ?? "none", privacy: .public), range \(response.value(forHTTPHeaderField: "Content-Range") ?? "none", privacy: .public)"
            )
            throw ClipProblem.needsDownload
        }
        let (frame, _) = try await get(url, bytes: tagSize...(tagSize + 511))
        guard MP3Header.isVariableBitrate(frame) == false,
            let range = window.byteRange(totalBytes: total, id3TagSize: tagSize)
        else {
            log.error("Can't clip this stream: variable bitrate, or no byte range for the window")
            throw ClipProblem.needsDownload
        }
        let (chunk, _) = try await get(url, bytes: range)
        // The part starts mid-frame; decode from its first real frame, a few milliseconds in.
        guard let first = MP3Header.firstFrame(in: chunk, like: frame) else {
            log.error("Can't clip this stream: no frame like the first one in \(range.lowerBound)-\(range.upperBound)")
            throw ClipProblem.needsDownload
        }
        let file = FileManager.default.temporaryDirectory.appending(path: "clip-\(UUID().uuidString).mp3")
        try chunk.dropFirst(first.offset).write(to: file)
        log.debug(
            """
            Fetched \(chunk.count) bytes (\(range.lowerBound)-\(range.upperBound) of \(total), tag \(tagSize)), \
            first frame at \(first.offset), in \(Date.now.timeIntervalSince(started), format: .fixed(precision: 2)) s
            """)
        let skipped = Double(first.offset * 8) / Double(first.bitrate)
        return ClipAudio(file: file, start: window.fetchSpan.lowerBound + skipped, isTemporary: true)
    }

    /// A ranged GET that must come back as 206 Partial Content.
    private static func get(_ url: URL, bytes: ClosedRange<Int>) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue("bytes=\(bytes.lowerBound)-\(bytes.upperBound)", forHTTPHeaderField: "Range")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 206 else {
            log.error(
                "Ranged request for \(bytes.lowerBound)-\(bytes.upperBound) got status \((response as? HTTPURLResponse)?.statusCode ?? -1)"
            )
            throw ClipProblem.needsDownload
        }
        return (data, http)
    }

    private static func isMP3(_ url: URL, _ response: HTTPURLResponse) -> Bool {
        ["audio/mpeg", "audio/mp3"].contains(response.mimeType ?? "") || url.pathExtension.lowercased() == "mp3"
    }

    /// The size after the slash in "Content-Range: bytes 0-9/12345".
    private static func totalBytes(_ response: HTTPURLResponse) -> Int? {
        (response.value(forHTTPHeaderField: "Content-Range")?.split(separator: "/").last).flatMap { Int($0) }
    }

    /// What AVPlayer sends, so servers that vary the file by User-Agent return what the player plays.
    private static let userAgent: String = {
        let build =
            ProcessInfo.processInfo.operatingSystemVersionString
            .firstMatch(of: /Build ([0-9A-Za-z]+)/).map { String($0.1) } ?? ""
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let os = [version.majorVersion, version.minorVersion, version.patchVersion].map(String.init).joined(
            separator: "_")
        return "AppleCoreMedia/1.0.0.\(build) (iPhone; U; CPU OS \(os) like Mac OS X; en_us)"
    }()

    // MARK: Decoding

    /// Mono samples of the fetch span, turned into the span's bars and the fetch span's gaps.
    private static func decode(_ audio: ClipAudio, window: ClipWindow) async throws -> ClipSpan {
        let fetchSpan = window.fetchSpan
        let samples = try await samples(
            of: audio.file, from: fetchSpan.lowerBound - audio.start,
            length: fetchSpan.upperBound - fetchSpan.lowerBound)
        // A big tag or a bitrate estimate gone wrong leaves the chunk short; better no clip than a wrong one.
        let decoded = Double(samples.count) / sampleRate
        guard decoded >= fetchSpan.upperBound - fetchSpan.lowerBound - 1 else {
            log.error("Decoded \(decoded) s of a \(fetchSpan.upperBound - fetchSpan.lowerBound) s span")
            throw ClipProblem.needsDownload
        }
        let index = { (time: TimeInterval) in
            min(max(Int((time - fetchSpan.lowerBound) * sampleRate), 0), samples.count)
        }
        let span = window.span
        let bars = LoudnessBars.bars(
            from: Array(samples[index(span.lowerBound)..<index(span.upperBound)]), count: barCount)
        let readings = Loudness.readings(from: samples, sampleRate: sampleRate, startingAt: fetchSpan.lowerBound)
        let gaps = QuietGaps.find(in: readings, neighborhood: QuietGaps.editorNeighborhood)
        log.debug("Decoded \(decoded, format: .fixed(precision: 1)) s: \(gaps.count) gaps")
        return ClipSpan(audio: audio, bars: bars, gaps: gaps)
    }

    /// Mono 32-bit float samples at `sampleRate`, from `start` seconds into the file.
    private static func samples(of file: URL, from start: TimeInterval, length: TimeInterval) async throws -> [Float] {
        let asset = AVURLAsset(url: file)
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else {
            throw ClipProblem.needsDownload
        }
        let reader = try AVAssetReader(asset: asset)
        reader.timeRange = CMTimeRange(
            start: CMTime(seconds: max(start, 0), preferredTimescale: 600),
            duration: CMTime(seconds: length, preferredTimescale: 600))
        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsFloatKey: true,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: sampleRate,
            ])
        let provider = reader.outputProvider(for: output)
        try reader.start()
        var samples: [Float] = []
        samples.reserveCapacity(Int(length * sampleRate))
        while let buffer = try await provider.next() {
            samples += buffer.withUnsafeSampleBuffer { buffer -> [Float] in
                guard let block = CMSampleBufferGetDataBuffer(buffer) else { return [] }
                let byteCount = CMBlockBufferGetDataLength(block)
                var chunk = [Float](repeating: 0, count: byteCount / MemoryLayout<Float>.size)
                chunk.withUnsafeMutableBytes {
                    _ = CMBlockBufferCopyDataBytes(
                        block, atOffset: 0, dataLength: byteCount, destination: $0.baseAddress!)
                }
                return chunk
            }
        }
        return samples
    }
}

/// Cuts a clip and writes it as a square video of the art, whose waveform fills tangerine as the clip plays.
enum ClipVideo {
    static let side = 1080
    /// Enough frames a second for the fill to move smoothly; only the waveform changes, so frames stay small.
    static let framesPerSecond = 15
    static let barCount = 48
    /// Where the waveform sits, in the 1080 px frame, from the top left.
    static let waveformArea = CGRect(x: 60, y: 865, width: 960, height: 115)
    private static let log = Logger(subsystem: "sh.oribi.Casterr", category: "clips")

    /// A temporary `.mp4` of `frame`, revealing `played` over it left to right across the waveform as the clip plays,
    /// with the clip's audio at normal speed.
    static func make(_ clip: ClosedRange<TimeInterval>, of audio: ClipAudio, frame: CGImage, played: CGImage)
        async throws -> URL
    {
        try await Task.detached {
            let started = Date.now
            let temporary = FileManager.default.temporaryDirectory
            let cut = temporary.appending(path: "clip-\(UUID().uuidString).m4a")
            defer { try? FileManager.default.removeItem(at: cut) }
            try await cutAudio(clip, of: audio, to: cut)
            let video = temporary.appending(path: "Clip-\(UUID().uuidString.prefix(8)).mp4")
            do {
                try await write(frame: frame, played: played, audio: cut, to: video)
            } catch {
                try? FileManager.default.removeItem(at: video)
                throw error
            }
            let size = (try? video.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            log.debug(
                "Made a \(clip.upperBound - clip.lowerBound, format: .fixed(precision: 1)) s clip video, \(size) bytes, in \(Date.now.timeIntervalSince(started), format: .fixed(precision: 2)) s"
            )
            return video
        }.value
    }

    /// The clip as AAC, cut straight from the file: no speed change.
    private static func cutAudio(_ clip: ClosedRange<TimeInterval>, of audio: ClipAudio, to url: URL) async throws {
        guard
            let session = AVAssetExportSession(
                asset: AVURLAsset(url: audio.file), presetName: AVAssetExportPresetAppleM4A)
        else { throw ClipProblem.needsDownload }
        session.timeRange = CMTimeRange(
            start: CMTime(seconds: clip.lowerBound - audio.start, preferredTimescale: 600),
            end: CMTime(seconds: clip.upperBound - audio.start, preferredTimescale: 600))
        try await session.export(to: url, as: .m4a)
    }

    /// `framesPerSecond` frames of the art with the waveform filling, plus the AAC audio passed through, into an
    /// H.264 `.mp4`.
    private static func write(frame: CGImage, played: CGImage, audio: URL, to url: URL) async throws {
        let asset = AVURLAsset(url: audio)
        guard let track = try await asset.loadTracks(withMediaType: .audio).first,
            let format = try await track.load(.formatDescriptions).first
        else { throw ClipProblem.needsDownload }
        let duration = try await asset.load(.duration)
        let reader = try AVAssetReader(asset: asset)
        let audioSamples = reader.outputProvider(for: AVAssetReaderTrackOutput(track: track, outputSettings: nil))

        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let videoReceiver = writer.inputPixelBufferReceiver(
            for: AVAssetWriterInput(
                mediaType: .video,
                outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: side, AVVideoHeightKey: side,
                ]), pixelBufferAttributes: nil)
        let audioReceiver = writer.inputReceiver(
            for: AVAssetWriterInput(mediaType: .audio, outputSettings: nil, sourceFormatHint: format))
        try writer.start()
        try reader.start()
        writer.startSession(atSourceTime: .zero)

        let frames = max(Int((duration.seconds * Double(framesPerSecond)).rounded(.up)), 1)
        // The writer interleaves the tracks, so it takes from whichever one it's ready for.
        var index = 0
        var pixels = CVReadOnlyPixelBuffer(unsafeBuffer: try pixelBuffer(of: frame, played: played, progress: 0))
        var sample = try await audioSamples.next()
        if sample == nil { audioReceiver.finish() }
        while index < frames || sample != nil {
            var appended = false
            if index < frames,
                try videoReceiver.appendImmediately(
                    pixels, with: CMTime(value: CMTimeValue(index), timescale: CMTimeScale(framesPerSecond)))
            {
                index += 1
                if index == frames {
                    videoReceiver.finish()
                } else {
                    pixels = CVReadOnlyPixelBuffer(
                        unsafeBuffer: try pixelBuffer(
                            of: frame, played: played, progress: Double(index) / Double(frames)))
                }
                appended = true
            }
            if let next = sample, try audioReceiver.appendImmediately(next) {
                sample = try await audioSamples.next()
                if sample == nil { audioReceiver.finish() }
                appended = true
            }
            if !appended { try await Task.sleep(for: .milliseconds(5)) }
        }
        writer.endSession(atSourceTime: duration)
        await writer.finishWriting()
        guard writer.status == .completed else { throw writer.error ?? ClipProblem.needsDownload }
    }

    /// `image`, with `played` drawn over it up to `progress` of the way across the waveform.
    private static func pixelBuffer(of image: CGImage, played: CGImage, progress: Double) throws -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        CVPixelBufferCreate(
            nil, side, side, kCVPixelFormatType_32BGRA,
            [kCVPixelBufferCGImageCompatibilityKey: true, kCVPixelBufferCGBitmapContextCompatibilityKey: true]
                as CFDictionary,
            &buffer)
        guard let buffer else { throw ClipProblem.needsDownload }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer), width: side, height: side, bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        let all = CGRect(x: 0, y: 0, width: side, height: side)
        context?.draw(image, in: all)
        if progress > 0 {
            context?.clip(
                to: CGRect(x: 0, y: 0, width: waveformArea.minX + waveformArea.width * progress, height: CGFloat(side)))
            context?.draw(played, in: all)
        }
        return buffer
    }
}
