import CasterrCore
import SwiftUI
import UniformTypeIdentifiers

/// The shows you follow, search, adding by URL, and OPML import and export.
/// When you follow nothing, it shows the top shows instead.
struct ShowsView: View {
    @Environment(AppModel.self) private var model
    @State private var shows: [Row] = []
    @State private var loaded = false
    @State private var query = ""
    @State private var addingFeed = false
    @State private var importingOPML = false
    @State private var importReport: OPMLImportReport?
    @State private var importError: String?

    var body: some View {
        Group {
            if !query.isEmpty || (loaded && shows.isEmpty) {
                // While searching, your matching shows come first, then more from the directory.
                DiscoverView(query: query, followed: query.isEmpty ? [] : shows.filter {
                    ShowSearch.matches(query, title: $0.title, author: $0.author)
                }.map { FollowedShow(key: $0.key, title: $0.title, author: $0.author, artworkURL: $0.artworkURL) })
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: 3), spacing: 16) {
                        ForEach(shows, id: \.key) { show in
                            NavigationLink(value: Route.show(show.key)) { ShowTile(show: show) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .searchable(text: $query, prompt: "Search shows")
        .navigationTitle("Shows")
        .toolbar {
            Menu("Add", systemImage: "plus") {
                Button("Add by Feed Address", systemImage: "link") { addingFeed = true }
                Button("Import OPML File", systemImage: "square.and.arrow.down") { importingOPML = true }
                Divider()
                ShareLink(item: OPMLExport(library: model.library),
                          preview: SharePreview("Casterr Subscriptions")) {
                    Label("Export OPML File", systemImage: "square.and.arrow.up")
                }
            }
        }
        .refreshable { await model.refresh() }
        .sheet(isPresented: $addingFeed) { AddFeedView() }
        .sheet(item: $importReport) { ImportReportView(report: $0) }
        .fileImporter(isPresented: $importingOPML, allowedContentTypes: [.xml, UTType(filenameExtension: "opml") ?? .xml]) { result in
            Task { await importOPML(result) }
        }
        .alert("Import failed", isPresented: .constant(importError != nil), presenting: importError) { _ in
            Button("OK") { importError = nil }
        } message: { Text($0) }
        .task(id: model.revision) { await load() }
    }

    private func load() async {
        let library = model.library
        let subscriptions = (try? await library.subscriptions()) ?? []
        var loaded: [Row] = []
        for subscription in subscriptions {
            let show = try? await library.show(subscription.showKey)
            loaded.append(Row(key: subscription.showKey,
                              title: show?.title ?? subscription.feedURL.absoluteString,
                              author: show?.author, artworkURL: show?.artworkURL,
                              starred: subscription.level == .autoQueue || subscription.level == .playNext,
                              failing: show?.lastRefreshError != nil))
        }
        shows = loaded.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        self.loaded = true
    }

    private func importOPML(_ result: Result<URL, any Error>) async {
        do {
            let url = try result.get()
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            importReport = try await model.feeds.importOPML(data)
        } catch OPMLError.notOPML {
            importError = "That file isn't an OPML file."
        } catch {
            importError = error.localizedDescription
        }
        await model.change {}
    }
}

/// The subscriptions as an OPML file, written when shared.
private struct OPMLExport: Transferable {
    let library: Library

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .xml) { export in
            var feeds: [(title: String, url: URL)] = []
            for subscription in try await export.library.subscriptions() {
                let title = try await export.library.show(subscription.showKey)?.title
                feeds.append((title ?? subscription.feedURL.absoluteString, subscription.feedURL))
            }
            return OPMLWriter.write(feeds)
        }
        .suggestedFileName("Casterr Subscriptions.opml")
    }
}

private struct Row {
    let key: ShowKey
    let title: String
    let author: String?
    let artworkURL: URL?
    /// Auto-queue or Play Next.
    let starred: Bool
    let failing: Bool
}

/// A show in the grid: artwork, title, and badges for starred shows and failing feeds.
private struct ShowTile: View {
    let show: Row

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geometry in
                ArtworkView(url: show.artworkURL, title: show.title, size: geometry.size.width)
                    .overlay(alignment: .topTrailing) {
                        HStack(spacing: 4) {
                            if show.failing { badge("exclamationmark", .yellow, .black) }
                            if show.starred { badge("star.fill", .tangerine, .white) }
                        }
                        .padding(5)
                    }
            }
            .aspectRatio(1, contentMode: .fit)
            Text(show.title)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([show.title, show.author].compactMap(\.self).joined(separator: ", "))
        .accessibilityValue([show.starred ? "Starred" : nil, show.failing ? "Feed not answering" : nil].compactMap(\.self).joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
    }

    private func badge(_ symbol: String, _ fill: Color, _ ink: Color) -> some View {
        Image(systemName: symbol)
            .font(.caption2.weight(.bold))
            .foregroundStyle(ink)
            .frame(width: 22, height: 22)
            .background(fill, in: .circle)
            .shadow(radius: 2)
    }
}

extension OPMLImportReport: @retroactive Identifiable {
    public var id: String { "\(subscribed.count)|\(alreadySubscribed.count)|\(failures.count)" }
}

private struct ImportReportView: View {
    @Environment(\.dismiss) private var dismiss
    let report: OPMLImportReport

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Subscribed", value: "\(report.subscribed.count)")
                    LabeledContent("Already following", value: "\(report.alreadySubscribed.count)")
                }
                if !report.failures.isEmpty {
                    Section("Couldn't add") {
                        ForEach(Array(report.failures.enumerated()), id: \.offset) { _, failure in
                            VStack(alignment: .leading) {
                                Text(failure.title ?? failure.url ?? "Untitled")
                                Text(failure.reason).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Import")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

private struct AddFeedView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var message: String?
    @State private var working = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("https://example.com/feed.xml", text: $address)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("feedAddress")
                if let message {
                    Text(message).foregroundStyle(.red)
                }
            }
            .navigationTitle("Add Show")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Subscribe") { Task { await subscribe() } }
                        .disabled(address.isEmpty || working)
                }
            }
        }
    }

    private func subscribe() async {
        guard let url = URL(string: address.trimmingCharacters(in: .whitespaces)) else {
            message = "That isn't a web address."
            return
        }
        working = true
        defer { working = false }
        do {
            _ = try await model.feeds.subscribe(to: url)
            await model.change {}
            dismiss()
        } catch {
            message = switch error as? SubscribeError {
            case .invalidURL: "That isn't a web address."
            case .notAPodcast: "That address isn't a podcast feed."
            case .unreachable: "Couldn't reach that feed. Check the address and your connection."
            case nil: error.localizedDescription
            }
        }
    }
}
