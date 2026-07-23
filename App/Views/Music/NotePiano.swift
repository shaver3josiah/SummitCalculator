import SwiftUI

/// A pocket piano: one octave of tappable keys. Every tap plays the note with
/// the same soft grand-piano voice AND drops its token (e.g. "E4") into the
/// song box, so melodies can be sprinkled between chords. Octaves 2–5 only —
/// those tokens never collide with chord names like C6/G7/C9.
struct NotePiano: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(MusicStore.self) private var store
    @Environment(SoundStore.self) private var sound

    @State private var octave = 4
    @State private var tapTrigger = 0

    private static let whiteKeys: [(name: String, pc: Int)] = [
        ("C", 0), ("D", 2), ("E", 4), ("F", 5), ("G", 7), ("A", 9), ("B", 11)
    ]
    // (name, pitch class, index of the white key this black key follows)
    private static let blackKeys: [(name: String, pc: Int, after: Int)] = [
        ("C#", 1, 0), ("D#", 3, 1), ("F#", 6, 3), ("G#", 8, 4), ("A#", 10, 5)
    ]
    private static let spacing: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            keyboard
            Text("Tap a key — it plays, and lands in your song.")
                .font(summitBody(12))
                .foregroundStyle(theme.color("muted"))
        }
        .sensoryFeedback(.impact(weight: .light), trigger: tapTrigger) { _, _ in
            sound.hapticsEnabled
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Label("Single notes", systemImage: "music.note")
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
            Spacer()
            octaveButton("minus", disabled: octave <= 2) { octave -= 1 }
            Text("C\(octave)–B\(octave)")
                .font(summitNumber(14))
                .foregroundStyle(theme.color("text"))
                .frame(width: 62)
            octaveButton("plus", disabled: octave >= 5) { octave += 1 }
            octaveButton("delete.left", disabled: store.chordText.isEmpty) {
                store.removeLastToken()
            }
            // Delete wipes a note; the steppers only nudge the octave. They differ
            // by one glyph, so the gap is the only thing standing between a fumbled
            // "+" and a lost note: 10pt HStack spacing + 10pt here = 20pt of miss.
            .padding(.leading, 10)
            .accessibilityLabel("Remove last note")
        }
    }

    private func octaveButton(_ icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.color(disabled ? "muted" : "primaryStrong"))
                .frame(width: 36, height: 36)
                .background(Circle().fill(theme.color("surfaceSoft")))
                // 44x44 of reach around a disc that still draws — and still lays
                // out — at 36: three of these plus the "C4–B4" readout and the
                // section label have no width to spare on an SE. The -4 gives the
                // 8pt back to the row, and keeps the press dim on the disc
                // instead of haloing 4pt past it.
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .padding(-4)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    private var keyboard: some View {
        GeometryReader { geo in
            let whiteW = (geo.size.width - Self.spacing * 6) / 7
            let blackW = whiteW * 0.62

            ZStack(alignment: .topLeading) {
                HStack(spacing: Self.spacing) {
                    ForEach(Self.whiteKeys, id: \.0) { key in
                        pianoKey(key.name, pc: key.pc, isBlack: false)
                            .frame(height: 104)
                    }
                }
                // The black keys land ~23pt wide on an SE and stay there: a piano's
                // black keys are narrow by nature, and she aims at them the way she
                // aims at a real one. Widening them to 44 would stop it being a piano.
                ForEach(Self.blackKeys, id: \.0) { key in
                    let boundary = CGFloat(key.after + 1) * whiteW
                        + CGFloat(key.after) * Self.spacing + Self.spacing / 2
                    pianoKey(key.name, pc: key.pc, isBlack: true)
                        .frame(width: blackW, height: 62)
                        .offset(x: boundary - blackW / 2)
                }
            }
        }
        .frame(height: 104)
    }

    private func pianoKey(_ name: String, pc: Int, isBlack: Bool) -> some View {
        Button {
            tapTrigger += 1
            let symbol = "\(name)\(octave)"
            store.playNote(midi: 12 * (octave + 1) + pc, symbol: symbol)
            store.appendToken(symbol)
        } label: {
            VStack {
                Spacer()
                if !isBlack {
                    Text(name)
                        .font(summitBody(11, weight: .medium))
                        .foregroundStyle(theme.color("muted"))
                        .padding(.bottom, 6)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: isBlack ? 5 : 8, style: .continuous)
                    .fill(isBlack ? theme.color("deep") : theme.color("surface"))
                    .shadow(color: theme.color("shadow"), radius: isBlack ? 3 : 2, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: isBlack ? 5 : 8, style: .continuous)
                    .stroke(theme.color("line"), lineWidth: isBlack ? 0 : 1)
            )
        }
        .buttonStyle(PianoKeyPressStyle(isBlack: isBlack))
        .accessibilityLabel("\(name) \(octave)")
    }
}

/// Piano-specific press: the key sinks straight down and darkens, like a real
/// key going into the bed.
private struct PianoKeyPressStyle: ButtonStyle {
    var isBlack: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: isBlack ? 5 : 8, style: .continuous)
                    .fill(Color.black.opacity(configuration.isPressed ? (isBlack ? 0.25 : 0.09) : 0))
            )
            .offset(y: configuration.isPressed ? 2 : 0)
            .scaleEffect(configuration.isPressed ? 0.985 : 1, anchor: .top)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
