import SwiftUI

struct SoundStudioView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStore.self) private var theme
    @Environment(SoundStore.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showCredits = false
    @State private var playEpoch = 0

    // Positioned leaf bursts: each play button reports its frame in the "studio"
    // coordinate space; on preview we convert its center to fractions of the
    // container so the burst erupts from the button that was pressed.
    //
    // The frames live in a plain reference box, NOT @State: they change on every
    // scroll frame (viewport-relative), and a @State write per frame re-evaluates
    // the whole view while scrolling for zero visual benefit. The box mutation
    // publishes nothing; the value is only read at tap time in preview().
    @State private var frameBox = FrameBox()
    @State private var containerSize: CGSize = .zero
    @State private var burstX: Double = 0.5
    @State private var burstY: Double = 0.25

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Match any sound to each button. Tap a note to preview. Your choices are saved on this device.")
                        .font(summitBody(14))
                        .foregroundStyle(theme.color("muted"))

                    togglesSection

                    groupLabel("Keypad buttons")
                    VStack(spacing: 8) {
                        ForEach(SoundStore.keypadEvents, id: \.0) { eventId, symbol in
                            eventRow(eventId: eventId, symbol: symbol)
                        }
                    }

                    groupLabel("Events")
                    VStack(spacing: 8) {
                        ForEach(SoundStore.namedEvents, id: \.0) { eventId, name in
                            eventRow(eventId: eventId, symbol: name)
                        }
                    }

                    Button("Reset to defaults") {
                        sound.resetToDefaults()
                    }
                    .font(summitBody(14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radius)
                            .fill(theme.color("surfaceSoft"))
                    )

                    Button("Credits") {
                        showCredits = true
                    }
                    .font(summitBody(14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radius)
                            .fill(theme.color("surface2"))
                    )
                }
                .padding(20)
            }
            .background {
                ZStack {
                    theme.color("bg")
                    if theme.motionEnabled && !reduceMotion {
                        DistantRange()
                    }
                }
                .ignoresSafeArea()
            }
            // Measure the container (viewport) that the burst overlay fills, so
            // the play-button fractions below map onto the same area.
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: StudioSizeKey.self, value: proxy.size)
                }
            )
            .coordinateSpace(.named("studio"))
            .overlay {
                // Every preview scatters a few leaves — erupting from the pressed
                // play button (burstX/burstY are fractions of this same container).
                if theme.leavesOn {
                    LeafBurstView(trigger: playEpoch, originX: burstX, originY: burstY)
                        .allowsHitTesting(false)
                }
            }
            .onPreferenceChange(PlayButtonFrameKey.self) { frameBox.frames = $0 }   // no view invalidation
            .onPreferenceChange(StudioSizeKey.self) { containerSize = $0 }
            .navigationTitle("Sound Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        SummitLogo(size: 22)
                        Text("Sound Studio")
                            .font(summitBody(17, weight: .semibold))
                            .foregroundStyle(theme.color("deep"))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
    }

    private var togglesSection: some View {
        VStack(spacing: 10) {
            Toggle(isOn: Binding(
                get: { sound.enabled },
                set: { sound.enabled = $0 }
            )) {
                Text("Sounds")
                    .font(summitBody(15, weight: .medium))
                    .foregroundStyle(theme.color("text"))
            }
            Toggle(isOn: Binding(
                get: { sound.hapticsEnabled },
                set: { sound.hapticsEnabled = $0 }
            )) {
                Text("Haptics")
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

    private func groupLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(summitBody(11, weight: .semibold))
            .foregroundStyle(theme.color("muted"))
            .padding(.top, 4)
    }

    private func eventRow(eventId: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Text(symbol)
                .font(summitBody(14, weight: .semibold))
                .frame(width: 64, alignment: .leading)
                .foregroundStyle(theme.color("text"))

            Picker("", selection: bindingFor(eventId)) {
                ForEach(SoundStore.optionChoices, id: \.0) { value, label in
                    Text(label).tag(value)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                preview(eventId)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(theme.color("surface")))
                    .overlay(
                        Circle().stroke(
                            LinearGradient(
                                colors: [theme.color("primary"), theme.color("flowerCenter")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    )
            }
            .buttonStyle(.plain)
            // Report this button's on-screen center so the burst starts here.
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: PlayButtonFrameKey.self,
                        value: [eventId: proxy.frame(in: .named("studio"))]
                    )
                }
            )
            .accessibilityLabel("Preview sound")
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.color("surfaceSoft"))
        )
    }

    private func preview(_ eventId: String) {
        sound.preview(currentValue(eventId))
        // Aim the burst at the pressed button: its center as a fraction of the
        // container, clamped so an off-viewport reading can't escape 0...1.
        if containerSize.width > 0, containerSize.height > 0, let frame = frameBox.frames[eventId] {
            burstX = min(max(frame.midX / containerSize.width, 0), 1)
            burstY = min(max(frame.midY / containerSize.height, 0), 1)
        }
        playEpoch += 1   // a leaf burst with every note
    }

    private func currentValue(_ eventId: String) -> String {
        sound.eventMap[eventId] ?? SoundStore.defaultMap[eventId] ?? "silent"
    }

    private func bindingFor(_ eventId: String) -> Binding<String> {
        Binding(
            get: { currentValue(eventId) },
            set: { sound.setEvent(eventId, to: $0) }
        )
    }
}

/// Reference box for the play-button frames — a plain class (not @Observable) so
/// per-scroll-frame updates mutate silently instead of invalidating the view.
private final class FrameBox {
    var frames: [String: CGRect] = [:]
}

/// Each play button's frame within the "studio" coordinate space, keyed by event id.
private struct PlayButtonFrameKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// The size of the container the burst overlay fills (used to normalise origins).
private struct StudioSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// Faint summit marks resting behind the studio like a distant range — a static
/// background layer, not content. (Bloom's flowers spun; a mountain holds still.)
private struct DistantRange: View {
    var body: some View {
        GeometryReader { geo in
            FaintPeak(size: 180)
                .position(x: geo.size.width * 0.12, y: geo.size.height * 0.18)
            FaintPeak(size: 130)
                .position(x: geo.size.width * 0.92, y: geo.size.height * 0.42)
            FaintPeak(size: 210)
                .position(x: geo.size.width * 0.20, y: geo.size.height * 0.88)
        }
        .allowsHitTesting(false)
    }
}

private struct FaintPeak: View {
    let size: CGFloat

    var body: some View {
        SummitLogo(size: size)
            .opacity(0.07)
    }
}
