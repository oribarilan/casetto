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

/// A show's artwork, or a tangerine square with the show's first letter.
struct ArtworkView: View {
    let url: URL?
    let title: String
    let size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
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
    }
}
