import SwiftUI

/// A one-time, just-in-time tip in Cassy's sticker style, pointing at a control.
///
/// Mark the control with `.cassyTipTarget(_:)`, host tips on the screen with `.cassyTips(_:)`,
/// and create the tip with `CassyTip.once(_:target:text:)` at the moment the listener needs it.
/// The tip closes with its ✕ or a tap anywhere else, and never shows again.
struct CassyTip: Equatable {
    /// Names the tip, so it shows once per install.
    let id: String
    /// The `cassyTipTarget` it points at.
    let target: String
    let text: String

    /// The tip, if it hasn't been shown before. Creating it counts as showing it.
    static func once(_ id: String, target: String, text: String) -> CassyTip? {
        guard !hasShown(id) else { return nil }
        markShown(id)
        return CassyTip(id: id, target: target, text: text)
    }

    static func hasShown(_ id: String) -> Bool {
        UserDefaults.standard.bool(forKey: key(id))
    }

    /// For when the listener already did what the tip would teach.
    static func markShown(_ id: String) {
        UserDefaults.standard.set(true, forKey: key(id))
    }

    private static func key(_ id: String) -> String { "hasSeenTip.\(id)" }
}

/// Where each tip target sits on screen, keyed by target name.
private struct CassyTipAnchors: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Makes this view a place a tip can point at.
    func cassyTipTarget(_ name: String) -> some View {
        anchorPreference(key: CassyTipAnchors.self, value: .bounds) { [name: $0] }
    }

    /// Shows `tip` over this view, pointing at its target while the target is on screen.
    func cassyTips(_ tip: Binding<CassyTip?>) -> some View {
        overlayPreferenceValue(CassyTipAnchors.self) { anchors in
            GeometryReader { proxy in
                if let current = tip.wrappedValue, let anchor = anchors[current.target] {
                    CassyTipLayer(tip: current, target: proxy[anchor], area: proxy.size) {
                        withAnimation(.easeOut(duration: 0.15)) { tip.wrappedValue = nil }
                    }
                }
            }
        }
    }
}

/// Catches taps anywhere to close the tip, and places the bubble under its target, or above it near the bottom.
private struct CassyTipLayer: View {
    let tip: CassyTip
    let target: CGRect
    let area: CGSize
    let close: () -> Void

    private let width: CGFloat = 250
    private let margin: CGFloat = 12

    var body: some View {
        let below = target.maxY + 120 < area.height
        let x = min(max(target.midX - width / 2, margin), area.width - width - margin)
        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(.rect)
                .onTapGesture(perform: close)
                .accessibilityHidden(true)
            CassyTipBubble(text: tip.text, tailX: target.midX - x, tailOnTop: below, close: close)
                .frame(width: width)
                .fixedSize(horizontal: false, vertical: true)
                .alignmentGuide(.leading) { _ in -x }
                .alignmentGuide(.top) { d in below ? -(target.maxY + 4) : -(target.minY - 4 - d.height) }
        }
        .transition(.opacity)
    }
}

/// The sticker bubble: cream fill, dark outline, hard orange shadow, a tail, and a ✕ in faded ink, readable in dark mode too.
private struct CassyTipBubble: View {
    let text: String
    let tailX: CGFloat
    let tailOnTop: Bool
    let close: () -> Void

    static let cream = Color(red: 1, green: 0.957, blue: 0.925)
    static let ink = Color(red: 0.227, green: 0.078, blue: 0.02)
    static let orange = Color(red: 1, green: 0.353, blue: 0.122)

    var body: some View {
        let shape = TipShape(tailX: tailX, tailOnTop: tailOnTop)
        HStack(alignment: .top, spacing: 8) {
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Self.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Dismiss tip", systemImage: "xmark", action: close)
                .labelStyle(.iconOnly)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Self.ink.opacity(0.6))
                .frame(width: 22, height: 22)
                .background(Self.ink.opacity(0.1), in: .circle)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.top, tailOnTop ? TipShape.tail + 10 : 10)
        .padding(.bottom, tailOnTop ? 10 : TipShape.tail + 10)
        .background {
            shape.fill(Self.orange).offset(x: 3, y: 3)
            shape.fill(Self.cream)
            shape.stroke(Self.ink, lineWidth: 2)
        }
        .accessibilityElement(children: .contain)
    }
}

/// A rounded rectangle with a small tail on its top or bottom edge, at `tailX`.
private struct TipShape: Shape {
    static let tail: CGFloat = 9
    let tailX: CGFloat
    let tailOnTop: Bool

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 14, t = Self.tail, half: CGFloat = 8
        let body = CGRect(x: rect.minX, y: rect.minY + (tailOnTop ? t : 0), width: rect.width, height: rect.height - t)
        let tx = min(max(tailX, body.minX + r + half), body.maxX - r - half)
        return Path { p in
            p.move(to: CGPoint(x: body.minX + r, y: body.minY))
            if tailOnTop {
                p.addLine(to: CGPoint(x: tx - half, y: body.minY))
                p.addLine(to: CGPoint(x: tx, y: body.minY - t))
                p.addLine(to: CGPoint(x: tx + half, y: body.minY))
            }
            p.addLine(to: CGPoint(x: body.maxX - r, y: body.minY))
            p.addArc(tangent1End: CGPoint(x: body.maxX, y: body.minY), tangent2End: CGPoint(x: body.maxX, y: body.minY + r), radius: r)
            p.addLine(to: CGPoint(x: body.maxX, y: body.maxY - r))
            p.addArc(tangent1End: CGPoint(x: body.maxX, y: body.maxY), tangent2End: CGPoint(x: body.maxX - r, y: body.maxY), radius: r)
            if !tailOnTop {
                p.addLine(to: CGPoint(x: tx + half, y: body.maxY))
                p.addLine(to: CGPoint(x: tx, y: body.maxY + t))
                p.addLine(to: CGPoint(x: tx - half, y: body.maxY))
            }
            p.addLine(to: CGPoint(x: body.minX + r, y: body.maxY))
            p.addArc(tangent1End: CGPoint(x: body.minX, y: body.maxY), tangent2End: CGPoint(x: body.minX, y: body.maxY - r), radius: r)
            p.addLine(to: CGPoint(x: body.minX, y: body.minY + r))
            p.addArc(tangent1End: CGPoint(x: body.minX, y: body.minY), tangent2End: CGPoint(x: body.minX + r, y: body.minY), radius: r)
            p.closeSubpath()
        }
    }
}
