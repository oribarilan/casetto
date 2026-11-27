import CarPlay
import CasterrCore
import UIKit

/// The car screen: the Queue as the only list, and Now Playing with Bookmark and Speed buttons.
/// Triage stays on the phone.
@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private let queue = CPListTemplate(title: "Queue", sections: [])
    private var watching: Task<Void, Never>?
    private var artwork: [URL: UIImage] = [:]
    private var model: AppModel { .shared }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        // Apple's rule: the car never tells the driver to use the phone.
        queue.emptyViewTitleVariants = ["Your Queue is empty"]
        queue.emptyViewSubtitleVariants = ["Starred shows' new episodes show up here."]
        interfaceController.setRootTemplate(queue, animated: false, completion: nil)
        showNowPlayingButtons(bookmarked: false)
        watching = Task { [weak self] in
            let model = AppModel.shared
            for await _ in Observations({
                (model.revision([.episodes, .feeds, .downloads]), model.player.episode?.key, model.player.isPlaying)
            }) {
                await self?.reloadQueue()
            }
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        watching?.cancel()
        watching = nil
        self.interfaceController = nil
    }

    // MARK: Queue

    private func reloadQueue() async {
        let keys = (try? await model.library.playableQueue()) ?? []
        // Some cars cap list length.
        let episodes = await model.episodes(Array(keys.prefix(CPListTemplate.maximumItemCount)))
        let art = (try? await model.library.showArt()) ?? [:]
        let items = episodes.map { episode in
            let show = art[episode.showKey]
            let item = CPListItem(
                text: episode.title, detailText: show?.title,
                image: show?.artworkURL.flatMap { artwork[$0] })
            item.isPlaying = model.player.isPlaying && model.player.episode?.key == episode.key
            item.handler = { [weak self] _, completion in
                Task {
                    await self?.play(episode.key)
                    completion()
                }
            }
            if let url = show?.artworkURL, artwork[url] == nil {
                Task { await self.loadArtwork(url, into: item) }
            }
            return item
        }
        queue.updateSections([CPListSection(items: items)])
    }

    private func loadArtwork(_ url: URL, into item: CPListItem) async {
        guard let (data, _) = try? await URLSession.shared.data(from: url),
            let image = UIImage(data: data)
        else { return }
        artwork[url] = image
        item.setImage(image)
    }

    private func play(_ key: EpisodeKey) async {
        await model.change(.episodes) { try await model.player.play(key) }
        interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
    }

    // MARK: Now Playing

    private func showNowPlayingButtons(bookmarked: Bool) {
        let symbol = UIImage(systemName: bookmarked ? "bookmark.fill" : "bookmark") ?? UIImage()
        let bookmark = CPNowPlayingImageButton(image: symbol) { [weak self] _ in
            Task { await self?.bookmark() }
        }
        let speed = CPNowPlayingPlaybackRateButton { [weak self] _ in
            Task { await self?.nextSpeed() }
        }
        CPNowPlayingTemplate.shared.updateNowPlayingButtons([speed, bookmark])
    }

    /// Saves the moment without a note, and fills the icon for 2 seconds to confirm.
    private func bookmark() async {
        await model.bookmark()
        showNowPlayingButtons(bookmarked: true)
        try? await Task.sleep(for: .seconds(2))
        showNowPlayingButtons(bookmarked: false)
    }

    /// One step faster, saved as the show's own speed, the same as on the phone.
    private func nextSpeed() async {
        guard let show = model.player.episode?.showKey else { return }
        let speed = model.player.speed.next
        await model.change(.follows) {
            try await model.library.setSpeedOverride(show, to: speed)
            try await model.player.reloadSpeed()
        }
    }
}
