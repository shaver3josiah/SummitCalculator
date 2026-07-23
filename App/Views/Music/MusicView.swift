import SwiftUI

struct MusicView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(MusicStore.self) private var store
    @Environment(SoundStore.self) private var sound

    // Press-feedback epochs for the encircle hairline (app-wide press language).
    @State private var toggleEpoch = 0
    @State private var pressedPad: Int? = nil
    @State private var padEpoch = 0
    @State private var padGeneration = 0

    // Base Camp Sessions tour.
    @State private var tourStep: MusicTourStep? = nil
    @State private var typingTask: Task<Void, Never>? = nil

    @State private var librarySheet: SongCategory? = nil
    @State private var showSongwriter = false

    private let libraryColumns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    headerRow

                    songwriterButton

                    librarySection
                        .id("sec.lib")
                        .tourSpotlight(tourStep == .library, cornerRadius: 18)

                    composeCard
                        .id("sec.compose")
                        .tourSpotlight(tourStep == .write, cornerRadius: theme.radius)

                    Card { NotePiano() }
                        .id("sec.piano")
                        .tourSpotlight(tourStep == .piano, cornerRadius: theme.radius)

                    SlideToSummit(enabled: canLoad) { handleLoad() }
                        .id("sec.slide")
                        .tourSpotlight(tourStep == .slide, cornerRadius: 999)

                    keyChordToggles
                        .encircleOnPress(toggleEpoch, cornerRadius: theme.radius)
                        .onChange(of: store.playOnKeys) { _, _ in toggleEpoch += 1 }
                        .onChange(of: store.cycleOnTabSwitch) { _, _ in toggleEpoch += 1 }

                    if !store.chords.isEmpty {
                        loadedHeader
                        controls
                            .id("sec.controls")
                            .tourSpotlight(tourStep == .controls, cornerRadius: theme.radius)
                        chordPads
                            .id("sec.pads")
                            .tourSpotlight(tourStep == .pads, cornerRadius: theme.radius)
                    }
                }
                .padding(16)
                .padding(.bottom, tourStep == nil ? 16 : 110)
            }
            .background(theme.color("bg"))
            .overlay(alignment: .bottom) {
                if let step = tourStep {
                    MusicTourCard(
                        step: step,
                        onNext: { advanceTour(from: step) },
                        onSkip: { endTour() },
                        onAssist: step == .slide ? { assistLoad() } : nil
                    )
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onChange(of: tourStep) { _, step in
                guard let step, let anchor = scrollAnchor(for: step) else { return }
                withAnimation(SummitMotion.glide) { proxy.scrollTo(anchor, anchor: .center) }
            }
            .sheet(item: $librarySheet) { category in
                SongLibrarySheet(category: category)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showSongwriter) {
                SongwriterView()
            }
            .sensoryFeedback(.impact(weight: .light), trigger: padEpoch) { _, _ in
                sound.hapticsEnabled
            }
            .onAppear {
                store.warmUp()   // engine ready before the first pad/piano tap
            }
            .onDisappear { typingTask?.cancel() }
        }
    }

    private var canLoad: Bool {
        !store.chordText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Pick a song or write your own — every chord rolls out as warm grand piano, all offline.")
                .font(summitBody(14))
                .foregroundStyle(theme.color("muted"))
                .frame(maxWidth: .infinity, alignment: .leading)
            // The tour is a small, quiet offer in the corner — never a popup,
            // never a banner. She takes it when she wants it.
            Button {
                startTour()
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(theme.color("surface2")))
                    // Reach 44, lay out 36 — the header row and the press dim both
                    // stay exactly where they were.
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .padding(-4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Take the tour")
            .accessibilityHint("Walks you through Base Camp Sessions")
        }
    }

    // The doorway to her clean page: chords AND lyrics, structured like a song.
    private var songwriterButton: some View {
        Button {
            sound.play("modeswitch")
            showSongwriter = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: [theme.color("primary"), theme.color("primaryStrong")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Songwriting mode")
                        .font(summitBody(16, weight: .semibold))
                        .foregroundStyle(theme.color("deep"))
                    Text("A clean page for chords, lyrics & structure")
                        .font(summitBody(12))
                        .foregroundStyle(theme.color("muted"))
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.color("primaryStrong"))
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                    .fill(theme.color("surface"))
                    .shadow(color: theme.color("shadow"), radius: 10, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                    .stroke(theme.color("primary").opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens a full-screen page to write chords and lyrics")
    }

    // MARK: - Song library

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Song library", systemImage: "books.vertical.fill")
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
            LazyVGrid(columns: libraryColumns, spacing: 10) {
                ForEach(SongCategory.allCases) { category in
                    categoryCard(category)
                }
            }
        }
    }

    private func categoryCard(_ category: SongCategory) -> some View {
        Button {
            sound.play("modeswitch")
            librarySheet = category
        } label: {
            HStack(spacing: 10) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: [theme.color("primary"), theme.color("primaryStrong")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(summitBody(15, weight: .semibold))
                        .foregroundStyle(theme.color("deep"))
                    Text("\(category.songs.count) songs")
                        .font(summitBody(12))
                        .foregroundStyle(theme.color("muted"))
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.color("surface"))
                    .shadow(color: theme.color("shadow"), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.name), \(category.songs.count) songs")
    }

    // MARK: - Compose

    private var composeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Label("Write your own", systemImage: "pencil.and.outline")
                    .font(summitBody(13, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                TextField(
                    "C  G  Am  F    (Dm7, C/E — or notes like E4)",
                    text: chordTextBinding,
                    prompt: Text("C  G  Am  F    (Dm7, C/E — or notes like E4)")
                        .foregroundStyle(theme.color("muted")),
                    axis: .vertical
                )
                .font(summitBody(14))
                .lineLimit(3...6)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(theme.color("surfaceSoft")))
                sampleChips
            }
        }
    }

    private var sampleChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("TRY")
                    .font(summitBody(11, weight: .semibold))
                    .foregroundStyle(theme.color("muted"))
                ForEach(MusicStore.samples, id: \.0) { key, label in
                    Button {
                        store.loadSample(key)
                        sound.play("modeswitch")
                    } label: {
                        Text(label)
                            .font(summitBody(12, weight: .medium))
                            .foregroundStyle(theme.color("text"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(theme.color("surfaceSoft")))
                            // After the capsule, so the pill keeps its size and only
                            // the reachable area grows around it.
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Toggles (unchanged behavior)

    private var keyChordToggles: some View {
        VStack(spacing: 10) {
            Toggle(isOn: playOnKeysBinding) {
                Text("Play chords on calculator keys")
                    .font(summitBody(15, weight: .medium))
                    .foregroundStyle(theme.color("text"))
            }
            Toggle(isOn: cycleOnTabSwitchBinding) {
                Text("Cycle chords on tab switch")
                    .font(summitBody(15, weight: .medium))
                    .foregroundStyle(theme.color("text"))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surface"))
        )
        .tint(theme.color("primaryStrong"))
    }

    // MARK: - Loaded song

    private var loadedHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "music.note.list")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.color("primaryStrong"))
            VStack(alignment: .leading, spacing: 1) {
                Text(store.loadedSongTitle ?? "Your chords")
                    .font(summitBody(15, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                Text("\(store.chords.count) \(store.chords.count == 1 ? "pad" : "pads") · tap to play")
                    .font(summitBody(12))
                    .foregroundStyle(theme.color("muted"))
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    private var controls: some View {
        Card(padding: 14) {
            VStack(spacing: 14) {
                HStack {
                    Button {
                        store.isPlaying ? store.stopAll() : store.playAll()
                    } label: {
                        Label(store.isPlaying ? "Stop" : "Play", systemImage: store.isPlaying ? "stop.fill" : "play.fill")
                            .font(summitBody(15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(theme.color("primaryStrong")))
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Toggle("Strum", isOn: strumBinding)
                        .font(summitBody(13))
                        .foregroundStyle(theme.color("text"))
                        .tint(theme.color("primaryStrong"))
                        .fixedSize()
                }

                HStack {
                    Text("Tempo")
                        .font(summitBody(13))
                        .foregroundStyle(theme.color("muted"))
                        .frame(width: 64, alignment: .leading)
                    Slider(value: tempoBinding, in: 50...170)
                        .tint(theme.color("primary"))
                    Text("\(Int(store.tempo))")
                        .font(summitNumber(15))
                        .frame(width: 36)
                }

                HStack {
                    Text("Loudness")
                        .font(summitBody(13))
                        .foregroundStyle(theme.color("muted"))
                        .frame(width: 64, alignment: .leading)
                    Slider(value: chordVolumeBinding, in: 0.5...1.8)
                        .tint(theme.color("primary"))
                    Text("\(Int(store.chordVolume * 100))%")
                        .font(summitNumber(15))
                        .frame(width: 44)
                }

                HStack(spacing: 10) {
                    Text("Transpose")
                        .font(summitBody(13))
                        .foregroundStyle(theme.color("muted"))
                        .frame(width: 64, alignment: .leading)
                    transposeButton("minus") { store.transpose -= 1 }
                    Text("\(store.transpose > 0 ? "+" : "")\(store.transpose)")
                        .font(summitNumber(15))
                        .frame(width: 40)
                    transposeButton("plus") { store.transpose += 1 }
                    Spacer()
                }
            }
        }
    }

    private func transposeButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.color("primaryStrong"))
                .frame(width: 36, height: 36)
                .background(Circle().fill(theme.color("surfaceSoft")))
                // Reach 44, lay out 36 — see NotePiano's octave stepper.
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .padding(-4)
        }
        .buttonStyle(.plain)
    }

    private var chordPads: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 12)], spacing: 12) {
            ForEach(Array(store.chords.enumerated()), id: \.offset) { index, chord in
                let isNote = chord.midiNotes.count == 1
                Button {
                    store.playChord(chord)
                    bumpPad(index)
                } label: {
                    HStack(spacing: 3) {
                        if isNote {
                            Image(systemName: "music.note")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(theme.color("primaryStrong"))
                        }
                        Text(chord.symbol)
                            .font(summitNumber(16, weight: .semibold))
                            .foregroundStyle(theme.color("deep"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.color(isNote ? "surface2" : "surfaceSoft"))
                    )
                }
                .buttonStyle(.plain)
                .overlay {
                    if theme.shimmerOn && pressedPad == index {
                        EncircleOutline(trigger: padEpoch, cornerRadius: 16, lineWidth: 1.5)
                            .transition(.opacity)
                    }
                }
                .accessibilityLabel(isNote ? "Note \(chord.symbol)" : "Chord \(chord.symbol)")
            }
        }
    }

    /// Encircle the tapped chord pad for ~1s, then clear (guarded so a newer tap wins).
    private func bumpPad(_ index: Int) {
        pressedPad = index
        padEpoch += 1
        padGeneration += 1
        let expected = padGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if padGeneration == expected {
                withAnimation(.easeOut(duration: 0.35)) { pressedPad = nil }
            }
        }
    }

    // MARK: - Load

    /// Tour "Do it for me": make sure there's something to load, then load it.
    private func assistLoad() {
        if !canLoad { store.chordText = "C G Am F" }
        handleLoad()
    }

    private func handleLoad() {
        store.loadChords()
        sound.play("modeswitch")
        theme.triggerCurtain()
        if tourStep == .slide {
            withAnimation(SummitMotion.springSoft) { tourStep = .pads }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if tourStep == .pads { store.playAll() }
            }
        }
    }

    // MARK: - Tour state machine

    private func startTour() {
        typingTask?.cancel()
        withAnimation(SummitMotion.springSoft) { tourStep = .welcome }
    }

    private func advanceTour(from step: MusicTourStep) {
        switch step {
        case .welcome:
            sound.play("modeswitch")
            withAnimation(SummitMotion.springSoft) { tourStep = .library }
        case .library:
            withAnimation(SummitMotion.springSoft) { tourStep = .write }
            typeDemoChords()
        case .write:
            withAnimation(SummitMotion.springSoft) { tourStep = .slide }
        case .slide:
            withAnimation(SummitMotion.springSoft) { tourStep = .pads }
        case .pads:
            store.stopAll()
            withAnimation(SummitMotion.springSoft) { tourStep = .controls }
        case .controls:
            withAnimation(SummitMotion.springSoft) { tourStep = .piano }
        case .piano:
            withAnimation(SummitMotion.springSoft) { tourStep = .done }
        case .done:
            sound.play("success")
            theme.triggerCurtain()
            endTour()
        }
    }

    private func endTour() {
        typingTask?.cancel()
        withAnimation(SummitMotion.springSoft) { tourStep = nil }
    }

    /// Which section the tour card is talking about, for the auto-scroll.
    private func scrollAnchor(for step: MusicTourStep) -> String? {
        switch step {
        case .welcome, .done: return nil
        case .library: return "sec.lib"
        case .write: return "sec.compose"
        case .slide: return "sec.slide"
        case .pads: return "sec.pads"
        case .controls: return "sec.controls"
        case .piano: return "sec.piano"
        }
    }

    /// Typewriter demo: writes a friendly progression into the box, one letter
    /// at a time. Never clobbers something she already wrote.
    private func typeDemoChords() {
        guard store.chordText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        typingTask?.cancel()
        typingTask = Task { @MainActor in
            store.chordText = ""
            for ch in "C G Am F" {
                guard !Task.isCancelled else { return }
                store.chordText.append(ch)
                try? await Task.sleep(nanoseconds: 110_000_000)
            }
        }
    }

    // MARK: - Bindings

    private var chordTextBinding: Binding<String> {
        Binding(get: { store.chordText }, set: { store.chordText = $0 })
    }
    private var strumBinding: Binding<Bool> {
        Binding(get: { store.strum }, set: { store.strum = $0 })
    }
    private var tempoBinding: Binding<Double> {
        Binding(get: { store.tempo }, set: { store.tempo = $0 })
    }
    private var chordVolumeBinding: Binding<Double> {
        Binding(get: { store.chordVolume }, set: { store.chordVolume = $0 })
    }
    private var playOnKeysBinding: Binding<Bool> {
        Binding(get: { store.playOnKeys }, set: { store.playOnKeys = $0 })
    }
    private var cycleOnTabSwitchBinding: Binding<Bool> {
        Binding(get: { store.cycleOnTabSwitch }, set: { store.cycleOnTabSwitch = $0 })
    }
}
