import SwiftUI
import UIKit

/// What the Inbox card does when the listener swipes it off: right queues, left removes.
struct CardSwipe {
    var queue: () -> Void
    var remove: () -> Void
}

/// Lets the Inbox card follow a sideways drag. Past a third of its width, or on a flick, it flies off and acts;
/// before that it springs back. A drag that starts up or down is left to the List, so the Inbox still scrolls.
struct CardDrag: ViewModifier {
    let swipe: CardSwipe
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGFloat = 0
    @State private var width: CGFloat = 320
    @State private var faded = false

    private var pastPoint: Bool { abs(offset) > width / 3 }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                stamp("Queue", "text.badge.plus", tint: .tangerineText, tilt: -10)
                    .opacity(min(1, max(0, offset / 90)))
            }
            .overlay(alignment: .topTrailing) {
                stamp("Remove", "minus.circle", tint: .secondary, tilt: 10)
                    .opacity(min(1, max(0, -offset / 90)))
            }
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
            .rotationEffect(.degrees(reduceMotion ? 0 : offset / 20), anchor: .bottom)
            .offset(x: offset)
            .opacity(faded ? 0 : 1)
            .gesture(SidewaysPan(changed: { offset = $0 }, ended: end))
            .sensoryFeedback(.impact(weight: .light), trigger: pastPoint) { _, past in past }
    }

    private func stamp(_ title: String, _ symbol: String, tint: Color, tilt: Double) -> some View {
        Label(title, systemImage: symbol)
            .font(.headline.weight(.heavy))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.regularMaterial, in: .rect(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint, lineWidth: 2.5))
            .rotationEffect(.degrees(tilt))
            .padding(14)
            .accessibilityHidden(true)
    }

    private func end(_ x: CGFloat, _ velocity: CGFloat) {
        let flick = abs(velocity) > 900 && abs(x) > 24 && (velocity > 0) == (x > 0)
        guard abs(x) > width / 3 || flick else {
            withAnimation(reduceMotion ? nil : .snappy) { offset = 0 }
            return
        }
        let right = x > 0
        withAnimation(.easeOut(duration: 0.22)) {
            if reduceMotion { faded = true } else { offset = (right ? 1.6 : -1.6) * width }
        } completion: {
            right ? swipe.queue() : swipe.remove()
        }
    }
}

/// A pan that begins only when the finger moves more sideways than up or down.
private struct SidewaysPan: UIGestureRecognizerRepresentable {
    let changed: (CGFloat) -> Void
    let ended: (_ translation: CGFloat, _ velocity: CGFloat) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func handleUIGestureRecognizerAction(_ pan: UIPanGestureRecognizer, context: Context) {
        let x = pan.translation(in: nil).x
        switch pan.state {
        case .changed: changed(x)
        case .ended: ended(x, pan.velocity(in: nil).x)
        case .cancelled, .failed: ended(0, 0)
        default: break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: nil)
            return abs(velocity.x) > abs(velocity.y)
        }
    }
}
