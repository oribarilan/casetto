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
    /// Confirms a new bookmark for 4 seconds and offers Add Note in place.
    func bookmarkToast() -> some View {
        overlay(alignment: .top) { BookmarkToast() }
    }
}

private struct BookmarkToast: View {
    @Environment(AppModel.self) private var model
    @State private var editing = false
    @State private var note = ""

    var body: some View {
        if let bookmark = model.lastBookmark {
            HStack {
                if editing {
                    TextField("Note", text: $note)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit { save(bookmark) }
                        .accessibilityIdentifier("bookmarkNote")
                    Button("Save") { save(bookmark) }
                } else {
                    CassyView(job: .success, size: 36).accessibilityHidden(true)
                    Text("Bookmarked at \(bookmark.position.clock)")
                    Spacer()
                    Button("Add Note") { editing = true }
                }
            }
            .padding()
            .glassEffect(in: .rect(cornerRadius: 16))
            .padding(.horizontal)
            .task(id: bookmark.id) {
                editing = false
                note = ""
                try? await Task.sleep(for: .seconds(4))
                if !editing { model.lastBookmark = nil }
            }
        }
    }

    private func save(_ bookmark: RecentBookmark) {
        let text = note
        model.lastBookmark = nil
        editing = false
        Task { await model.change { try await model.library.setNote(text, for: bookmark.id) } }
    }
}

/// Bookmarks grouped by episode, most recent first, each group in position order.
struct BookmarksView: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    @State private var query = ""
    @State private var groups: [[BookmarkInfo]] = []
    @State private var known: Set<EpisodeKey> = []
    @State private var loaded = false
    @State private var editing: BookmarkInfo?
    @State private var note = ""

    var body: some View {
        List {
            ForEach(groups, id: \.first!.episodeKey) { group in
                Section {
                    ForEach(group, id: \.id) { row($0) }
                } header: {
                    header(group)
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
        .searchable(text: $query, prompt: "Search bookmarks")
        .navigationTitle("Bookmarks")
        .alert("Note", isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })) {
            TextField("Note", text: $note)
            Button("Save") {
                if let id = editing?.id {
                    let text = note
                    Task { await model.change { try await model.library.setNote(text, for: id) } }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .task(id: "\(model.revision)|\(query)") { await load() }
    }

    private func header(_ group: [BookmarkInfo]) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(group[0].episodeTitle).lineLimit(2)
                Text(group[0].showTitle).font(.caption)
            }
            Spacer()
            ShareLink(item: MarkdownExport(bookmarks: group), preview: SharePreview(BookmarkMarkdown.fileName(group))) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .labelStyle(.iconOnly)
        }
    }

    private func row(_ bookmark: BookmarkInfo) -> some View {
        Button {
            Task {
                await model.change { try await player.play(bookmark.episodeKey) }
                player.seek(to: bookmark.position)
            }
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(bookmark.position.clock).monospacedDigit().bold()
                if bookmark.note.isEmpty {
                    Text("No note").foregroundStyle(.secondary)
                } else {
                    Text(bookmark.note)
                }
                Spacer()
                if !known.contains(bookmark.episodeKey) {
                    Text("Not in the feed").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!known.contains(bookmark.episodeKey))
        .accessibilityIdentifier("bookmark")
        .swipeActions(edge: .leading) {
            Button("Edit Note", systemImage: "pencil") {
                note = bookmark.note
                editing = bookmark
            }
        }
        .swipeActions(edge: .trailing) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                Task { await model.change { try await model.library.deleteBookmark(bookmark.id) } }
            }
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
        var found: Set<EpisodeKey> = []
        for key in order where (try? await model.library.episode(key)) != nil { found.insert(key) }
        known = found
        loaded = true
    }
}

/// One episode's bookmarks as a Markdown file, written when shared.
private struct MarkdownExport: Transferable {
    let bookmarks: [BookmarkInfo]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .init(filenameExtension: "md") ?? .plainText) { export in
            Data(BookmarkMarkdown.render(export.bookmarks).utf8)
        }
        .suggestedFileName { BookmarkMarkdown.fileName($0.bookmarks) }
    }
}
