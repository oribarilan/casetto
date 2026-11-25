import CasterrCore
import CryptoKit
import SwiftUI
import UIKit

extension Color {
    /// The accent: tangerine, a little lighter in dark mode.
    static let tangerine = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 0.478, blue: 0.271, alpha: 1)
            : UIColor(red: 1, green: 0.353, blue: 0.122, alpha: 1)
    })
}

extension Color {
    /// Tangerine for text: darker in light mode and lighter in dark mode, so it passes 4.5:1 contrast.
    static let tangerineText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 0.541, blue: 0.361, alpha: 1)
            : UIColor(red: 0.761, green: 0.255, blue: 0.047, alpha: 1)
    })
}

extension Color {
    /// Dark brown for text and symbols on tangerine: white on tangerine is only 3:1, too faint to read.
    static let onTangerine = Color(red: 0.227, green: 0.078, blue: 0.02)
}

extension View {
    /// A filled tangerine button with dark brown text.
    func filledButton() -> some View {
        buttonStyle(.borderedProminent).foregroundStyle(Color.onTangerine)
    }
}

@MainActor
enum Theme {
    /// Heavy rounded navigation titles, and an image cache big enough that lists don't re-download art.
    static func apply() {
        func rounded(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            return UIFont(descriptor: base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor, size: size)
        }
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.font: rounded(34, .black)]
        bar.titleTextAttributes = [.font: rounded(17, .bold)]
        URLCache.shared = URLCache(memoryCapacity: 50_000_000, diskCapacity: 300_000_000)
    }
}

/// A shimmering bar that stands in for a line of text while it loads.
struct PlaceholderBar: View {
    var width: CGFloat?
    var height: CGFloat = 12

    var body: some View {
        Shimmer()
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .clipShape(.capsule)
    }
}

/// A show's artwork. A grey shimmer while it downloads, and a tangerine square with the show's first letter
/// when there's no art or it fails to load.
struct ArtworkView: View {
    let url: URL?
    let title: String
    let size: CGFloat
    @Environment(\.displayScale) private var scale
    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            // A kept image shows on the first frame, with no shimmer.
            if let image = image ?? url.flatMap({ ArtCache.kept($0, pixels: size * scale) }) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if url == nil || failed {
                Color.tangerine.overlay {
                    Text(title.first.map(String.init) ?? "")
                        .font(.system(size: size * 0.45, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            } else {
                Shimmer()
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: size * 0.23))
        .accessibilityHidden(true)
        .task(id: url) {
            image = nil
            failed = false
            guard let url else { return }
            let started = Date.now
            let loaded = await ArtCache.image(for: url, pixels: size * scale)
            // Art saved on the device arrives in a few milliseconds and pops in; a download fades in.
            withAnimation(Date.now.timeIntervalSince(started) < 0.1 ? nil : .easeOut(duration: 0.25)) {
                image = loaded
                failed = loaded == nil
            }
        }
    }
}

/// A soft grey placeholder with a light band sweeping across, or still grey with Reduce Motion.
/// Art, and the bars that stand in for text while a page loads.
struct Shimmer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var sweeping = false

    var body: some View {
        // A fill that adapts to what's behind it, so the shape shows on light and dark rows alike.
        Color(.tertiarySystemFill)
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(colors: [.clear, .white.opacity(colorScheme == .dark ? 0.08 : 0.35), .clear],
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: proxy.size.width * 0.6)
                            .offset(x: proxy.size.width * (sweeping ? 1 : -0.6))
                    }
                    .onAppear {
                        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { sweeping = true }
                    }
                }
            }
            .clipped()
    }
}

/// Show art, kept once loaded: originals in the 300 MB download cache, read without asking the server again;
/// shrunk copies as small files, so a launch doesn't shrink 3000-pixel art again; and decoded images in memory,
/// so lists don't flash the placeholder.
@MainActor
enum ArtCache {
    private static let memory = NSCache<NSString, UIImage>()
    private static let folder = URL.cachesDirectory.appending(path: "Art")

    /// Bytes of shrunk copies on disk.
    static var diskSize: Int { FileManager.default.size(ofFolder: folder) }

    /// The decoded art already in memory, if any.
    static func kept(_ url: URL, pixels: CGFloat) -> UIImage? {
        memory.object(forKey: key(url, pixels))
    }

    /// The art at `url`, shrunk to `pixels` wide. Nil when it can't be loaded.
    static func image(for url: URL, pixels: CGFloat) async -> UIImage? {
        let key = key(url, pixels)
        if let image = memory.object(forKey: key) { return image }
        let file = folder.appending(path: SHA256.hash(data: Data((key as String).utf8)).map { String(format: "%02x", $0) }.joined())
        if let saved = UIImage(contentsOfFile: file.path(percentEncoded: false)),
           let image = await saved.byPreparingForDisplay() {
            memory.setObject(image, forKey: key)
            return image
        }
        let side = max(pixels.rounded(.up), 1)
        guard let data = await data(for: url), let full = UIImage(data: data) else { return nil }
        // Feeds often carry 3000-pixel art; shrinking keeps memory small and decodes it off the main thread.
        let shrunk = CGSize(width: side, height: side * full.size.height / max(full.size.width, 1))
        let image = await full.byPreparingThumbnail(ofSize: shrunk) ?? full
        memory.setObject(image, forKey: key)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? image.jpegData(compressionQuality: 0.85)?.write(to: file, options: .atomic)
        return image
    }

    /// Downloads art not yet kept, so it shows at once later, offline too.
    static func keep(_ urls: [URL]) {
        for url in urls { Task { _ = await data(for: url) } }
    }

    /// Forgets every kept image. Feeds and charts download again when needed.
    static func clear() {
        memory.removeAllObjects()
        URLCache.shared.removeAllCachedResponses()
        try? FileManager.default.removeItem(at: folder)
    }

    private static func key(_ url: URL, _ pixels: CGFloat) -> NSString {
        "\(Int(pixels.rounded(.up))) \(url.absoluteString)" as NSString
    }

    private static func data(for url: URL) async -> Data? {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        return try? await URLSession.shared.data(for: request).0
    }
}

/// How long an icon's spin lasts.
private let spinSeconds = 0.6

extension View {
    /// Spins this icon in from `angle`, growing from 0.6 to full size, each time `trigger` changes.
    /// Opening a screen doesn't spin it, and with Reduce Motion on it never spins.
    func spin(from angle: Angle, trigger: Int) -> some View {
        modifier(Spin(start: angle, trigger: trigger))
    }
}

private struct Spin: ViewModifier {
    let start: Angle
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Pose {
        var angle = Angle.zero
        var scale = 1.0
    }

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.keyframeAnimator(initialValue: Pose(), trigger: trigger) { view, pose in
                view.rotationEffect(pose.angle).scaleEffect(pose.scale)
            } keyframes: { _ in
                KeyframeTrack(\.angle) {
                    MoveKeyframe(start)
                    SpringKeyframe(.zero, duration: spinSeconds, spring: .bouncy)
                }
                KeyframeTrack(\.scale) {
                    MoveKeyframe(0.6)
                    SpringKeyframe(1, duration: spinSeconds, spring: .bouncy)
                }
            }
        }
    }
}
