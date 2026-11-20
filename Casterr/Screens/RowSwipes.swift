import SwiftUI
import UIKit

extension View {
    /// Lets rows that swipe right (like "Add to Queue") keep that gesture on a pushed screen.
    /// iOS also pops a pushed screen when you swipe right anywhere in its content, and that wins
    /// over a row's swipe. This turns off only the content swipe; the edge swipe still goes back.
    func keepsRowSwipes() -> some View {
        background(ContentPopBlocker().frame(width: 0, height: 0))
    }
}

private struct ContentPopBlocker: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) {}

    final class Controller: UIViewController {
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.interactiveContentPopGestureRecognizer?.isEnabled = false
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            navigationController?.interactiveContentPopGestureRecognizer?.isEnabled = true
        }
    }
}
