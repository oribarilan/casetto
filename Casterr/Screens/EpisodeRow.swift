import CasterrCore
import SwiftUI

/// An episode in a list. Tapping plays it. An automatic move shows its reason and, while allowed, Undo.
struct EpisodeRow: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    let episode: EpisodeInfo
    let identifier: String
    var caption: String?
    var move: LastMove?
    var downloaded = false
    var art: ShowArt?
    /// A symbol shown before the caption, like the waveform on the playing episode.
    var captionSymbol: String?
    var animateSymbol = false
    /// A short note at the end of the details line, like "leaves in 2 days".
    var metaNote: String?

    var body: some View {
        HStack {
            Button {
                Task { await model.change { try await player.play(episode.key) } }
            } label: {
                HStack(spacing: 12) {
                    ArtworkView(url: art?.artworkURL, title: art?.title ?? episode.title, size: 52)
                    details
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(identifier)
            if move?.canUndo == true {
                Button("Undo") {
                    Task { await model.change { try await model.library.undo(episode.key) } }
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            let captions = [caption, move?.reason.label].compactMap(\.self)
            if !captions.isEmpty {
                HStack(spacing: 4) {
                    if let captionSymbol {
                        Image(systemName: captionSymbol)
                            .symbolEffect(.variableColor.iterative, isActive: animateSymbol)
                            .accessibilityHidden(true)
                    }
                    Text(captions.joined(separator: " · "))
                }
                .font(.caption.bold())
                .foregroundStyle(.tint)
            }
            Text(episode.title).lineLimit(2)
            HStack {
                if let date = episode.publishDate { Text(date, format: .dateTime.day().month().year()) }
                if let duration = episode.duration { Text(duration.clock) }
                if downloaded {
                    Image(systemName: "arrow.down.circle.fill").accessibilityLabel("Downloaded")
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
