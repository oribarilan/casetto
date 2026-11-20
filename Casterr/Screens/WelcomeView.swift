import SwiftUI

/// The one intro screen, on first launch: Cassy and the three steps of using Casterr.
/// Everything else is taught with just-in-time tips.
struct WelcomeView: View {
    let start: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    CassyView(job: .idle, size: 150)
                        .accessibilityHidden(true)
                        .padding(.top, 40)
                    Text("Hi, I'm Cassy!")
                        .font(.largeTitle.weight(.black))
                        .padding(.top, 12)
                    Text("I keep your podcasts in order, so you just press play.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: 20) {
                        step(1, "Follow shows", "Their new episodes land in your Inbox.")
                        step(2, "Queue the episodes you want", "The rest leave on their own after 14 days.")
                        step(3, "Press play", "Your Queue plays top to bottom.")
                    }
                    .padding(.top, 28)
                }
                .padding(.horizontal, 28)
            }
            Button(action: start) {
                Text("Let's add some shows")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .padding(.horizontal, 28)
            .padding(.bottom, 16)
        }
    }

    private func step(_ number: Int, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.title2.weight(.black))
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(Color.tangerine.opacity(0.12), in: .rect(cornerRadius: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
