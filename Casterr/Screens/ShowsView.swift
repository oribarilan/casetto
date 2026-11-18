import CasterrCore
import SwiftUI
import UniformTypeIdentifiers

/// The shows you follow, plus adding by URL and importing OPML.
struct ShowsView: View {
    @Environment(AppModel.self) private var model
    @State private var shows: [Row] = []
    @State private var addingFeed = false
    @State private var importingOPML = false
    @State private var importReport: OPMLImportReport?
    @State private var importError: String?

    var body: some View {
        List(shows, id: \.key) { show in
            NavigationLink(value: Route.show(show.key)) {
                VStack(alignment: .leading) {
                    Text(show.title)
                    if let author = show.author {
                        Text(author).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .overlay {
            if shows.isEmpty {
                ContentUnavailableView("No shows yet", systemImage: "square.stack",
                                       description: Text("Add a show by its feed address, or import an OPML file."))
            }
        }
        .navigationTitle("Shows")
        .toolbar {
            Menu("Add", systemImage: "plus") {
                Button("Add by Feed Address", systemImage: "link") { addingFeed = true }
                Button("Import OPML File", systemImage: "square.and.arrow.down") { importingOPML = true }
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
                              author: show?.author))
        }
        shows = loaded.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
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

private struct Row {
    let key: ShowKey
    let title: String
    let author: String?
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
