import CasterrCore
import SwiftUI

/// A line from Cassy, with an optional action. One at a time; a new one replaces the old.
struct CassyMessage: Identifiable {
    let id = UUID()
    let job: CassyJob
    let text: String
    var actionTitle: String?
    var action: (@MainActor () async -> Void)?
}

extension View {
    /// Shows `AppModel.cassyToast` at the top for 5 seconds. Tapping it runs its action.
    func cassyToast() -> some View {
        overlay(alignment: .top) { CassyToast() }
    }
}

private struct CassyToast: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let message = model.cassyToast {
            Button {
                model.cassyToast = nil
                if let action = message.action { Task { await action() } }
            } label: {
                HStack(spacing: 10) {
                    CassyView(job: message.job, size: 44)
                        .accessibilityHidden(true)
                    Text(message.text)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let title = message.actionTitle {
                        Text(title).font(.subheadline.weight(.bold)).foregroundStyle(.tint)
                    }
                }
                .padding(12)
                .glassEffect(in: .rect(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .accessibilityIdentifier("cassyToast")
            .task(id: message.id) {
                try? await Task.sleep(for: .seconds(5))
                if model.cassyToast?.id == message.id { model.cassyToast = nil }
            }
        }
    }
}
