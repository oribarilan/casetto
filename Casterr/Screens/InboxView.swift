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
    @State private var progress: [EpisodeKey: TimeInterval] = [:]
    @State private var starredShows: Set<ShowKey> = []
    /// The row whose action line is open.
    @State private var openRow: EpisodeKey?
    /// The one-time tip that teaches the swipes, on the first row.
    @State private var tip: CassyTip?
    @State private var loaded = false
    /// Episodes swiped off the card, hidden until the save lands so the next one takes the card at once.
    @State private var swiped: Set<EpisodeKey> = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shown: [EpisodeInfo] { items.filter { !swiped.contains($0.key) } }

    var body: some View {
        List {
            if !cards.isEmpty {
                Section("Suggestions") {
                    ForEach(cards, id: \.card.show) { RuleCardRow(card: $0.card, title: $0.title) }
                }
            }
            Section {
                ForEach(shown.prefix(1), id: \.key) { episode in
                    row(episode, card: CardSwipe(queue: { swipeCard(episode, queue: true) },
                                                 remove: { swipeCard(episode, queue: false) }))
                        .listRowBackground(Color.clear)
                        // Room for the card's shadow, which the row would cut off.
                        .listRowInsets(EdgeInsets(top: 14, leading: 0, bottom: 18, trailing: 0))
                        .listRowSeparator(.hidden)
                }
            } footer: {
                if shown.count == 1 { expiryLine }
            }
            if shown.count > 1 {
                Section {
                    ForEach(shown.dropFirst(), id: \.key) { row($0) }
                } header: {
                    Text("Also new · \(shown.count - 1)")
                } footer: {
                    expiryLine
                }
            }
        }
        .overlay {
            if loaded && shown.isEmpty && cards.isEmpty {
                CassyEmptyState(job: .success, title: "Inbox zero!", message: "Everything's sorted. Go stretch your legs.") {}
            }
        }
        .cassyTips($tip)
        .keepsRowSwipes()
        .navigationTitle("Inbox")
        .refreshable { await model.refresh() }
        .reload(on: model.revision([.episodes, .feeds, .follows, .settings])) { await load() }
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

    /// The newest episode on its card, which swipes itself, or a row with the List's swipes.
    @ViewBuilder private func row(_ episode: EpisodeInfo, card: CardSwipe? = nil) -> some View {
        let row = EpisodeRow(episode: episode, identifier: card == nil ? "inboxItem" : "inboxCard", move: moves[episode.key],
                             starred: starredShows.contains(episode.showKey),
                             download: model.downloadState(episode), progress: progress[episode.key] ?? 0,
                             art: art[episode.showKey], metaNote: countdown(daysLeft[episode.key]),
                             isOpen: openRow == episode.key,
                             toggle: { openRow = openRow == episode.key ? nil : episode.key },
                             actions: actions(episode), card: card)
            .cassyTipTarget("inboxRow.\(episode.key.rawValue)")
        if card != nil {
            row
        } else {
            row
                .swipeActions(edge: .leading) {
                    Button("Add to Queue", systemImage: "text.badge.plus") {
                        Task { await model.change(.episodes) { try await model.library.addToQueue(episode.key) } }
                    }
                    .tint(.accentColor)
                }
                .swipeActions(edge: .trailing) {
                    Button("Remove", systemImage: "minus.circle", role: .destructive) {
                        Task { await model.change(.episodes) { try await model.library.dismiss(episode.key) } }
                    }
                }
        }
    }

    /// The card has flown off: the next episode takes it at once, and its row leaves the list.
    private func swipeCard(_ episode: EpisodeInfo, queue: Bool) {
        // Changed from a task, as on the show page: a change made in the gesture inserts the new card without its animation.
        Task {
            withAnimation(reduceMotion ? nil : .snappy) {
                swiped.insert(episode.key)
                if openRow == episode.key { openRow = nil }
            }
            await model.change(.episodes) {
                if queue { try await model.library.addToQueue(episode.key) } else { try await model.library.dismiss(episode.key) }
            }
        }
    }

    /// Play Next, Add to Queue, Share, Show, Remove. No Played: Remove covers "not for me", and the line fits six.
    private func actions(_ episode: EpisodeInfo) -> [RowAction] {
        [.playNext(episode.key, model), .addToQueue(episode.key, model), .share, .show(episode.showKey, model),
         .change("Remove", "minus.circle", destructive: true, model) { try await $0.dismiss(episode.key) }]
    }

    private func load() async {
        let keys = (try? await model.library.inbox()) ?? []
        items = await model.episodes(keys)
        swiped.formIntersection(keys)
        moves = await model.moves(of: keys)
        progress = await model.progress(of: keys)
        starredShows = Set(((try? await model.library.subscriptions()) ?? []).filter(\.starred).map(\.showKey))
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
                        .filledButton()
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
        // A card sets the show's level, hides the card, or unfollows, which removes its Inbox episodes.
        Task { await model.change([.follows, .episodes], work) }
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
