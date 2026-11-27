import SwiftUI

/// A share link that sends a message with its link, previewed with the show's art once it has loaded.
struct ArtShareLink<Label: View>: View {
    let share: (text: String, url: URL)
    let art: UIImage?
    @ViewBuilder let label: () -> Label

    var body: some View {
        if let art {
            ShareLink(
                item: share.url, message: Text(share.text),
                preview: SharePreview(share.text, image: Image(uiImage: art)), label: label)
        } else {
            ShareLink(item: share.url, message: Text(share.text), preview: SharePreview(share.text), label: label)
        }
    }
}
