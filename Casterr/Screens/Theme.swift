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

/// A show's artwork, or a tangerine square with the show's first letter while it loads or when there's none.
struct ArtworkView: View {
    let url: URL?
    let title: String
    let size: CGFloat
    @Environment(\.displayScale) private var scale
    @State private var image: UIImage?

    var body: some View {
        Group {
            // A kept image shows on the first frame, with no placeholder flash.
            if let image = image ?? url.flatMap({ ArtCache.kept($0, pixels: size * scale) }) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Color.tangerine.overlay {
                    Text(title.first.map(String.init) ?? "")
                        .font(.system(size: size * 0.45, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: size * 0.23))
        .accessibilityHidden(true)
        .task(id: url) {
            image = nil
            guard let url else { return }
            image = await ArtCache.image(for: url, pixels: size * scale)
        }
    }
}

/// Show art, kept once loaded: files in the 300 MB download cache, read without asking the server again,
/// and decoded images in memory so lists don't flash the placeholder.
@MainActor
enum ArtCache {
    private static let memory = NSCache<NSString, UIImage>()

    /// The decoded art already in memory, if any.
    static func kept(_ url: URL, pixels: CGFloat) -> UIImage? {
        memory.object(forKey: key(url, pixels))
    }

    /// The art at `url`, shrunk to `pixels` wide. Nil when it can't be loaded.
    static func image(for url: URL, pixels: CGFloat) async -> UIImage? {
        let key = key(url, pixels)
        if let image = memory.object(forKey: key) { return image }
        let side = max(pixels.rounded(.up), 1)
        guard let data = await data(for: url), let full = UIImage(data: data) else { return nil }
        // Feeds often carry 3000-pixel art; shrinking keeps memory small and decodes it off the main thread.
        let shrunk = CGSize(width: side, height: side * full.size.height / max(full.size.width, 1))
        let image = await full.byPreparingThumbnail(ofSize: shrunk) ?? full
        memory.setObject(image, forKey: key)
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
    }

    private static func key(_ url: URL, _ pixels: CGFloat) -> NSString {
        "\(Int(pixels.rounded(.up))) \(url.absoluteString)" as NSString
    }

    private static func data(for url: URL) async -> Data? {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        return try? await URLSession.shared.data(for: request).0
    }
}
