import CasterrCore
import SwiftUI

/// One button in a row's action line.
struct RowAction: Identifiable {
    let title: String
    let symbol: String
    var destructive = false
    /// Play and Pause: a filled tangerine circle.
    var filled = false
    /// Share Episode: the row builds the message and art itself.
    var isShare = false
    var run: () -> Void = {}
    var id: String { title }

    @MainActor static let share = RowAction(title: "Share", symbol: "square.and.arrow.up", isShare: true)

    /// An action that changes where an episode is, then reloads the screens that show episodes.
    @MainActor
    static func change(_ title: String, _ symbol: String, destructive: Bool = false, _ model: AppModel,
                       _ work: @escaping (Library) async throws -> Void) -> RowAction {
        RowAction(title: title, symbol: symbol, destructive: destructive) {
            Task { await model.change(.episodes) { try await work(model.library) } }
        }
    }

    /// Download, when the episode waits for Wi-Fi and the phone has cellular data.
    @MainActor static func downloadOnCellular(_ episode: EpisodeInfo, _ model: AppModel) -> [RowAction] {
        guard model.canDownloadOnCellular(episode) else { return [] }
        return [RowAction(title: "Download", symbol: "arrow.down.circle") {
            model.downloadOnCellular(episode)
        }]
    }

    @MainActor static func playNext(_ key: EpisodeKey, _ model: AppModel) -> RowAction {
        change("Play Next", "text.line.first.and.arrowtriangle.forward", model) { try await $0.playNextByListener(key) }
    }

    @MainActor static func addToQueue(_ key: EpisodeKey, _ model: AppModel) -> RowAction {
        change("Add to Queue", "text.badge.plus", model) { try await $0.addToQueue(key) }
    }

    @MainActor static func played(_ key: EpisodeKey, _ model: AppModel) -> RowAction {
        change("Played", "checkmark.circle", model) { try await $0.markPlayed(key) }
    }

    @MainActor static func unplayed(_ key: EpisodeKey, _ model: AppModel) -> RowAction {
        change("Unplayed", "circle", model) { try await $0.markUnplayed(key) }
    }

    /// Opens the show's page on the Queue's stack, where the Queue and the Inbox live.
    @MainActor static func show(_ show: ShowKey, _ model: AppModel) -> RowAction {
        RowAction(title: "Show", symbol: "square.stack") { model.queuePath.append(.show(show)) }
    }
}

/// An episode in a list. A tap opens a line of actions under it, with Play (or Pause) first.
/// The line above the title holds the status words: `label` in orange, the rest in gray.
/// An automatic move shows its reason in the status line.
struct EpisodeRow: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    @Environment(\.displayScale) private var scale
    let episode: EpisodeInfo
    let identifier: String
    /// What the first Queue row is doing: Up next, Playing, or Paused. Orange.
    var label: String?
    /// Where the episode is, like "Queued" or "Played". Gray. The row adds the move reason and Downloaded.
    var statuses: [String] = []
    var move: LastMove?
    /// The show is starred: a small gray star starts the status line.
    var starred = false
    /// The download's word at the end of the status line: Downloaded, Downloading 45%, or Waiting for Wi-Fi.
    var download: DownloadState?
    var played = false
    /// Seconds already heard. A started episode shows the minutes left instead of its length.
    var progress: TimeInterval = 0
    var art: ShowArt?
    /// A symbol shown before the label, like the waveform on the playing episode.
    var captionSymbol: String?
    var animateSymbol = false
    /// A short note at the end of the details line, like "removed in 2 days".
    var metaNote: String?
    var isOpen = false
    var toggle: () -> Void = {}
    /// The actions after Play, in order. Those that don't apply are left out by the screen.
    var actions: [RowAction] = []
    /// The Inbox card: a bigger look with the description, swiped sideways by its own drag.
    var card: CardSwipe?

    var body: some View {
        // In a List, each view in this group is its own row. The line is a second row, which the List inserts
        // smoothly; growing one row instead makes the List snap to the new height.
        Group {
            header
                .listRowSeparator(isOpen ? .hidden : .automatic, edges: .bottom)
            if isOpen {
                actionLine
                    .listRowSeparator(.hidden, edges: .top)
                    .moveDisabled(true)
            }
        }
    }

    // The row's outer view stays the same for a plain row and the card: an `if` around the whole row made
    // the show page's List scroll to keep "Show older episodes" in view when it added rows above it.
    private var header: some View {
        Button {
            animate(toggle)
        } label: {
            if let card {
                cardFace.modifier(CardDrag(swipe: card))
                    // A turned card behind, when more episodes wait, so the card looks like the top of a pile.
                    // It sits outside the drag, so it stays put while the top card moves.
                    .background {
                        if card.more {
                            RoundedRectangle(cornerRadius: 24)
                                // In dark mode the shadow doesn't show on black, so the card behind is a lighter grey.
                                .fill(Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
                                    ? .systemGray5 : .secondarySystemGroupedBackground }))
                                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
                                .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
                                .scaleEffect(0.97)
                                .rotationEffect(.degrees(4))
                                .offset(y: 8)
                                .accessibilityHidden(true)
                        }
                    }
            } else {
                HStack(spacing: 12) {
                    ArtworkView(url: art?.artworkURL, title: art?.title ?? episode.title, size: 52)
                    details
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityHint(isOpen ? "Hides actions" : "Shows actions")
        .accessibilityActions {
            if let card {
                Button("Add to Queue", action: card.queue)
                Button("Remove", action: card.remove)
            }
        }
    }

    private var cardFace: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                ArtworkView(url: art?.artworkURL, title: art?.title ?? episode.title, size: 88)
                VStack(alignment: .leading, spacing: 4) {
                    if let show = art?.title {
                        Text(show)
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Color.tangerineText)
                            .lineLimit(1)
                    }
                    details
                }
            }
            if let summary = episode.plainSummary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 3)
        .contentShape(.rect(cornerRadius: 24))
    }

    private func animate(_ change: () -> Void) {
        withAnimation(.smooth(duration: 0.35), change)
    }

    private var isLoaded: Bool { player.episode?.key == episode.key }

    private var playAction: RowAction {
        let pausing = isLoaded && player.isPlaying
        return RowAction(title: pausing ? "Pause" : "Play", symbol: pausing ? "pause.fill" : "play.fill", filled: true) {
            Task {
                await model.change(.episodes) {
                    if isLoaded { try await player.togglePlayPause() } else { try await player.play(episode.key) }
                }
            }
        }
    }

    private var actionLine: some View {
        HStack(alignment: .top, spacing: 0) {
            let all = [playAction] + actions.filter { !($0.isShare && episode.showKey == .shared) }
            ForEach(Array(all.enumerated()), id: \.element.id) { index, action in
                Group {
                    actionButton(action)
                }
                .modifier(PopIn(delay: Double(index) * 0.035))
            }
        }
    }

    @ViewBuilder private func actionButton(_ action: RowAction) -> some View {
                if action.isShare {
                    ArtShareLink(share: ShareText.episode(episode, showTitle: art?.title, feedURL: art?.feedURL),
                                 art: art?.artworkURL.flatMap { ArtCache.kept($0, pixels: 52 * scale) }) { actionLabel(action) }
                        .buttonStyle(.borderless)
                } else {
                    Button {
                        animate(toggle)
                        action.run()
                    } label: {
                        actionLabel(action)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityIdentifier(action.filled ? "rowPlay" : action.title)
                }
    }

    private func actionLabel(_ action: RowAction) -> some View {
        let filled = action.filled
        let tint: Color = action.destructive ? .red : .tangerine
        return VStack(spacing: 4) {
            Image(systemName: action.symbol)
                .font(.body.weight(.semibold))
                .frame(width: 42, height: 42)
                .foregroundStyle(filled ? Color.onTangerine : tint)
                .background(filled ? Color.tangerine : Color(.tertiarySystemFill), in: .circle)
            Text(action.title)
                .font(.caption2)
                .foregroundStyle(action.destructive ? Color.red : Color.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(action.title)
    }

    /// "Up next" in orange, then the gray words, joined by " · ".
    private var statusText: Text? {
        let gray = statuses + [move?.reason.label, download?.label].compactMap(\.self)
        let words = (label.map { [Text($0).foregroundStyle(.tint)] } ?? []) + gray.map { Text($0).foregroundStyle(.secondary) }
        guard let first = words.first else { return nil }
        return words.dropFirst().reduce(first) { Text("\($0)\(Text(" · ").foregroundStyle(.secondary))\($1)") }
    }

    private var minutesLeft: Int? {
        guard progress > 0, !played, let duration = episode.duration, duration > progress else { return nil }
        return Int(((duration - progress) / 60).rounded(.up))
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            if starred || statusText != nil {
                HStack(spacing: 4) {
                    if starred {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Starred")
                    }
                    if let captionSymbol {
                        Image(systemName: captionSymbol)
                            .foregroundStyle(.tint)
                            .symbolEffect(.variableColor.iterative, isActive: animateSymbol)
                            .accessibilityHidden(true)
                    }
                    statusText
                }
                .font(.caption.bold())
            }
            Text(episode.title)
                .font(card == nil ? .body : .headline)
                .lineLimit(2)
                .foregroundStyle(played ? .secondary : .primary)
            HStack {
                if let date = episode.publishDate { Text(date, format: .dateTime.day().month().year()) }
                if let minutesLeft {
                    Text("\(minutesLeft) min left")
                } else if let duration = episode.duration {
                    Text(duration.clock)
                }
                if let metaNote {
                    Text(metaNote).foregroundStyle(Color.tangerineText)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// Springs a button in a moment after the one before it, so the line opens like a fan.
private struct PopIn: ViewModifier {
    let delay: Double
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let still = reduceMotion || shown
        content
            .scaleEffect(still ? 1 : 0.4)
            .opacity(still ? 1 : 0)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.spring(response: 0.38, dampingFraction: 0.6).delay(delay)) { shown = true }
            }
    }
}
