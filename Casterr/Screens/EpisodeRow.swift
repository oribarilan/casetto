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

    var body: some View {
        HStack {
            Button {
                Task { await model.change { try await player.play(episode.key) } }
            } label: {
                details
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
                Text(captions.joined(separator: " · ")).font(.caption.bold()).foregroundStyle(.tint)
            }
            Text(episode.title).lineLimit(2)
            HStack {
                if let date = episode.publishDate { Text(date, format: .dateTime.day().month().year()) }
                if let duration = episode.duration { Text(duration.clock) }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
