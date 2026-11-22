import CasterrCore
import SwiftUI

/// Saves the current moment without pausing.
struct BookmarkButton: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Button("Bookmark", systemImage: "bookmark") { Task { await model.bookmark() } }
            .labelStyle(.iconOnly)
    }
}

extension View {
    /// Confirms a new bookmark for 4 seconds. Add Note, or a tap on the rest, opens it in the Bookmarks tab.
    func bookmarkToast() -> some View {
        overlay(alignment: .top) { BookmarkToast() }
    }
}

private struct BookmarkToast: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let bookmark = model.lastBookmark {
            HStack {
                Button { open(bookmark, editNote: false) } label: {
                    HStack {
                        CassyView(job: .success, size: 36).accessibilityHidden(true)
                        Text("Bookmarked at \(bookmark.position.clock)")
                        Spacer()
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("bookmarkToast")
                Button("Add Note") { open(bookmark, editNote: true) }
            }
            .padding()
            .glassEffect(in: .rect(cornerRadius: 16))
            .padding(.horizontal)
            .task(id: bookmark.id) {
                try? await Task.sleep(for: .seconds(4))
                if model.lastBookmark == bookmark { model.lastBookmark = nil }
            }
        }
    }

    private func open(_ bookmark: RecentBookmark, editNote: Bool) {
        model.lastBookmark = nil
        model.openingBookmark = OpenBookmark(id: bookmark.id, editNote: editNote)
    }
}

/// Bookmarks grouped by episode, most recent first, each group in position order.
/// The time plays the bookmark; tapping the note edits it in place.
struct BookmarksView: View {
    @Environment(AppModel.self) private var model
    @State private var query = ""
    @State private var searching = false
    @State private var groups: [[BookmarkInfo]] = []
    /// Episodes still in the feed cache, with their show art. A missing episode can't play.
    @State private var known: [EpisodeKey: ShowArt] = [:]
    @State private var loaded = false
    @FocusState private var editing: UUID?

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(groups, id: \.first!.episodeKey) { group in
                    let canPlay = known[group[0].episodeKey] != nil
                    Section {
                        header(group)
                        ForEach(group, id: \.id) { BookmarkRow(bookmark: $0, canPlay: canPlay, editing: $editing).id($0.id) }
                    } footer: {
                        if !canPlay {
                            Text(group[0].episodeKey.rawValue.hasPrefix(ShowKey.shared.rawValue + "|")
                                 ? "This shared file isn't on this iPhone, so it can't play."
                                 : "No longer in the feed, so it can't play.")
                        }
                    }
                }
            }
            .overlay {
                if loaded && groups.isEmpty {
                    if query.isEmpty {
                        CassyEmptyState(job: .asleep, title: "Nothing saved yet",
                                        message: "Tap the bookmark while you listen and I'll keep the moment.") {}
                    } else {
                        ContentUnavailableView.search(text: query)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .searchable(text: $query, isPresented: $searching, prompt: "Search bookmarks")
            .navigationTitle("Bookmarks")
            .toolbar {
                if !groups.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: MarkdownExport(episodes: groups),
                                  preview: SharePreview(BookmarkMarkdown.fileName(episodes: groups))) {
                            Label("Export All", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { editing = nil }
                }
            }
            .task(id: "\(model.revision)|\(query)") { await load() }
            .task(id: model.openingBookmark) { await open(model.openingBookmark, with: proxy) }
        }
    }

    /// Scrolls to the bookmark the toast asked for, and puts the keyboard in its note when asked.
    private func open(_ request: OpenBookmark?, with proxy: ScrollViewProxy) async {
        guard let request else { return }
        searching = false
        query = ""
        // A new bookmark reaches the list a moment later, after the search clears.
        for _ in 0..<20 where !groups.joined().contains(where: { $0.id == request.id }) {
            try? await Task.sleep(for: .milliseconds(100))
        }
        withAnimation { proxy.scrollTo(request.id, anchor: .center) }
        if request.editNote {
            // Let Now Playing finish closing, or the keyboard won't come up.
            try? await Task.sleep(for: .milliseconds(450))
            editing = request.id
        }
        model.openingBookmark = nil
    }

    private func header(_ group: [BookmarkInfo]) -> some View {
        let art = known[group[0].episodeKey]
        return HStack(spacing: 12) {
            ArtworkView(url: art?.artworkURL, title: group[0].showTitle, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(group[0].episodeTitle).font(.headline.weight(.semibold)).lineLimit(2)
                Text(group[0].showTitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            ShareLink(item: MarkdownExport(episodes: [group]),
                      preview: SharePreview(BookmarkMarkdown.fileName(group))) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
    }

    private func load() async {
        let bookmarks = (try? await model.library.bookmarks(matching: query)) ?? []
        var order: [EpisodeKey] = []
        var byEpisode: [EpisodeKey: [BookmarkInfo]] = [:]
        for bookmark in bookmarks {
            if byEpisode[bookmark.episodeKey] == nil { order.append(bookmark.episodeKey) }
            byEpisode[bookmark.episodeKey, default: []].append(bookmark)
        }
        groups = order.map { byEpisode[$0]!.sorted { $0.position < $1.position } }
        let art = (try? await model.library.showArt()) ?? [:]
        var found: [EpisodeKey: ShowArt] = [:]
        for key in order {
            if let episode = try? await model.library.episode(key) {
                found[key] = art[episode.showKey] ?? ShowArt(title: "", artworkURL: nil)
            }
        }
        known = found
        loaded = true
    }
}

/// The time plays the bookmark; the note is a text field that saves when editing ends.
private struct BookmarkRow: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    let bookmark: BookmarkInfo
    let canPlay: Bool
    var editing: FocusState<UUID?>.Binding
    @State private var note = ""

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Button(action: play) {
                HStack(spacing: 5) {
                    if canPlay { Image(systemName: "play.fill").font(.caption2) }
                    Text(bookmark.position.clock).monospacedDigit().bold()
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .foregroundStyle(canPlay ? Color.tangerineText : .secondary)
                .background(canPlay ? Color.tangerine.opacity(0.12) : Color(.tertiarySystemFill), in: .capsule)
            }
            .buttonStyle(.borderless)
            .disabled(!canPlay)
            .accessibilityLabel("Play from \(bookmark.position.clock)")
            .accessibilityIdentifier("bookmarkPlay")
            TextField("Note", text: $note, prompt: Text("Add a note").foregroundStyle(Color.tangerineText.opacity(0.75)),
                      axis: .vertical)
                .focused(editing, equals: bookmark.id)
                .submitLabel(.done)
                .accessibilityIdentifier("bookmarkNoteField")
                .onChange(of: note) {
                    // Return ends editing instead of starting a new line.
                    if note.contains("\n") {
                        note = note.replacingOccurrences(of: "\n", with: "")
                        editing.wrappedValue = nil
                    }
                }
        }
        .task(id: bookmark.note) { note = bookmark.note }
        .onChange(of: editing.wrappedValue == bookmark.id) { _, isEditing in
            if !isEditing { save() }
        }
        .swipeActions(edge: .trailing) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                Task { await model.change { try await model.library.deleteBookmark(bookmark.id) } }
            }
        }
    }

    private func play() {
        Task {
            await model.change { try await player.play(bookmark.episodeKey) }
            player.seek(to: bookmark.position)
        }
    }

    private func save() {
        let text = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text != bookmark.note else { return }
        Task { await model.change { try await model.library.setNote(text, for: bookmark.id) } }
    }
}

/// Bookmarks as a Markdown file, written when shared: one episode, or all listed ones.
private struct MarkdownExport: Transferable {
    let episodes: [[BookmarkInfo]]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .init(filenameExtension: "md") ?? .plainText) { export in
            Data(BookmarkMarkdown.render(episodes: export.episodes).utf8)
        }
        .suggestedFileName { BookmarkMarkdown.fileName(episodes: $0.episodes) }
    }
}
