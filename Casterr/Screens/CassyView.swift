import CasterrCore
import SwiftUI

/// Cassy, the cassette mascot. Her reels are her eyes. Drawn as a sticker: cream body,
/// dark outline, hard orange shadow. Geometry is in a 124 by 96 box, as in the design mockups.
struct CassyView: View {
    /// What she's doing here. `idle` plays random loops; every other job shows its catalog animation.
    let job: CassyJob
    var size: CGFloat = 120

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The idle loop playing now, and when it started.
    @State private var loop: (kind: CassyAnimation, start: Date)?
    /// The job's animation, picked when she's created so even her first frame shows it.
    @State private var chosen: CassyAnimation?

    init(job: CassyJob, size: CGFloat = 120) {
        self.job = job
        self.size = size
        var generator = SystemRandomNumberGenerator()
        _chosen = State(initialValue: job.animation(using: &generator))
    }

    private var animates: Bool {
        if reduceMotion { return false }
        return job == .idle ? loop != nil : true
    }

    var body: some View {
        // 30 frames a second is plenty for her motion and easier on the battery.
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animates)) { timeline in
            let t = animates ? timeline.date.timeIntervalSinceReferenceDate : 0
            let progress = loop.map { min(1, timeline.date.timeIntervalSince($0.start) / ($0.kind.duration ?? 1)) } ?? 0
            Canvas { context, canvasSize in
                let scale = canvasSize.width / 124
                context.scaleBy(x: scale, y: scale)
                context.translateBy(x: 0, y: 4)
                CassyDrawing(animation: loop?.kind ?? chosen, time: t, still: !animates, progress: progress)
                    .draw(in: &context)
            }
        }
        .frame(width: size, height: size * 0.78)
        .task(id: job) {
            // A new job (say idle, then success) picks again.
            if chosen.map({ !job.animations.contains($0) }) ?? !job.animations.isEmpty {
                var generator = SystemRandomNumberGenerator()
                chosen = job.animation(using: &generator)
            }
            await playIdleLoops()
        }
        .accessibilityElement()
        .accessibilityLabel("Cassy, \(job.rawValue)")
    }
}

extension CassyView {
    /// Plays random loops with a short pause before each one, never the same twice in a row.
    private func playIdleLoops() async {
        guard job == .idle else { return }
        var generator = SystemRandomNumberGenerator()
        var previous: CassyAnimation?
        while true {
            do { try await Task.sleep(for: .seconds(Double.random(in: CassyAnimation.pause))) } catch { return }
            guard !reduceMotion else { continue }
            let next = CassyAnimation.nextIdleLoop(after: previous, using: &generator)
            previous = next
            loop = (next, .now)
            do { try await Task.sleep(for: .seconds(next.duration ?? 1)) } catch { loop = nil; return }
            loop = nil
        }
    }
}

/// Draws one frame. `animation` nil is the resting idle face; an idle loop draws at `progress`;
/// a functional animation repeats on `time`.
private struct CassyDrawing {
    let animation: CassyAnimation?
    let time: Double
    let still: Bool
    var progress: Double = 0

    /// 0 at `from`, 1 halfway, 0 again at `to`; eased.
    private func bump(_ p: Double, _ from: Double, _ to: Double) -> Double {
        guard p > from, p < to else { return 0 }
        return sin((p - from) / (to - from) * .pi)
    }

    static let cream = Color(red: 1, green: 0.957, blue: 0.925)
    static let ink = Color(red: 0.227, green: 0.078, blue: 0.02)
    static let orange = Color(red: 1, green: 0.353, blue: 0.122)
    static let star = Color(red: 1, green: 0.784, blue: 0.227)

    private func line(_ path: Path, _ width: CGFloat, in context: inout GraphicsContext, opacity: Double = 1) {
        context.stroke(path, with: .color(Self.ink.opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func quad(_ points: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)]) -> Path {
        Path { p in
            for (x0, y0, cx, cy, x1, y1) in points {
                p.move(to: CGPoint(x: x0, y: y0))
                p.addQuadCurve(to: CGPoint(x: x1, y: y1), control: CGPoint(x: cx, y: cy))
            }
        }
    }

    func draw(in context: inout GraphicsContext) {
        if let loop = animation, loop.isIdleLoop {
            // Loops that move her whole body turn or lift around the bottom center.
            let p = progress
            var angle = 0.0, lift = 0.0
            switch loop {
            case .breathe: lift = 1.5 * sin(p * .pi)
            case .hum: angle = 2.5 * sin(p * 2 * .pi)
            case .peek: angle = -9 * bump(p, 0, 0.5) + 6 * bump(p, 0.5, 1)
            default: break
            }
            context.translateBy(x: 60, y: 84 - lift)
            context.rotate(by: .degrees(angle))
            context.translateBy(x: -60, y: -84)
        }
        // Loading: bounce squashes and stretches on each hop; jog leans side to side with a bob.
        if animation == .bounce || animation == .jog {
            let period = animation == .bounce ? 0.62 : 0.5
            let f = still ? 0 : (time / period).truncatingRemainder(dividingBy: 1)
            let k = cos(f * 2 * .pi)
            context.translateBy(x: 60, y: 86)
            if animation == .bounce {
                context.translateBy(x: 0, y: -7 * sin(f * .pi))
                context.scaleBy(x: 1 + 0.05 * k, y: 1 - 0.05 * k)
            } else {
                context.translateBy(x: 0, y: -3 * abs(sin(f * 2 * .pi)))
                context.rotate(by: .degrees(-5 * k))
            }
            context.translateBy(x: -60, y: -86)
        }
        // Cheering hops; the hop is a short lift every 1.1 seconds.
        if animation == .cheer {
            let phase = (time / 1.1).truncatingRemainder(dividingBy: 1)
            context.translateBy(x: 0, y: -5 * max(0, sin(phase * .pi * 2.5)) * (phase < 0.4 ? 1 : 0))
        }
        drawExtras(in: &context)
        drawBody(in: &context)
        drawFace(in: &context)
    }

    private func drawBody(in context: inout GraphicsContext) {
        context.fill(Path(roundedRect: CGRect(x: 13, y: 19, width: 104, height: 66), cornerRadius: 16), with: .color(Self.orange))
        let body = Path(roundedRect: CGRect(x: 8, y: 14, width: 104, height: 66), cornerRadius: 16)
        context.fill(body, with: .color(Self.cream))
        line(body, 4, in: &context)
        line(Path(roundedRect: CGRect(x: 19, y: 23, width: 82, height: 36), cornerRadius: 9), 3, in: &context)
        line(Path { p in
            p.move(to: CGPoint(x: 42, y: 80)); p.addLine(to: CGPoint(x: 46, y: 74))
            p.addLine(to: CGPoint(x: 74, y: 74)); p.addLine(to: CGPoint(x: 78, y: 80))
        }, 2.5, in: &context, opacity: 0.55)
    }

    private func eyeSocket(_ cx: CGFloat, in context: inout GraphicsContext) {
        let socket = Path(ellipseIn: CGRect(x: cx - 11, y: 31, width: 22, height: 22))
        context.fill(socket, with: .color(Self.cream))
        line(socket, 3, in: &context)
    }

    private func reel(_ cx: CGFloat, angle: Double, look: CGPoint = .zero, squash: Double = 1, in context: inout GraphicsContext) {
        var eye = context
        eye.translateBy(x: cx, y: 42)
        eye.scaleBy(x: 1, y: max(squash, 0.08))
        eye.translateBy(x: -cx, y: -42)
        eyeSocket(cx, in: &eye)
        let hx = cx + look.x, hy = 42 + look.y
        eye.fill(Path(ellipseIn: CGRect(x: hx - 4.2, y: hy - 4.2, width: 8.4, height: 8.4)), with: .color(Self.ink))
        let spokes = Path { p in
            for k in 0..<4 {
                let a = angle + Double(k) * .pi / 2
                p.move(to: CGPoint(x: hx + 4.5 * cos(a), y: hy + 4.5 * sin(a)))
                p.addLine(to: CGPoint(x: hx + 8.5 * cos(a), y: hy + 8.5 * sin(a)))
            }
        }
        line(spokes, 2.2, in: &eye)
    }

    /// Her everyday eye: a cream socket with a round pupil and a white highlight. The spoked reels are
    /// kept for loading and the reel-twitch loop.
    private func eye(_ cx: CGFloat, look: CGPoint = .zero, squash: Double = 1, in context: inout GraphicsContext) {
        var eye = context
        eye.translateBy(x: cx, y: 42)
        eye.scaleBy(x: 1, y: max(squash, 0.08))
        eye.translateBy(x: -cx, y: -42)
        eyeSocket(cx, in: &eye)
        let px = cx + look.x, py = 42.5 + look.y
        eye.fill(Path(ellipseIn: CGRect(x: px - 6.2, y: py - 6.2, width: 12.4, height: 12.4)), with: .color(Self.ink))
        eye.fill(Path(ellipseIn: CGRect(x: px + 0.2, y: py - 4.5, width: 4, height: 4)), with: .color(.white))
    }

    /// The idle face: shining eyes and a smile, changed by whichever loop is playing.
    private func drawIdleFace(_ loop: CassyAnimation?, in context: inout GraphicsContext) {
        let smile = quad([(52, 66, 60, 72, 68, 66)])
        let p = progress
        switch loop {
        case nil, .bounce?, .jog?, .dozing?, .cheer?, .dizzy?:
            eye(42, in: &context)
            eye(78, in: &context)
            line(smile, 3, in: &context)
        case .blink:
            let squash = 1 - 0.92 * bump(p, 0, 1)
            eye(42, squash: squash, in: &context)
            eye(78, squash: squash, in: &context)
            line(smile, 3, in: &context)
        case .wink:
            let wink = bump(p, 0.05, 0.95)
            eye(42, in: &context)
            eye(78, squash: 1 - 0.92 * wink, in: &context)
            line(wink > 0.2 ? quad([(53, 67, 61, 71, 67, 65)]) : smile, 3, in: &context)
        case .lookAround:
            let x = -3.5 * bump(p, 0, 0.5) + 3.5 * bump(p, 0.35, 0.8)
            let y = -2 * bump(p, 0.7, 1)
            eye(42, look: CGPoint(x: x, y: y), in: &context)
            eye(78, look: CGPoint(x: x, y: y), in: &context)
            line(smile, 3, in: &context)
        case .breathe:
            let squash = 1 - 0.92 * bump(p, 0.45, 0.55)
            eye(42, squash: squash, in: &context)
            eye(78, squash: squash, in: &context)
            line(smile, 3, in: &context)
        case .reelTwitch:
            let angle = p < 0.25 ? 0 : p < 0.5 ? 0.87 : p < 0.75 ? 0.52 : 1.57
            reel(42, angle: angle, in: &context)
            reel(78, angle: angle, in: &context)
            line(smile, 3, in: &context)
        case .hum:
            line(quad([(33, 46, 42, 36, 51, 46), (69, 46, 78, 36, 87, 46)]), 3.2, in: &context)
            line(smile, 3, in: &context)
            for (offset, symbol, color) in [(0.0, "music.note", Self.ink), (0.45, "music.note.list", Self.orange)] {
                let q = p - offset
                guard q > 0 else { continue }
                var note = context
                note.opacity = q < 0.25 ? q / 0.25 : max(0, 1 - (q - 0.25) / 0.5)
                var image = note.resolve(Image(systemName: symbol))
                image.shading = .color(color)
                note.draw(image, in: CGRect(x: 98 + 10 * q, y: 2 - 18 * q, width: 13, height: 14))
            }
        case .yawn:
            let open = bump(p, 0.1, 0.9)
            eye(42, squash: 1 - 0.75 * open, in: &context)
            eye(78, squash: 1 - 0.75 * open, in: &context)
            let ry = 2.6 + 4.6 * open, rx = 3.5 + 1.5 * open
            context.fill(Path(ellipseIn: CGRect(x: 60 - rx, y: 67 - ry, width: rx * 2, height: ry * 2)), with: .color(Self.ink))
        case .peek:
            let x = -3 * bump(p, 0, 0.5) + 3 * bump(p, 0.5, 1)
            eye(42, look: CGPoint(x: x, y: -1), in: &context)
            eye(78, look: CGPoint(x: x, y: -1), in: &context)
            line(smile, 3, in: &context)
        }
    }

    private func spiral(_ cx: CGFloat, angle: Double, in context: inout GraphicsContext) {
        eyeSocket(cx, in: &context)
        let path = Path { p in
            for step in 0...80 {
                let theta = Double(step) / 80 * 4 * .pi
                let r = 0.8 + 6.4 * theta / (4 * .pi)
                let point = CGPoint(x: cx + r * cos(theta + angle), y: 42 + r * sin(theta + angle))
                step == 0 ? p.move(to: point) : p.addLine(to: point)
            }
        }
        line(path, 2, in: &context)
    }

    private func drawFace(in context: inout GraphicsContext) {
        switch animation {
        case .bounce, .jog:
            let angle = time * 2 * .pi / 0.7
            reel(42, angle: angle, in: &context)
            reel(78, angle: angle, in: &context)
            var mouth = quad([(48, 62, 60, 74, 72, 62)])
            mouth.closeSubpath()
            context.fill(mouth, with: .color(Self.ink))
        case .dozing:
            line(quad([(33, 43, 42, 49, 51, 43), (69, 43, 78, 49, 87, 43)]), 3.2, in: &context)
            context.fill(Path(ellipseIn: CGRect(x: 56.5, y: 64.4, width: 7, height: 5.2)), with: .color(Self.ink))
        case .cheer:
            line(quad([(33, 46, 42, 36, 51, 46), (69, 46, 78, 36, 87, 46)]), 3.2, in: &context)
            var mouth = quad([(48, 62, 60, 74, 72, 62)])
            mouth.closeSubpath()
            context.fill(mouth, with: .color(Self.ink))
        case .dizzy:
            let angle = time * 2 * .pi / 1.8
            spiral(42, angle: angle, in: &context)
            spiral(78, angle: angle, in: &context)
            line(Path { p in
                p.move(to: CGPoint(x: 47, y: 67))
                var x: CGFloat = 47
                for k in 0..<4 {
                    p.addQuadCurve(to: CGPoint(x: x + 6.5, y: 67), control: CGPoint(x: x + 3.25, y: k.isMultiple(of: 2) ? 63 : 71))
                    x += 6.5
                }
            }, 3, in: &context)
        default:
            drawIdleFace(animation, in: &context)
        }
    }

    private func drawExtras(in context: inout GraphicsContext) {
        switch animation {
        case .jog:
            // Speed lines flicker behind her.
            var lines = context
            lines.opacity = still ? 0.7 : 0.2 + 0.7 * (0.5 + 0.5 * sin(time * 2 * .pi / 0.5))
            line(Path { p in
                for (x0, y, x1) in [(-4.0, 32.0, 6.0), (-8, 44, 6), (-4, 56, 6)] {
                    p.move(to: CGPoint(x: x0, y: y)); p.addLine(to: CGPoint(x: x1, y: y))
                }
            }, 2.6, in: &lines)
        case .dozing:
            for (offset, size, x, y) in [(0.0, 13.0, 98.0, 14.0), (0.5, 10.0, 107.0, 6.0)] {
                let phase = still ? 0.3 : (time / 2.6 + offset).truncatingRemainder(dividingBy: 1)
                let opacity = phase < 0.3 ? phase / 0.3 * 0.9 : 0.9 * (1 - (phase - 0.3) / 0.7)
                var z = context
                z.opacity = still ? 0.8 : opacity
                z.draw(Text("z").font(.system(size: size, weight: .heavy, design: .rounded)).foregroundStyle(Self.ink),
                       at: CGPoint(x: x + 8 * phase, y: y + 4 - 18 * phase))
            }
        case .cheer:
            context.stroke(Path { p in
                for (x0, y0, x1, y1) in [(4.0, 6.0, 7.0, 11.0), (116, 6, 113, 11), (12, 2, 13, 6), (108, 2, 107, 6)] {
                    p.move(to: CGPoint(x: x0, y: y0)); p.addLine(to: CGPoint(x: x1, y: y1))
                }
            }, with: .color(Self.orange), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        case .dizzy:
            let bob = still ? 0 : -2 * sin(time * 2 * .pi / 1.6)
            for (x, y, s) in [(18.0, 8.0, 6.0), (104, 4, 5), (60, -1, 4)] {
                let cy = y + bob
                let star = Path { p in
                    p.move(to: CGPoint(x: x, y: cy - s))
                    p.addLine(to: CGPoint(x: x + s * 0.3, y: cy - s * 0.3))
                    p.addLine(to: CGPoint(x: x + s, y: cy))
                    p.addLine(to: CGPoint(x: x + s * 0.3, y: cy + s * 0.3))
                    p.addLine(to: CGPoint(x: x, y: cy + s))
                    p.addLine(to: CGPoint(x: x - s * 0.3, y: cy + s * 0.3))
                    p.addLine(to: CGPoint(x: x - s, y: cy))
                    p.addLine(to: CGPoint(x: x - s * 0.3, y: cy - s * 0.3))
                    p.closeSubpath()
                }
                context.fill(star, with: .color(Self.star))
            }
        default:
            break
        }
    }
}
