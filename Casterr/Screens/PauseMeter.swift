import CasterrCore
import SwiftUI

/// The pause icon's two bars, each filling with tangerine from the bottom as loud as the voice is now (left) and a
/// tenth of a second ago (right). The mini player and Now Playing's pause button share it. With Reduce Motion it's
/// the plain pause icon.
struct PauseMeter: View {
    /// The bars' height; their width and the gap scale with it, in a pause icon's proportions.
    var height: CGFloat = 19
    /// The bars' color under the fill.
    var base = Color(.label)

    @Environment(Player.self) private var player
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // About ten updates a second, each easing out (fast start, slow finish), so the fill glides with the voice.
        TimelineView(.animation(minimumInterval: 0.1, paused: reduceMotion)) { _ in
            let levels = reduceMotion ? (now: 0.0, before: 0.0) : player.levels()
            HStack(spacing: height * 0.26) {
                bar(levels.now)
                bar(levels.before)
            }
        }
        .accessibilityHidden(true)
    }

    private func bar(_ level: Double) -> some View {
        let corner = height * 0.1
        return RoundedRectangle(cornerRadius: corner)
            .fill(base)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.tangerine).frame(height: height * level)
                    .animation(.easeOut(duration: 0.25), value: level)
            }
            .clipShape(.rect(cornerRadius: corner))
            .frame(width: height * 0.32, height: height)
    }
}
