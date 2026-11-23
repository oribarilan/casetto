import CasterrCore
import SwiftUI

struct NowPlayingView: View {
    @Environment(Player.self) private var player
    /// Closes Now Playing and opens the show page.
    let openShow: (ShowKey) -> Void
    @State private var controlSheet: ControlSheetKind?
    @State private var tint = Color(white: 0.18)
    /// The show's art, for the background tint and the share sheet's preview.
    @State private var showArt: UIImage?
    @State private var clipRequest: ClipRequest?

    var body: some View {
        VStack(spacing: 24) {
            artwork
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
                ChapterPill()
                    .padding(.top, 6)
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
                Button { controlSheet = .speed } label: {
                    Text(player.speed.title).roundControl()
                }
                .accessibilityIdentifier("speed")
                Spacer()
                Button { controlSheet = .voiceBoost } label: {
                    Image(systemName: "waveform").roundControl(on: player.voiceBoost)
                }
                .accessibilityIdentifier("voiceBoost")
                .accessibilityLabel("Voice boost")
                .accessibilityValue(player.voiceBoost ? "On" : "Off")
                Spacer()
                BookmarkButton().roundControl()
                Spacer()
                SleepTimerButton { controlSheet = .sleepTimer }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) { shareMenu.padding(.trailing, 18).padding(.top, 8) }
        .background(LinearGradient(colors: [tint, tint.mix(with: .black, by: 0.45)], startPoint: .top, endPoint: .bottom))
        .tint(.white)
        .environment(\.colorScheme, .dark)
        .task(id: player.show?.artworkURL) { await loadTint() }
        .bookmarkToast()
        .cassyToast()
        .sheet(item: $controlSheet) { kind in
            switch kind {
            case .speed: SpeedSheet()
            case .voiceBoost: VoiceBoostSheet()
            case .sleepTimer: SleepTimerSheet()
            }
        }
        .sheet(item: $clipRequest) { ClipEditor(request: $0) }
    }

    /// Share Episode and Share Clip. Files shared to Casterr have no link, so they get neither.
    @ViewBuilder private var shareMenu: some View {
        if let episode = player.episode, episode.showKey != .shared {
            Menu {
                ArtShareLink(share: ShareText.episode(episode, show: player.show), art: showArt) {
                    Text("Share Episode")
                }
                Button("Share Clip") {
                    clipRequest = ClipRequest(
                        window: ClipWindow(position: player.position, duration: player.duration ?? 0),
                        episode: episode, show: player.show, audioURL: player.loadedURL,
                        chapterArt: player.currentChapter?.artwork)
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.14), in: .circle)
            }
            .accessibilityLabel("Share")
            .accessibilityIdentifier("nowPlayingShare")
        }
    }

    /// The playing chapter's picture when the file has one, otherwise the show's art.
    @ViewBuilder private var artwork: some View {
        if let data = player.currentChapter?.artwork, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
                .frame(width: 280, height: 280)
                .clipShape(.rect(cornerRadius: 280 * 0.23))
                .accessibilityHidden(true)
        } else {
            ArtworkView(url: player.show?.artworkURL, title: player.show?.title ?? "", size: 280)
        }
    }

    /// The background comes from the artwork's average color, darkened for white text.
    private func loadTint() async {
        guard let url = player.show?.artworkURL,
              let (data, _) = try? await URLSession.shared.data(from: url),
              let art = UIImage(data: data), let image = art.cgImage else { return }
        showArt = art
        let rgb = ArtworkTint.color(of: image)
        withAnimation { tint = Color(red: rgb.red, green: rgb.green, blue: rgb.blue) }
    }

    private var scrubber: some View {
        let duration = max(player.duration ?? 0, 1)
        let shown = player.position
        return VStack {
            // Seeks as the thumb moves, so a drag that never reports its end still lands where it stopped.
            Slider(value: Binding(get: { min(shown, duration) }, set: { player.seek(to: $0) }), in: 0...duration)
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

/// The playing chapter, filling as it plays. Tapping it lists every chapter.
private struct ChapterPill: View {
    @Environment(Player.self) private var player
    @State private var showingList = false

    var body: some View {
        let progress = player.chapterProgress
        if let index = progress.current {
            let chapter = player.chapters[index]
            Button { showingList = true } label: {
                HStack(spacing: 4) {
                    Text(chapter.title).fontWeight(.semibold).lineLimit(1)
                    Text("· \(index + 1) of \(player.chapters.count)").foregroundStyle(.secondary)
                    Image(systemName: "chevron.right").font(.caption2.weight(.bold))
                }
                .font(.footnote)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    ProgressFill(fraction: progress.fractions[index], color: .white.opacity(0.16))
                        .background(.white.opacity(0.14))
                        .clipShape(.capsule)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Chapter \(index + 1) of \(player.chapters.count), \(chapter.title)")
            .accessibilityHint("Shows all chapters")
            .accessibilityIdentifier("chapterPill")
            .sheet(isPresented: $showingList) { ChapterList() }
        }
    }
}

/// Every chapter as its own progress bar: played ones full and faint, the playing one partway with its time left.
private struct ChapterList: View {
    @Environment(Player.self) private var player
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let progress = player.chapterProgress
        NavigationStack {
            ScrollViewReader { proxy in
                List(Array(player.chapters.enumerated()), id: \.offset) { index, chapter in
                    let isPlaying = index == progress.current
                    let isPlayed = progress.current.map { index < $0 } ?? false
                    Button {
                        player.jump(to: chapter)
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(Color.tangerine)
                                .opacity(isPlaying ? 1 : 0)
                            Text(chapter.start.clock).monospacedDigit().foregroundStyle(.secondary)
                                .frame(width: 64, alignment: .leading)
                            let alignment: HorizontalAlignment = chapter.title.isRightToLeft ? .trailing : .leading
                            VStack(alignment: alignment, spacing: 2) {
                                Text(chapter.title)
                                    .fontWeight(isPlaying ? .semibold : .regular)
                                    .foregroundStyle(isPlayed ? .secondary : .primary)
                                    .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
                                if isPlaying, let minutes = progress.minutesLeft {
                                    Text("\(minutes) min left").font(.caption.weight(.semibold)).foregroundStyle(Color.tangerine)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(ProgressFill(
                        fraction: progress.fractions[index],
                        color: isPlaying ? Color.tangerine.opacity(0.25) : .primary.opacity(0.07)
                    ))
                    .accessibilityLabel("\(chapter.title), starts at \(chapter.start.clock)")
                    .accessibilityValue(isPlaying ? "Playing\(progress.minutesLeft.map { ", \($0) min left" } ?? "")" : isPlayed ? "Played" : "")
                    .id(index)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                // Keep the chapter before the playing one in view, so the list shows where you came from.
                .onAppear { if let current = progress.current, current > 1 { proxy.scrollTo(current - 1, anchor: .top) } }
            }
            .navigationTitle("Chapters")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color(white: 0.11))
        .environment(\.colorScheme, .dark)
    }
}

/// A fill from the left edge, like the scrubber, whatever the text direction.
private struct ProgressFill: View {
    let fraction: Double
    let color: Color

    var body: some View {
        Rectangle().fill(color)
            .scaleEffect(x: fraction, anchor: .leading)
            .environment(\.layoutDirection, .leftToRight)
    }
}

private extension String {
    /// True when the first letter is Hebrew or Arabic, so the title lines up on the right.
    var isRightToLeft: Bool {
        guard let scalar = unicodeScalars.first(where: { CharacterSet.letters.contains($0) }) else { return false }
        return (0x0590...0x08FF).contains(scalar.value) || (0xFB1D...0xFDFF).contains(scalar.value) || (0xFE70...0xFEFF).contains(scalar.value)
    }
}

/// Off: a moon. On: the time left, or "End" for the end of the episode, on a white button.
private enum ControlSheetKind: Identifiable {
    case speed, voiceBoost, sleepTimer
    var id: Self { self }
}

/// The sheet each control under the play button opens: name and value on top, an optional line under them,
/// the control, and an optional "Use my default" switch. All three share one height.
private struct ControlSheet<Control: View>: View {
    let title: String
    let value: Text
    var note: String?
    /// On while the show follows the default from Settings. Nil for a control without a default.
    var followsDefault: Binding<Bool>?
    var defaultValue = ""
    @ViewBuilder let control: Control

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                    Spacer()
                    value.monospacedDigit().foregroundStyle(.secondary)
                }
                .font(.headline)
                if let note { Text(note).font(.footnote).foregroundStyle(.secondary) }
            }
            control
            if let followsDefault {
                Toggle(isOn: followsDefault) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Use my default")
                        Text("\(defaultValue), from Settings").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .tint(.tangerine)
                .accessibilityIdentifier("useMyDefault")
                .padding(12)
                .background(.white.opacity(0.08), in: .rect(cornerRadius: 14))
            }
            Spacer(minLength: 0)
        }
        .padding()
        .padding(.top, 8)
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.visible)
        // Dark like Now Playing behind it, so white text reads on any show's tint.
        .presentationBackground {
            Rectangle().fill(.regularMaterial).environment(\.colorScheme, .dark)
        }
        .environment(\.colorScheme, .dark)
        .tint(.white)
    }
}

/// This show's speed. The slider is always there; moving it gives the show its own speed.
private struct SpeedSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    /// Nil follows the default.
    @State private var override: PlaybackSpeed?
    @State private var global = PlaybackSpeed.normal

    var body: some View {
        let speed = override ?? global
        ControlSheet(title: "Speed", value: Text(speed.title),
                     // Turning the default off keeps the default speed as the show's own.
                     followsDefault: Binding(get: { override == nil }, set: { save($0 ? nil : global) }),
                     defaultValue: global.title) {
            Slider(value: Binding(get: { speed.value }, set: { save(PlaybackSpeed($0)) }), in: 1.0...2.0, step: 0.1) {
                Text("Speed")
            } minimumValueLabel: {
                Text("1.0×").font(.caption)
            } maximumValueLabel: {
                Text("2.0×").font(.caption)
            }
            .accessibilityIdentifier("speedSlider")
        }
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

/// This show's voice boost: On or Off as its own choice, or the default from Settings.
private struct VoiceBoostSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(Player.self) private var player
    /// Nil follows the default.
    @State private var choice: Bool?
    @State private var global = false

    var body: some View {
        let isOn = choice ?? global
        ControlSheet(title: "Voice boost", value: Text(isOn ? "On" : "Off"), note: "Evens out loud and quiet voices.",
                     followsDefault: Binding(get: { choice == nil }, set: { save($0 ? nil : global) }),
                     defaultValue: global ? "On" : "Off") {
            Picker("Voice boost", selection: Binding(get: { isOn }, set: { save($0) })) {
                Text("On").tag(true)
                Text("Off").tag(false)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("voiceBoostPicker")
        }
        .task { await load() }
    }

    private func load() async {
        global = (try? await model.library.globalVoiceBoost()) ?? false
        if let show = player.episode?.showKey {
            choice = try? await model.library.voiceBoostOverride(show)
        }
    }

    /// Applies right away, so there's no Done button.
    private func save(_ isOn: Bool?) {
        guard isOn != choice, let show = player.episode?.showKey else { return }
        choice = isOn
        let library = model.library
        Task {
            await model.change {
                try await library.setVoiceBoostOverride(show, to: isOn)
                try await player.reloadVoiceBoost()
            }
        }
    }
}

/// The moon under the play button, with the time left, "Chapter", or "End" while a timer runs.
private struct SleepTimerButton: View {
    @Environment(Player.self) private var player
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz")
                if let end = player.sleepTimerEndsAt {
                    Text(timerInterval: Date.now...end, countsDown: true).monospacedDigit()
                } else if player.sleepTimer == .endOfChapter {
                    Text("Chapter")
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
        switch player.sleepTimer {
        case .endOfChapter: return "Pauses at the end of the chapter"
        case .endOfEpisode: return "Pauses at the end of the episode"
        default: return "Off"
        }
    }
}

/// The sleep timer's choices. Picking one starts it and closes the sheet.
private struct SleepTimerSheet: View {
    @Environment(Player.self) private var player
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ControlSheet(title: "Sleep timer", value: value, note: "Pauses the episode for you.") {
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach([15, 30, 45, 60], id: \.self) { minutes in
                        choice("\(minutes) min", label: "\(minutes) minutes", timer: .duration(.seconds(minutes * 60)))
                    }
                    if !player.chapters.isEmpty {
                        choice("This chapter", detail: player.chapterProgress.minutesLeft.map { "\($0) min left" },
                               timer: .endOfChapter)
                    }
                    choice("End of episode", detail: episodeMinutesLeft.map { "\($0) min left" }, timer: .endOfEpisode)
                }
                if player.sleepTimer != nil {
                    Button {
                        player.setSleepTimer(nil)
                        dismiss()
                    } label: {
                        Label("Turn Off", systemImage: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(.white.opacity(0.1), in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var value: Text {
        if let end = player.sleepTimerEndsAt { return Text(timerInterval: Date.now...end, countsDown: true) }
        switch player.sleepTimer {
        case .endOfChapter: return Text("Chapter")
        case .endOfEpisode: return Text("End")
        default: return Text("Off")
        }
    }

    private var episodeMinutesLeft: Int? {
        player.duration.map { max(1, Int((($0 - player.position) / 60).rounded(.up))) }
    }

    private func choice(_ title: String, label: String? = nil, detail: String? = nil, timer: SleepTimer) -> some View {
        let isOn = player.sleepTimer == timer
        return Button {
            player.setSleepTimer(timer)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline.weight(.semibold))
                if let detail { Text(detail).font(.caption).foregroundStyle(isOn ? Color.black.opacity(0.6) : .secondary) }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .foregroundStyle(isOn ? Color.black : .white)
            .background(isOn ? Color.white : .white.opacity(0.1), in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label ?? title)
        .accessibilityAddTraits(isOn ? .isSelected : [])
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
