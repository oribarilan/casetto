import CasterrCore
import SwiftUI

/// What happens to a show's new episodes: four tiles, and for the Inbox, how long they wait.
/// "Use my default" follows the global period; turning it off gives the show its own value.
struct NewEpisodesSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let showKey: ShowKey
    let level: TriageLevel
    /// Nil follows the global period.
    let override: InboxExpiry?
    let global: InboxExpiry

    private let tiles: [(TriageLevel, String, String, String)] = [
        (.inbox, "tray", "Inbox", "Wait for me to decide"),
        (.autoQueue, "text.badge.plus", "Queue", "Add to the end"),
        (.playNext, "text.line.first.and.arrowtriangle.forward", "Play next", "Right after what's playing"),
        (.skip, "archivebox", "Skip", "Only on this page"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                        ForEach(tiles, id: \.0) { tile($0) }
                    }
                    if level == .inbox {
                        inboxPeriod
                    } else {
                        Text(explanation).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New episodes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func tile(_ tile: (TriageLevel, String, String, String)) -> some View {
        let (value, symbol, title, detail) = tile
        let selected = value == level
        return Button {
            Task { await model.change { try await model.library.setLevel(showKey, to: value) } }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: symbol).font(.title3).foregroundStyle(.tint)
                Text(title).font(.subheadline.weight(.bold))
                Text(detail).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(selected ? Color.tangerine.opacity(0.08) : Color(.secondarySystemGroupedBackground),
                        in: .rect(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? Color.tangerine : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(detail)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var inboxPeriod: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Remove from your Inbox").font(.footnote).foregroundStyle(.secondary)
            Toggle(isOn: Binding(get: { override == nil }, set: { follow in
                // Turning the default off starts this show at the current default, so it can stay there on purpose.
                Task { await model.change { try await model.library.setExpiryOverride(showKey, to: follow ? nil : global) } }
            })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use my default")
                    Text(global.title).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
            if let override {
                Picker("Remove after", selection: Binding(get: { override }, set: { value in
                    Task { await model.change { try await model.library.setExpiryOverride(showKey, to: value) } }
                })) {
                    ForEach(InboxExpiry.choices, id: \.self) { Text($0.shortTitle).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Text(periodSentence(override ?? global) + (override == nil ? "" : " Only for this show."))
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private func periodSentence(_ expiry: InboxExpiry) -> String {
        switch expiry {
        case .never: "New episodes stay in your Inbox until you play or remove them."
        case .days: "If you don't play a new episode within \(expiry.title), it's removed from your Inbox."
        }
    }

    private var explanation: String {
        switch level {
        case .inbox: ""
        case .autoQueue: "New episodes go to the end of your Queue."
        case .playNext: "New episodes go right after what's playing, ahead of everything you queued."
        case .skip: "New episodes don't go to your Inbox or Queue. You'll still find them on this page."
        }
    }
}

extension InboxExpiry {
    /// "1d", "14d", or "Never", for the picker.
    var shortTitle: String {
        switch self {
        case .days(let days): "\(days)d"
        case .never: "Never"
        }
    }
}
