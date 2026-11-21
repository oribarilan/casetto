import AVFoundation
import CasterrCore
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Casterr in other apps' share sheets: takes the first audio file or an Apple Podcasts episode link,
/// drops it where the app picks it up, and shows a short confirmation.
final class ShareViewController: UIViewController {
    private let card = ShareCard.Model()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        let host = UIHostingController(rootView: ShareCard(model: card) { [weak self] in self?.finish() })
        host.view.backgroundColor = .clear
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
        Task { await take() }
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func take() async {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? []).flatMap { $0.attachments ?? [] }
        let outcome: ShareCard.State
        if let audio = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.audio.identifier) }) {
            outcome = await takeFile(audio)
        } else if let link = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            outcome = await takeLink(link)
        } else {
            outcome = .failed(ShareCard.wrongKind)
        }
        card.state = outcome
        guard case .added = outcome else { return }
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(SharedDrop.notification as CFString), nil, nil, true)
        try? await Task.sleep(for: .seconds(1.5))
        finish()
    }

    /// Copies the file while the provider's temporary copy still exists, after checking it plays.
    private func takeFile(_ provider: NSItemProvider) async -> ShareCard.State {
        guard let drop = SharedDrop.standard() else { return .failed(ShareCard.unavailable) }
        let staged: URL? = await withCheckedContinuation { continuation in
            _ = provider.loadFileRepresentation(forTypeIdentifier: UTType.audio.identifier) { url, _ in
                guard let url else { return continuation.resume(returning: nil) }
                let copy = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
                    .appending(path: url.lastPathComponent)
                try? FileManager.default.createDirectory(at: copy.deletingLastPathComponent(), withIntermediateDirectories: true)
                continuation.resume(returning: (try? FileManager.default.copyItem(at: url, to: copy)) != nil ? copy : nil)
            }
        }
        guard let staged else { return .failed(ShareCard.unplayable) }
        defer { try? FileManager.default.removeItem(at: staged.deletingLastPathComponent()) }
        let asset = AVURLAsset(url: staged)
        guard (try? await asset.load(.isPlayable)) == true else { return .failed(ShareCard.unplayable) }
        let tag = try? await AVMetadataItem.metadataItems(
            from: asset.load(.commonMetadata), filteredByIdentifier: .commonIdentifierTitle).first?.load(.stringValue)
        let title = tag.flatMap { $0.isEmpty ? nil : $0 } ?? staged.deletingPathExtension().lastPathComponent
        do {
            try drop.drop(.file(staged.lastPathComponent, title: title), file: staged)
            return .added(title)
        } catch {
            return .failed(ShareCard.unavailable)
        }
    }

    private func takeLink(_ provider: NSItemProvider) async -> ShareCard.State {
        guard let drop = SharedDrop.standard() else { return .failed(ShareCard.unavailable) }
        let url: URL? = await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: URL.self) { url, _ in continuation.resume(returning: url) }
        }
        guard let url, let link = ApplePodcastsLink(url) else { return .failed(ShareCard.wrongKind) }
        do {
            guard let episode = try await AppleDirectory().episode(for: link) else { return .failed(ShareCard.notFound) }
            try drop.drop(.link(episode))
            return .added(episode.title)
        } catch is DirectoryError {
            return .failed(ShareCard.offline)
        } catch {
            return .failed(ShareCard.unavailable)
        }
    }
}

/// The confirmation: Cassy and one line. Accepted items close by themselves; problems wait for Done.
struct ShareCard: View {
    enum State: Equatable {
        case working
        case added(String)
        case failed(String)
    }

    @Observable final class Model {
        var state: State = .working
    }

    static let wrongKind = "Casterr takes audio files and Apple Podcasts episode links."
    static let unplayable = "Casterr can't play this kind of audio file."
    static let notFound = "Casterr couldn't find that episode on Apple Podcasts."
    static let offline = "Casterr couldn't reach Apple Podcasts. Check your connection and share again."
    static let unavailable = "Casterr couldn't save this. Open Casterr once, then share again."

    let model: Model
    let done: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            switch model.state {
            case .working:
                CassyView(job: .idle, size: 90)
                ProgressView()
            case .added(let title):
                CassyView(job: .success, size: 90)
                Text("Up next in your Queue").font(.headline)
                Text(title).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).lineLimit(3)
            case .failed(let message):
                CassyView(job: .error, size: 90)
                Text(message).font(.headline).multilineTextAlignment(.center)
                Button("Done", action: done).buttonStyle(.borderedProminent)
            }
        }
        .accessibilityElement(children: .combine)
        .padding(24)
        .frame(maxWidth: 320)
        .background(.regularMaterial, in: .rect(cornerRadius: 28))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.25))
        .fontDesign(.rounded)
    }
}
