import CasterrCore
import SwiftUI

struct NowPlayingView: View {
    @Environment(Player.self) private var player
    /// Closes Now Playing and opens the show page.
    let openShow: (ShowKey) -> Void
    @State private var scrubbing: TimeInterval?
    @State private var choosingSpeed = false
    @State private var tint = Color(white: 0.18)

    var body: some View {
        VStack(spacing: 24) {
            ArtworkView(url: player.show?.artworkURL, title: player.show?.title ?? "", size: 280)
                .shadow(color: .black.opacity(0.35), radius: 18, y: 12)

            VStack(spacing: 4) {
                Text(player.episode?.title ?? "").font(.headline.weight(.heavy)).multilineTextAlignment(.center)
                Button(player.show?.title ?? "") {
                    if let show = player.show?.key { openShow(show) }
                }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("nowPlayingShow")
                    .accessibilityHint("Opens the show page")
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
                    Text(player.speed.title).roundControl()
                }
                .accessibilityIdentifier("speed")
                Spacer()
                BookmarkButton().roundControl()
                Spacer()
                SleepTimerMenu()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [tint, tint.mix(with: .black, by: 0.45)], startPoint: .top, endPoint: .bottom))
        .tint(.white)
        .environment(\.colorScheme, .dark)
        .task(id: player.show?.artworkURL) { await loadTint() }
        .bookmarkToast()
        .cassyToast()
        .sheet(isPresented: $choosingSpeed) { SpeedSheet() }
    }

    /// The background comes from the artwork's average color, darkened for white text.
    private func loadTint() async {
        guard let url = player.show?.artworkURL,
              let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data)?.cgImage else { return }
        let rgb = ArtworkTint.color(of: image)
        withAnimation { tint = Color(red: rgb.red, green: rgb.green, blue: rgb.blue) }
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

/// Off: a moon. On: the time left, or "End" for the end of the episode, on a white button.
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
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz")
                if let end = player.sleepTimerEndsAt {
                    Text(timerInterval: Date.now...end, countsDown: true).monospacedDigit()
                } else if player.sleepTimer == .endOfEpisode {
                    Text("End")
                }
            }
            .roundControl(on: player.sleepTimer != nil)
        }
        .accessibilityLabel("Sleep timer")
        .accessibilityValue(timerValue)
    }

    private var timerValue: String {
        if let end = player.sleepTimerEndsAt { return "Pauses at \(end.formatted(date: .omitted, time: .shortened))" }
        return player.sleepTimer == .endOfEpisode ? "Pauses at the end of the episode" : "Off"
    }
}

/// Sets this show's speed. "Use my default" follows the default speed from Settings.
private struct SpeedSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    /// Nil follows the default.
    @State private var override: PlaybackSpeed?
    @State private var global = PlaybackSpeed.normal

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Speed for this show").font(.headline)
                Spacer()
                Text((override ?? global).title)
            }
            Toggle(isOn: Binding(get: { override == nil }, set: { follow in
                // Turning the default off starts this show at the default, so it can stay there on purpose.
                save(follow ? nil : global)
            })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use my default")
                    Text("\(global.title), from Settings").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(.white.opacity(0.08), in: .rect(cornerRadius: 14))
            if let override {
                Slider(value: Binding(get: { override.value }, set: { save(PlaybackSpeed($0)) }), in: 1.0...2.0, step: 0.1) {
                    Text("Speed")
                } minimumValueLabel: {
                    Text("1.0×")
                } maximumValueLabel: {
                    Text("2.0×")
                }
                .accessibilityIdentifier("speedSlider")
                Text("\(player.show?.title ?? "This show") plays at \(override.title). Your other shows keep your default.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding()
        .presentationDetents([.height(override == nil ? 150 : 270)])
        .task { await load() }
    }

    private func load() async {
        global = (try? await model.library.globalSpeed()) ?? .normal
        if let show = player.episode?.showKey {
            override = try? await model.library.speedOverride(show)
        }
    }

    /// Applies right away, so there's no Done button.
    private func save(_ speed: PlaybackSpeed?) {
        guard speed != override, let show = player.episode?.showKey else { return }
        override = speed
        let library = model.library
        Task {
            await model.change {
                try await library.setSpeedOverride(show, to: speed)
                try await player.reloadSpeed()
            }
        }
    }
}

extension PlaybackSpeed {
    /// "1.3×"
    var title: String { "\(value.formatted(.number.precision(.fractionLength(1))))×" }
}

private extension View {
    /// The round buttons under the play controls. White when the control is on.
    func roundControl(on: Bool = false) -> some View {
        font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .frame(minWidth: 52, minHeight: 44)
            .foregroundStyle(on ? Color.black : .white)
            .background(on ? Color.white : .white.opacity(0.14), in: .capsule)
            .contentShape(.capsule)
    }
}
