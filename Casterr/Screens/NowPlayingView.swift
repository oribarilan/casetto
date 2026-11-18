import CasterrCore
import SwiftUI

struct NowPlayingView: View {
    @Environment(Player.self) private var player
    @State private var scrubbing: TimeInterval?
    @State private var choosingSpeed = false

    var body: some View {
        VStack(spacing: 24) {
            AsyncImage(url: player.show?.artworkURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                RoundedRectangle(cornerRadius: 12).fill(.quaternary)
            }
            .frame(maxWidth: 280, maxHeight: 280)
            .clipShape(.rect(cornerRadius: 12))

            VStack(spacing: 4) {
                Text(player.episode?.title ?? "").font(.headline).multilineTextAlignment(.center)
                Text(player.show?.title ?? "").foregroundStyle(.secondary)
            }

            if let message = player.errorMessage {
                Text(message).foregroundStyle(.red)
            }

            scrubber

            HStack(spacing: 40) {
                Button("Back 15 seconds", systemImage: "gobackward.15") { player.skipBack() }
                Button(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.circle.fill" : "play.circle.fill") {
                    Task { try? await player.togglePlayPause() }
                }
                .font(.system(size: 64))
                Button("Forward 30 seconds", systemImage: "goforward.30") { player.skipForward() }
            }
            .labelStyle(.iconOnly)
            .font(.title)

            HStack {
                Button { choosingSpeed = true } label: {
                    Text("\(player.speed.value, format: .number.precision(.fractionLength(1)))×")
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("speed")
                Spacer()
                SleepTimerMenu()
            }
        }
        .padding()
        .sheet(isPresented: $choosingSpeed) {
            SpeedSheet().presentationDetents([.height(220)])
        }
    }

    private var scrubber: some View {
        let duration = max(player.duration ?? 0, 1)
        let shown = scrubbing ?? player.position
        return VStack {
            Slider(value: Binding(get: { min(shown, duration) }, set: { scrubbing = $0 }), in: 0...duration) { editing in
                if !editing, let target = scrubbing {
                    player.seek(to: target)
                    scrubbing = nil
                }
            }
            HStack {
                Text(shown.clock).accessibilityIdentifier("elapsed")
                Spacer()
                Text("-" + (duration - shown).clock)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }
}

private struct SleepTimerMenu: View {
    @Environment(Player.self) private var player

    var body: some View {
        Menu {
            ForEach([15, 30, 45, 60], id: \.self) { minutes in
                Button("\(minutes) minutes") { player.setSleepTimer(.duration(.seconds(minutes * 60))) }
            }
            Button("End of episode") { player.setSleepTimer(.endOfEpisode) }
            if player.sleepTimer != nil {
                Button("Off", role: .destructive) { player.setSleepTimer(nil) }
            }
        } label: {
            Label(player.sleepTimer == nil ? "Sleep timer" : "Sleep timer on", systemImage: "moon.zzz")
        }
        .buttonStyle(.bordered)
    }
}

/// Sets the speed for this show (an override) or for all shows (the global speed).
private struct SpeedSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    @Environment(\.dismiss) private var dismiss
    @State private var value = 1.0
    @State private var forThisShow = true

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Speed").font(.headline)
                Spacer()
                Text("\(PlaybackSpeed(value).value, format: .number.precision(.fractionLength(1)))×")
            }
            Slider(value: $value, in: 1.0...2.0, step: 0.1)
                .accessibilityIdentifier("speedSlider")
            Picker("Applies to", selection: $forThisShow) {
                Text("This show").tag(true)
                Text("All shows").tag(false)
            }
            .pickerStyle(.segmented)
            Button("Done") { Task { await apply() } }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear { value = player.speed.value }
    }

    private func apply() async {
        let speed = PlaybackSpeed(value)
        guard let show = player.episode?.showKey else { return dismiss() }
        let library = model.library
        await model.change {
            if forThisShow {
                try await library.setSpeedOverride(show, to: speed)
            } else {
                try await library.setGlobalSpeed(speed)
                try await library.setSpeedOverride(show, to: nil)
            }
            try await player.reloadSpeed()
        }
        dismiss()
    }
}
