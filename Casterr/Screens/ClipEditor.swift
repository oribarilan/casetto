import LinkPresentation
import AVFoundation
import CasterrCore
import os
import SwiftUI

/// What the clip editor works on, taken from the player when the listener taps Share Clip.
struct ClipRequest: Identifiable {
    let id = UUID()
    let window: ClipWindow
    let episode: EpisodeInfo
    let show: ShowInfo?
    /// What the player loaded. Nil when nothing was.
    let audioURL: URL?
    /// The playing chapter's picture, which Now Playing shows instead of the show's art.
    let chapterArt: Data?
}

/// Share Clip: the two minutes around now as loudness bars, with a clip framed in tangerine.
/// The edges drag and snap to pauses between words; Preview plays it and Share sends it as a square video.
struct ClipEditor: View {
    @Environment(Player.self) private var player
    @Environment(\.dismiss) private var dismiss
    let request: ClipRequest

    @State private var phase = Phase.loading
    @State private var clip: ClosedRange<TimeInterval>
    @State private var art: UIImage?
    /// The gap the last dragged edge snapped to, and which edge, for the tick and the hint.
    @State private var snap: (edge: ClipWindow.Edge, gap: TimeInterval?)?
    @State private var previewer: AVAudioPlayer?
    @State private var previewStop: Task<Void, Never>?
    @State private var exporting = false
    @State private var sharing: ClipShare?
    private static let log = Logger(subsystem: "sh.oribi.Casterr", category: "clips")

    enum Phase {
        case loading
        case ready(ClipSpan)
        case failed(String)
    }

    init(request: ClipRequest) {
        self.request = request
        _clip = State(initialValue: request.window.defaultClip)
    }

    private var window: ClipWindow { request.window }

    private var span: ClipSpan? {
        if case .ready(let span) = phase { span } else { nil }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                ClipFrame(art: art, side: 220)
                    .clipShape(.rect(cornerRadius: 18))
                    .accessibilityHidden(true)
                Text("\(clip.lowerBound.clockTenths) – \(clip.upperBound.clockTenths) · \((clip.upperBound - clip.lowerBound).rounded().clock)")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy).monospacedDigit())
                    .accessibilityIdentifier("clipTimes")
                bars
                Spacer(minLength: 0)
                buttons
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(white: 0.11))
            .navigationTitle("Share Clip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.tint(Color.tangerine)
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .sensoryFeedback(.selection, trigger: snap?.gap) { _, gap in gap != nil }
        .task { await load() }
        .onDisappear(perform: cleanUp)
        .sheet(item: $sharing) { share in
            ActivityView(items: [ClipItem(share), share.text, share.link]) { sharing = nil }
                .ignoresSafeArea()
                .onDisappear { try? FileManager.default.removeItem(at: share.video) }
        }
    }

    // MARK: Bars

    @ViewBuilder private var bars: some View {
        VStack(spacing: 6) {
            switch phase {
            case .loading:
                ProgressView().frame(height: 84)
            case .failed(let message):
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 84)
                    .accessibilityIdentifier("clipProblem")
            case .ready(let span):
                ClipBars(window: window, bars: span.bars, clip: clip, now: window.position,
                         drag: { drag($0, to: $1, gaps: span.gaps) },
                         adjust: { edge, seconds in adjust(edge, by: seconds) })
                    .frame(height: 84)
            }
            HStack {
                Text(window.span.lowerBound.clock)
                Spacer()
                Text("now \(window.position.clock)")
                Spacer()
                Text(window.span.upperBound.clock)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            if span != nil {
                hint
            }
        }
    }

    private var hint: some View {
        let snapped = Text(snap?.gap == nil ? "" : snap?.edge == .start ? "Start snapped to a pause. " : "End snapped to a pause. ")
            .foregroundStyle(Color.tangerineText)
        let rest = Text("Drag the edges; they snap to pauses between words.").foregroundStyle(.secondary)
        return Text("\(snapped)\(rest)")
            .font(.caption.weight(.semibold))
            .multilineTextAlignment(.center)
    }

    // MARK: Buttons

    private var buttons: some View {
        HStack(spacing: 12) {
            Button(previewer == nil ? "Preview" : "Stop", systemImage: previewer == nil ? "play.fill" : "stop.fill", action: togglePreview)
                .font(.headline.weight(.heavy))
                .padding(.horizontal, 20)
                .frame(height: 52)
                .background(.white.opacity(0.14), in: .capsule)
                .accessibilityIdentifier("clipPreview")
            Button(action: share) {
                Group {
                    if exporting { ProgressView().tint(.white) } else { Text("Share") }
                }
                .font(.headline.weight(.heavy))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.tangerine, in: .capsule)
            }
            .disabled(exporting)
            .accessibilityIdentifier("clipShare")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .opacity(span == nil ? 0 : 1)
        .disabled(span == nil)
    }

    // MARK: Actions

    private func load() async {
        art = await loadArt()
        guard let url = request.audioURL else {
            phase = .failed(Self.downloadMessage)
            return
        }
        do {
            let span = try await ClipFetcher.span(of: url, window: window)
            clip = window.snappedDefaultClip(to: span.gaps)
            Self.log.debug("Default clip \(clip.lowerBound)-\(clip.upperBound), nearest gaps \(nearestGaps(span.gaps))")
            phase = .ready(span)
        } catch .offline {
            phase = .failed("You're offline. Connect to make a clip of a streamed episode.")
        } catch {
            phase = .failed(Self.downloadMessage)
        }
    }

    private static let downloadMessage = "Download this episode to make a clip"

    /// The gaps nearest each edge, for checking in the log that a clip starts and ends in quiet.
    private func nearestGaps(_ gaps: [TimeInterval]) -> String {
        [clip.lowerBound, clip.upperBound].map { edge in
            gaps.min { abs($0 - edge) < abs($1 - edge) }.map { String(format: "%.2f", $0) } ?? "none"
        }.joined(separator: ", ")
    }

    /// The chapter's picture, else the show's art. Nil draws Cassy on tangerine.
    private func loadArt() async -> UIImage? {
        if let data = request.chapterArt, let image = UIImage(data: data) { return image }
        guard let url = request.show?.artworkURL, let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data: data)
    }

    /// Moves an edge toward the finger, in 0.1 s steps, snapping to a gap within half a second.
    private func drag(_ edge: ClipWindow.Edge, to time: TimeInterval, gaps: [TimeInterval]) {
        stopPreview()
        let stepped = (time * 10).rounded() / 10
        let snapped = ClipWindow.snap(stepped, to: gaps)
        clip = window.dragging(edge, of: clip, to: snapped)
        // At the 5 or 60 s limit the edge stops short of the gap, so it didn't snap.
        let edgeTime = edge == .start ? clip.lowerBound : clip.upperBound
        let gap = snapped != stepped && edgeTime == snapped ? snapped : nil
        if let gap, gap != snap?.gap { Self.log.debug("Snapped the \(edge == .start ? "start" : "end") to the gap at \(gap)") }
        snap = (edge, gap)
    }

    /// VoiceOver's adjust: one second, without snapping.
    private func adjust(_ edge: ClipWindow.Edge, by seconds: TimeInterval) {
        stopPreview()
        let time = (edge == .start ? clip.lowerBound : clip.upperBound) + seconds
        clip = window.dragging(edge, of: clip, to: time)
        snap = nil
    }

    /// Pauses the episode and plays the clip from the fetched audio, at normal speed.
    private func togglePreview() {
        guard previewer == nil else { return stopPreview() }
        guard let audio = span?.audio, let audioPlayer = try? AVAudioPlayer(contentsOf: audio.file) else { return }
        Task { try? await player.pause() }
        audioPlayer.currentTime = clip.lowerBound - audio.start
        audioPlayer.play()
        previewer = audioPlayer
        let length = clip.upperBound - clip.lowerBound
        previewStop = Task {
            try? await Task.sleep(for: .seconds(length))
            if !Task.isCancelled { stopPreview() }
        }
    }

    private func stopPreview() {
        previewStop?.cancel()
        previewer?.stop()
        previewer = nil
    }

    private func share() {
        guard let audio = span?.audio else { return }
        stopPreview()
        exporting = true
        let renderer = ImageRenderer(content: ClipFrame(art: art, side: CGFloat(ClipVideo.side)))
        renderer.scale = 1
        let caption = ShareText.episode(request.episode, show: request.show)
        Task {
            defer { exporting = false }
            guard let frame = renderer.cgImage else { return }
            do {
                let video = try await ClipVideo.make(clip, of: audio, frame: frame)
                sharing = ClipShare(video: video, text: caption.text, link: caption.url, frame: UIImage(cgImage: frame))
            } catch {
                Self.log.error("Clip video failed: \(error)")
            }
        }
    }

    private func cleanUp() {
        stopPreview()
        if let audio = span?.audio, audio.isTemporary { try? FileManager.default.removeItem(at: audio.file) }
    }
}

/// A clip video on its way to the share sheet.
private struct ClipShare: Identifiable {
    let video: URL
    let text: String
    let link: URL
    let frame: UIImage
    var id: URL { video }
}

/// Gives the share sheet a header with the episode's text and the clip's frame, instead of "1 Link and 1 Document".
private final class ClipItem: NSObject, UIActivityItemSource {
    let share: ClipShare

    init(_ share: ClipShare) {
        self.share = share
    }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any { share.video }

    func activityViewController(_ controller: UIActivityViewController, itemForActivityType type: UIActivity.ActivityType?) -> Any? {
        share.video
    }

    func activityViewControllerLinkMetadata(_ controller: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = share.text
        metadata.imageProvider = NSItemProvider(object: share.frame)
        return metadata
    }
}

/// The bars, the tangerine frame around the clip with a handle on each edge, and a white line at now.
private struct ClipBars: View {
    let window: ClipWindow
    let bars: [Float]
    let clip: ClosedRange<TimeInterval>
    let now: TimeInterval
    let drag: (ClipWindow.Edge, TimeInterval) -> Void
    let adjust: (ClipWindow.Edge, TimeInterval) -> Void

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width, height = geometry.size.height
            let span = window.span
            let x = { (time: TimeInterval) in CGFloat((time - span.lowerBound) / (span.upperBound - span.lowerBound)) * width }
            let time = { (x: CGFloat) in span.lowerBound + Double(x / width) * (span.upperBound - span.lowerBound) }
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    let step = size.width / CGFloat(bars.count)
                    for (index, bar) in bars.enumerated() {
                        let barHeight = max(3, CGFloat(bar) * (size.height - 12))
                        let rect = CGRect(x: CGFloat(index) * step + step * 0.2, y: (size.height - barHeight) / 2,
                                          width: step * 0.6, height: barHeight)
                        let middle = time(rect.midX)
                        let color: Color = clip.contains(middle) ? .white.opacity(0.85) : .white.opacity(0.35)
                        context.fill(Path(roundedRect: rect, cornerRadius: step * 0.3), with: .color(color))
                    }
                }
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.tangerine.opacity(0.12))
                    .strokeBorder(Color.tangerine, lineWidth: 3)
                    .frame(width: x(clip.upperBound) - x(clip.lowerBound), height: height)
                    .offset(x: x(clip.lowerBound))
                    .allowsHitTesting(false)
                Rectangle().fill(.white)
                    .frame(width: 2, height: height + 12)
                    .offset(x: x(now) - 1, y: -6)
                    .allowsHitTesting(false)
                handle(.start, at: x(clip.lowerBound), height: height, time: time)
                handle(.end, at: x(clip.upperBound), height: height, time: time)
            }
        }
        .coordinateSpace(.named("bars"))
    }

    /// A tangerine grip on the frame's edge, with a wide touch area, that VoiceOver adjusts a second at a time.
    private func handle(_ edge: ClipWindow.Edge, at x: CGFloat, height: CGFloat, time: @escaping (CGFloat) -> TimeInterval) -> some View {
        let edgeTime = edge == .start ? clip.lowerBound : clip.upperBound
        return Capsule().fill(Color.tangerine)
            .frame(width: 8, height: 32)
            .frame(width: 44, height: height)
            .contentShape(.rect)
            .offset(x: x - 22)
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("bars")).onChanged { value in
                drag(edge, time(value.location.x))
            })
            .accessibilityElement()
            .accessibilityLabel(edge == .start ? "Clip start" : "Clip end")
            .accessibilityValue("\(edge == .start ? "Starts" : "Ends") at \(edgeTime.rounded().clock)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: adjust(edge, 1)
                case .decrement: adjust(edge, -1)
                @unknown default: break
                }
            }
            .accessibilityIdentifier(edge == .start ? "clipStart" : "clipEnd")
    }
}

/// The clip video's picture, and the editor's preview of it: the art, with the badge in the top left corner.
/// Laid out for 1080 px and scaled to `side`.
struct ClipFrame: View {
    let art: UIImage?
    let side: CGFloat

    var body: some View {
        let scale = side / CGFloat(ClipVideo.side)
        Group {
            if let art {
                Image(uiImage: art).resizable().interpolation(.high).scaledToFill()
            } else {
                Color.tangerine.overlay { CassyView(job: .idle, size: side * 0.6) }
            }
        }
        .frame(width: side, height: side)
        .clipped()
        .overlay(alignment: .topLeading) {
            ClipBadge(scale: scale).padding(40 * scale)
        }
    }
}

/// The app icon and "Clipped with Casterr" on a nearly opaque dark capsule, about a quarter of the
/// picture's width. Sizes are in 1080 px units, times `scale`.
private struct ClipBadge: View {
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 14 * scale) {
            Image("BadgeIcon")
                .resizable()
                .frame(width: 64 * scale, height: 64 * scale)
                .clipShape(.rect(cornerRadius: 15 * scale))
            Text("Clipped with\nCasterr")
                .font(.system(size: 25 * scale, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize()
        }
        .padding(.leading, 10 * scale)
        .padding(.trailing, 26 * scale)
        .padding(.vertical, 10 * scale)
        .background(.black.opacity(0.85), in: .capsule)
    }
}

/// The system share sheet. `completion` runs when it closes, shared or not.
private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    let completion: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // Sharing a clip back into Casterr would only import it as a shared file.
        controller.excludedActivityTypes = [UIActivity.ActivityType("sh.oribi.Casterr.Share")]
        controller.completionWithItemsHandler = { _, _, _, _ in completion() }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

extension TimeInterval {
    /// 12:04.4 or 1:02:03.4.
    var clockTenths: String {
        let tenths = Int((max(self, 0) * 10).rounded())
        return TimeInterval(tenths / 10).clock + ".\(tenths % 10)"
    }
}
