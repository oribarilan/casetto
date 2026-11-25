import SwiftUI

extension View {
    /// Runs `load` when the screen first shows and whenever `id` changes while it's on screen. A screen that comes
    /// back on screen reloads only if `id` changed while it was away. Pass `model.revision(_:)` with the areas the
    /// screen shows, plus anything else it depends on.
    func reload<ID: Equatable & Sendable>(on id: ID, _ load: @escaping () async -> Void) -> some View {
        modifier(Reload(id: id, load: load))
    }
}

private struct Reload<ID: Equatable & Sendable>: ViewModifier {
    let id: ID
    let load: () async -> Void
    /// The id the last finished load was for.
    @State private var loaded: ID?

    func body(content: Content) -> some View {
        content.task(id: id) {
            guard loaded != id else { return }
            await load()
            // A load cut short by leaving the screen runs again on return.
            if !Task.isCancelled { loaded = id }
        }
    }
}
