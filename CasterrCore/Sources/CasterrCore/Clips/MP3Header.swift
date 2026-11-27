import Foundation

/// Reads the start of an MP3 file, to tell whether its bytes can be fetched by time.
public enum MP3Header {
    /// The bytes before the audio: the whole ID3v2 tag with its header (and footer), or 0 without one.
    /// Nil with fewer than 10 bytes.
    public static func id3TagSize(_ header: Data) -> Int? {
        let bytes = [UInt8](header.prefix(10))
        guard bytes.count == 10 else { return nil }
        guard bytes[0...2] == [0x49, 0x44, 0x33] else { return 0 }  // "ID3"
        // The size is syncsafe: 7 bits in each of 4 bytes.
        let size = bytes[6...9].reduce(0) { $0 << 7 | Int($1 & 0x7F) }
        let footer = bytes[5] & 0x10 != 0 ? 10 : 0
        return 10 + size + footer
    }

    /// Whether the first MPEG frame in `bytes` carries a Xing or VBRI header, which marks variable bitrate.
    /// Nil when `bytes` holds no frame header.
    public static func isVariableBitrate(_ bytes: Data) -> Bool? {
        let data = [UInt8](bytes)
        guard let frame = data.indices.dropLast(3).first(where: { isSync(data, $0) }) else { return nil }
        let isMPEG1 = (data[frame + 1] >> 3) & 0x3 == 0x3
        let isMono = (data[frame + 3] >> 6) & 0x3 == 0x3
        let xing = frame + 4 + (isMPEG1 ? (isMono ? 17 : 32) : (isMono ? 9 : 17))
        return marker("Xing", in: data, at: xing) || marker("VBRI", in: data, at: frame + 36)
    }

    /// The first Layer III frame in `bytes` with the version, bitrate and sample rate of the first frame in
    /// `reference`, and a second such frame where it ends: its offset, and the bitrate in bits per second.
    /// A part cut from the middle of a file can start with bytes that only look like a frame, which stops
    /// Apple's decoder. Nil when there's no such frame, or `reference` holds no Layer III frame.
    public static func firstFrame(in bytes: Data, like reference: Data) -> (offset: Int, bitrate: Int)? {
        let ref = [UInt8](reference)
        let data = [UInt8](bytes)
        guard let r = ref.indices.dropLast(3).first(where: { isSync(ref, $0) }),
            let (bitrate, sampleRate) = layer3Format(ref, at: r)
        else { return nil }
        let bytesPerKilobit = (ref[r + 1] >> 3) & 0x3 == 0x3 ? 144 : 72  // MPEG-1 frames hold twice the samples
        let alike = { (i: Int) in
            i + 3 < data.count && isSync(data, i)
                && data[i + 1] & 0x1E == ref[r + 1] & 0x1E && data[i + 2] & 0xFC == ref[r + 2] & 0xFC
        }
        let next = { (i: Int) in i + bytesPerKilobit * bitrate / sampleRate + Int((data[i + 2] >> 1) & 0x1) }
        return data.indices.first { alike($0) && alike(next($0)) }.map { ($0, bitrate) }
    }

    /// The bitrate in bits per second and the sample rate of a Layer III frame header at `i`.
    private static func layer3Format(_ data: [UInt8], at i: Int) -> (bitrate: Int, sampleRate: Int)? {
        let version = (data[i + 1] >> 3) & 0x3
        let layer = (data[i + 1] >> 1) & 0x3
        let bitrateIndex = Int(data[i + 2] >> 4)
        let rateIndex = Int((data[i + 2] >> 2) & 0x3)
        guard version != 1, layer == 1, (1...14).contains(bitrateIndex), rateIndex < 3 else { return nil }
        let isMPEG1 = version == 3
        let kilobits =
            isMPEG1
            ? [32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320]
            : [8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160]
        // MPEG-2 halves MPEG-1's sample rates and MPEG-2.5 halves them again.
        let sampleRate = [44_100, 48_000, 32_000][rateIndex] >> (isMPEG1 ? 0 : version == 2 ? 1 : 2)
        return (kilobits[bitrateIndex - 1] * 1000, sampleRate)
    }

    private static func isSync(_ data: [UInt8], _ i: Int) -> Bool {
        data[i] == 0xFF && data[i + 1] & 0xE0 == 0xE0
    }

    private static func marker(_ name: String, in data: [UInt8], at offset: Int) -> Bool {
        offset + 4 <= data.count && String(decoding: data[offset..<offset + 4], as: UTF8.self) == name
    }
}
