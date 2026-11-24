import CasterrCore
import SwiftUI

/// What changed in each version, newest first, from the bundled changelog.
struct WhatsNewView: View {
    let releases: [Changelog.Release]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(releases, id: \.version) { release in
                Section("Version \(release.version)") {
                    ForEach(release.lines, id: \.self) { Text($0) }
                }
            }
            .navigationTitle("What's New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
