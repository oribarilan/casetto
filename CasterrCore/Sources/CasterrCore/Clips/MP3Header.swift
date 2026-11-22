import Foundation

/// Reads the start of an MP3 file, to tell whether its bytes can be fetched by time.
public enum MP3Header {
    /// The bytes before the audio: the whole ID3v2 tag with its header (and footer), or 0 without one.
    /// Nil with fewer than 10 bytes.
    public static func id3TagSize(_ header: Data) -> Int? {
        let bytes = [UInt8](header.prefix(10))
        guard bytes.count == 10 else { return nil }
        guard bytes[0...2] == [0x49, 0x44, 0x33] else { return 0 } // "ID3"
        // The size is syncsafe: 7 bits in each of 4 bytes.
        let size = bytes[6...9].reduce(0) { $0 << 7 | Int($1 & 0x7F) }
        let footer = bytes[5] & 0x10 != 0 ? 10 : 0
        return 10 + size + footer
    }

    /// Whether the first MPEG frame in `bytes` carries a Xing or VBRI header, which marks variable bitrate.
    /// Nil when `bytes` holds no frame header.
    public static func isVariableBitrate(_ bytes: Data) -> Bool? {
        let data = [UInt8](bytes)
        guard let frame = data.indices.dropLast(3).first(where: { data[$0] == 0xFF && data[$0 + 1] & 0xE0 == 0xE0 })
        else { return nil }
        let isMPEG1 = (data[frame + 1] >> 3) & 0x3 == 0x3
        let isMono = (data[frame + 3] >> 6) & 0x3 == 0x3
        let xing = frame + 4 + (isMPEG1 ? (isMono ? 17 : 32) : (isMono ? 9 : 17))
        return marker("Xing", in: data, at: xing) || marker("VBRI", in: data, at: frame + 36)
    }

    private static func marker(_ name: String, in data: [UInt8], at offset: Int) -> Bool {
        offset + 4 <= data.count && String(decoding: data[offset ..< offset + 4], as: UTF8.self) == name
    }
}
