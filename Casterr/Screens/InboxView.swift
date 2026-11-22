import CasterrCore
import SwiftUI

/// New episodes waiting for a decision, newest first.
struct InboxView: View {
    @Environment(AppModel.self) private var model
    @State private var items: [EpisodeInfo] = []
    @State private var cards: [(card: RuleCard, title: String)] = []
    @State private var moves: [EpisodeKey: LastMove] = [:]
    @State private var art: [ShowKey: ShowArt] = [:]
    @State private var expiry: InboxExpiry = .standard
    @State private var daysLeft: [EpisodeKey: Int] = [:]
    /// The one-time tip that teaches the swipes, on the first row.
    @State private var tip: CassyTip?
    @State private var loaded = false

    var body: some View {
        List {
            if !cards.isEmpty {
                Section("Suggestions") {
                    ForEach(cards, id: \.card.show) { RuleCardRow(card: $0.card, title: $0.title) }
                }
            }
            Section {
                episodeRows
            } footer: {
                if !items.isEmpty { expiryLine }
            }
        }
        .overlay {
            if loaded && items.isEmpty && cards.isEmpty {
                CassyEmptyState(job: .success, title: "Inbox zero!", message: "Everything's sorted. Go stretch your legs.") {}
            }
        }
        .cassyTips($tip)
        .keepsRowSwipes()
        .navigationTitle("Inbox")
        .refreshable { await model.refresh() }
        .task(id: model.revision) { await load() }
    }

    /// Says how long episodes wait here; the days open Settings at the Inbox section.
    private var expiryLine: some View {
        Button { model.queuePath.append(.settings(.inbox)) } label: {
            switch expiry {
            case .never:
                Text("Unplayed episodes stay in your Inbox until you remove them. \(Text("Change ›").foregroundStyle(Color.tangerineText))")
            case .days:
                Text("Unplayed episodes are removed after \(Text("\(expiry.title) ›").foregroundStyle(Color.tangerineText))")
            }
        }
        .buttonStyle(.plain)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("inboxExpiryLine")
    }

    /// Quiet until the last 3 days, then "removed in 2 days".
    private func countdown(_ days: Int?) -> String? {
        guard let days, days <= 3 else { return nil }
        switch days {
        case ...0: return "removed soon"
        case 1: return "removed tomorrow"
        default: return "removed in \(days) days"
        }
    }

    private var episodeRows: some View {
        ForEach(items, id: \.key) { episode in
            EpisodeRow(episode: episode, identifier: "inboxItem", move: moves[episode.key], art: art[episode.showKey],
                       metaNote: countdown(daysLeft[episode.key]))
                .cassyTipTarget("inboxRow.\(episode.key.rawValue)")
                .swipeActions(edge: .leading) {
                    Button("Add to Queue", systemImage: "text.badge.plus") {
                        Task { await model.change { try await model.library.addToQueue(episode.key) } }
                    }
                    .tint(.accentColor)
                }
                .swipeActions(edge: .trailing) {
                    Button("Remove", systemImage: "minus.circle", role: .destructive) {
                        Task { await model.change { try await model.library.dismiss(episode.key) } }
                    }
                }
        }
    }

    private func load() async {
        let keys = (try? await model.library.inbox()) ?? []
        items = await model.episodes(keys)
        moves = await model.moves(of: keys)
        art = (try? await model.library.showArt()) ?? [:]
        expiry = (try? await model.library.globalExpiry()) ?? .standard
        daysLeft = (try? await model.library.inboxDaysLeft()) ?? [:]
        if tip == nil, let first = items.first {
            tip = CassyTip.once("inboxSwipe", target: "inboxRow.\(first.key.rawValue)",
                                text: "Swipe right to queue an episode, or left to remove it.")
        }
        var loadedCards: [(card: RuleCard, title: String)] = []
        for card in (try? await model.library.ruleCards()) ?? [] {
            loadedCards.append((card, (try? await model.library.show(card.show))?.title ?? "This show"))
        }
        cards = loadedCards
        loaded = true
    }
}

/// A suggestion to change a show's level. Nothing changes without a tap. One button accepts;
/// the corner ✕ or a swipe left dismisses for 30 days; "…" holds Never ask and, for an ignored show, Unsubscribe.
private struct RuleCardRow: View {
    @Environment(AppModel.self) private var model
    let card: RuleCard
    let title: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            CassyView(job: .idle, size: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    question.font(.subheadline.weight(.heavy))
                    Text(reason).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.trailing, 24)
                HStack {
                    Button(card.kind == .autoQueue ? "Queue them" : "Skip them") { act(accept) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    Spacer()
                    Menu {
                        if card.kind == .ignored {
                            Button("Unfollow", systemImage: "minus.circle", role: .destructive) {
                                act { try await model.feeds.unsubscribe(card.show) }
                            }
                        }
                        Button("Never ask about this show", systemImage: "hand.raised") {
                            act { try await model.library.hideRuleCard(card, forever: true) }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 30, height: 30)
                            .background(.quaternary, in: .circle)
                    }
                    .accessibilityLabel("More options")
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button("Dismiss", systemImage: "xmark") { act(dismiss) }
                .labelStyle(.iconOnly)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(.quaternary, in: .circle)
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button("Dismiss", systemImage: "xmark") { act(dismiss) }
                .tint(.gray)
        }
        .accessibilityIdentifier("ruleCard")
    }

    /// The show name stands out in accent text, darkened or lightened so it stays readable.
    private var question: Text {
        let name = Text(title).foregroundStyle(Color.tangerineText)
        return card.kind == .autoQueue
            ? Text("Queue new \(name) episodes for you?")
            : Text("Skip new \(name) episodes?")
    }

    private var reason: String {
        card.kind == .autoQueue ? "You play it the day it drops." : "Its recent episodes went unplayed."
    }

    private func accept() async throws {
        try await model.library.setLevel(card.show, to: card.kind == .autoQueue ? .autoQueue : .skip)
    }

    private func dismiss() async throws {
        try await model.library.hideRuleCard(card, forever: false)
    }

    private func act(_ work: @escaping () async throws -> Void) {
        Task { await model.change(work) }
    }
}

extension InboxExpiry {
    var title: String {
        switch self {
        case .days(let days): days == 1 ? "1 day" : "\(days) days"
        case .never: "Never"
        }
    }
}

extension TriageLevel {
    var title: String {
        switch self {
        case .inbox: "Inbox"
        case .autoQueue: "Add to Queue"
        case .playNext: "Play Next"
        case .skip: "Skip"
        }
    }
}

/// An empty state with Cassy above a heavy title, a line of copy, and optional actions.
struct CassyEmptyState<Actions: View>: View {
    let job: CassyJob
    let title: String
    let message: String
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(spacing: 10) {
            CassyView(job: job, size: 150)
            Text(title)
                .font(.title2.weight(.black))
                .multilineTextAlignment(.center)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            actions().padding(.top, 6)
        }
        .padding(.horizontal, 32)
    }
}
