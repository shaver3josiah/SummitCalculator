import SwiftUI

struct MusicView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(MusicStore.self) private var store
    @Environment(SoundStore.self) private var sound

    // Press-feedback epochs for the encircle hairline.
    @State private var loadEpoch = 0
    @State private var toggleEpoch = 0
    @State private var pressedChip: String? = nil
    @State private var chipEpoch = 0
    @State private var chipGeneration = 0
    @State private var pressedPad: Int? = nil
    @State private var padEpoch = 0
    @State private var padGeneration = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                introText
                textBox
                sampleChips
                loadButton
                    .encircleOnPress(loadEpoch, cornerRadius: 999)
                keyChordToggles
                    .encircleOnPress(toggleEpoch, cornerRadius: theme.radius)
                    .onChange(of: store.playOnKeys) { _, _ in toggleEpoch += 1 }
                    .onChange(of: store.cycleOnTabSwitch) { _, _ in toggleEpoch += 1 }

                if !store.chords.isEmpty {
                    controls
                    chordPads
                }
            }
            .padding(16)
        }
        .background(theme.color("bg"))
    }

    private var introText: some View {
        Text("Paste piano chords and hear them roll out as warm grand-piano sound. Everything plays offline.")
            .font(summitBody(14))
            .foregroundStyle(theme.color("muted"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var textBox: some View {
        TextField(
            "Paste chords, e.g.   C  G  Am  F      (Dm7 G7 Cmaj7 and C/E also work)",
            text: chordTextBinding,
            prompt: Text("Paste chords, e.g.   C  G  Am  F      (Dm7 G7 Cmaj7 and C/E also work)")
                .foregroundStyle(theme.color("muted")),
            axis: .vertical
        )
        .font(summitBody(14))
        .lineLimit(3...6)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))
    }

    private var sampleChips: some View {
        HStack(spacing: 8) {
            Text("TRY")
                .font(summitBody(11, weight: .semibold))
                .foregroundStyle(theme.color("muted"))
            ForEach(MusicStore.samples, id: \.0) { key, label in
                Button(label) {
                    store.loadSample(key)
                    bumpChip(key)
                }
                .font(summitBody(12, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("surfaceSoft")))
                .overlay {
                    if theme.shimmerOn && pressedChip == key {
                        EncircleOutline(trigger: chipEpoch, cornerRadius: 999, lineWidth: 1)
                            .transition(.opacity)
                    }
                }
            }
        }
    }

    private var loadButton: some View {
        Button("Load chords") {
            store.loadChords()
            sound.play("modeswitch")
            theme.triggerCurtain()
            loadEpoch += 1
        }
        .font(summitBody(15, weight: .semibold))
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("primaryStrong")))
        .foregroundStyle(.white)
    }

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

    private var controls: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    store.isPlaying ? store.stopAll() : store.playAll()
                } label: {
                    Label(store.isPlaying ? "Stop" : "Play", systemImage: store.isPlaying ? "stop.fill" : "play.fill")
                }
                .font(summitBody(14, weight: .semibold))
                Spacer()
                Toggle("Strum", isOn: strumBinding)
                    .font(summitBody(13))
                    .fixedSize()
            }

            HStack {
                Text("Tempo")
                    .font(summitBody(13))
                    .foregroundStyle(theme.color("muted"))
                Slider(value: tempoBinding, in: 50...170)
                Text("\(Int(store.tempo))")
                    .font(summitNumber(15))
                    .frame(width: 32)
            }

            HStack {
                Text("Chord volume")
                    .font(summitBody(13))
                    .foregroundStyle(theme.color("muted"))
                Slider(value: chordVolumeBinding, in: 0.5...1.8)
                Text("\(Int(store.chordVolume * 100))%")
                    .font(summitNumber(15))
                    .frame(width: 44)
            }

            HStack {
                Text("Transpose")
                    .font(summitBody(13))
                    .foregroundStyle(theme.color("muted"))
                Button("-") { store.transpose -= 1 }
                Text("\(store.transpose > 0 ? "+" : "")\(store.transpose)")
                    .font(summitNumber(15))
                    .frame(width: 40)
                Button("+") { store.transpose += 1 }
                Spacer()
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
    }

    private var chordPads: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 10)], spacing: 10) {
            ForEach(Array(store.chords.enumerated()), id: \.offset) { index, chord in
                Button(chord.symbol) {
                    store.playChord(chord)
                    bumpPad(index)
                }
                .font(summitNumber(16, weight: .semibold))
                .frame(width: 76, height: 56)
                .background(RoundedRectangle(cornerRadius: 14).fill(theme.color("surfaceSoft")))
                .foregroundStyle(theme.color("deep"))
                .overlay {
                    if theme.shimmerOn && pressedPad == index {
                        EncircleOutline(trigger: padEpoch, cornerRadius: 14, lineWidth: 1.5)
                            .transition(.opacity)
                    }
                }
            }
        }
    }

    /// Encircle the tapped chip for ~1s, then clear (guarded so a newer tap wins).
    private func bumpChip(_ key: String) {
        pressedChip = key
        chipEpoch += 1
        chipGeneration += 1
        let expected = chipGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if chipGeneration == expected {
                withAnimation(.easeOut(duration: 0.35)) { pressedChip = nil }
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
