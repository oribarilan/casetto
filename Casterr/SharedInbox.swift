import AVFoundation
import CasterrCore
import os
import SwiftUI

/// Picks up what was shared to Casterr: when the app becomes active, and right away when the
/// share extension signals. Files move into `SharedStore`; links are queued through `FeedService`.
@MainActor
final class SharedInbox {
    private let model: AppModel
    private let store: SharedStore?
    private var picking = false
    private static let log = Logger(subsystem: "sh.oribi.Casterr", category: "sharing")

    init(model: AppModel, store: SharedStore?) {
        self.model = model
        self.store = store
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                let inbox = Unmanaged<SharedInbox>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in await inbox.pickUp() }
            },
            SharedDrop.notification as CFString, nil, .deliverImmediately)
    }

    func pickUp() async {
        guard !picking, let drop = SharedDrop.standard(), let store else { return }
        picking = true
        defer { picking = false }
        await dropUITestFixture(into: drop)
        let items = drop.pending()
        guard !items.isEmpty else { return }
        await drawCassyArt(store)
        for (folder, note) in items {
            switch note.kind {
            case .file: await importFile(note, from: folder, into: store)
            case .link: await queue(note)
            }
            drop.remove(folder)
        }
        try? await model.library.setSharedShowArtwork(store.cassyArt)
    }

    private func importFile(_ note: SharedNote, from folder: URL, into store: SharedStore) async {
        guard let name = note.fileName else { return }
        let source = folder.appending(path: name)
        let id = UUID().uuidString
        let address = SharedStore.audioURL(id: id, fileExtension: source.pathExtension)
        do {
            try store.save(source, as: address)
        } catch {
            Self.log.error("Couldn't keep the shared file: \(error.localizedDescription)")
            return
        }
        let duration = (try? await AVURLAsset(url: store.file(for: address) ?? source).load(.duration).seconds)
            .flatMap { $0.isFinite ? $0 : nil }
        let library = model.library
        await model.change([.feeds, .episodes]) {
            try await library.addSharedEpisode(id: id, title: note.title, duration: duration, audioURL: address)
        }
    }

    private func queue(_ note: SharedNote) async {
        guard let episode = note.episode else { return }
        let feeds = model.feeds
        let message = await model.change([.feeds, .episodes]) {
            if try await feeds.playNext(episode) == nil {
                Self.log.error("The shared episode \(episode.title) isn't in its feed")
            }
        }
        if let message { Self.log.error("Couldn't queue the shared episode: \(message)") }
    }

    /// The Shared with Casterr show's art: Cassy on tangerine, drawn once.
    private func drawCassyArt(_ store: SharedStore) async {
        guard !FileManager.default.fileExists(atPath: store.cassyArt.path(percentEncoded: false)) else { return }
        let renderer = ImageRenderer(content: CassyView(job: .success, size: 420)
            .frame(width: 600, height: 600)
            .background(Color.tangerine))
        renderer.scale = 1
        try? renderer.uiImage?.pngData()?.write(to: store.cassyArt)
    }

    /// UI tests: `SHARED_FIXTURE` names an audio file, and `SHARED_LINK` an Apple Podcasts link,
    /// to drop as if they had been shared.
    private func dropUITestFixture(into drop: SharedDrop) async {
        let environment = ProcessInfo.processInfo.environment
        guard ProcessInfo.processInfo.arguments.contains("-uiTesting") else { return }
        if let path = environment["SHARED_FIXTURE"] {
            let file = URL(filePath: path)
            try? drop.drop(.file(file.lastPathComponent, title: environment["SHARED_FIXTURE_TITLE"]
                                     ?? file.deletingPathExtension().lastPathComponent), file: file)
            unsetenv("SHARED_FIXTURE")
        }
        if let link = environment["SHARED_LINK"].flatMap(URL.init(string:)).flatMap(ApplePodcastsLink.init),
           let episode = try? await AppleDirectory().episode(for: link) {
            try? drop.drop(.link(episode))
            unsetenv("SHARED_LINK")
        }
    }
}
