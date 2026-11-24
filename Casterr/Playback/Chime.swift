import AVFoundation

/// A short two-note chime that confirms a bookmark made from headphone or car buttons.
@MainActor
enum Chime {
    private static var player: AVAudioPlayer?

    static func play() {
        // The app's playback audio session lets it sound with silent mode on.
        player = try? AVAudioPlayer(data: wav)
        player?.volume = 1.0
        player?.play()
    }

    private static let wav: Data = {
        let rate = 44_100
        var samples: [Int16] = []
        for (frequency, seconds) in [(880.0, 0.09), (1320.0, 0.14)] {
            let count = Int(Double(rate) * seconds)
            for i in 0..<count {
                let t = Double(i) / Double(rate)
                let envelope = min(1, Double(i) / 300) * (1 - Double(i) / Double(count))
                samples.append(Int16(sin(2 * .pi * frequency * t) * envelope * 28_000))
            }
        }
        var data = Data()
        func append<T>(_ value: T) { withUnsafeBytes(of: value) { data.append(contentsOf: $0) } }
        let bytes = UInt32(samples.count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); append(UInt32(36 + bytes).littleEndian)
        data.append(contentsOf: Array("WAVEfmt ".utf8)); append(UInt32(16).littleEndian)
        append(UInt16(1).littleEndian); append(UInt16(1).littleEndian)
        append(UInt32(rate).littleEndian); append(UInt32(rate * 2).littleEndian)
        append(UInt16(2).littleEndian); append(UInt16(16).littleEndian)
        data.append(contentsOf: Array("data".utf8)); append(bytes.littleEndian)
        for sample in samples { append(sample.littleEndian) }
        return data
    }()
}
