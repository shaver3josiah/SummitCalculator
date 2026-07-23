import SwiftUI

/// The "Load chords" control, reimagined as a slide-to-summit: drag the thumb
/// across the track and the chords load in a burst of leaves. Tapping the
/// track nudges the thumb to teach the gesture; VoiceOver gets a plain button.
struct SlideToSummit: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(SoundStore.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var enabled: Bool
    var onLoad: () -> Void

    @State private var dragX: CGFloat = 0
    @State private var isDragging = false
    @State private var summited = false       // brief success state at the far end
    @State private var successTrigger = 0     // haptic + reset timing
    @State private var resetGeneration = 0
    // Haptics along the travel: a tick every detent, a firmer click when she
    // crosses the release line, and the success buzz on reaching the top.
    @State private var tick = 0
    @State private var lastDetent = 0
    @State private var armed = false

    private let height: CGFloat = 60
    private let thumbSize: CGFloat = 50
    private let inset: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            let maxX = max(1, geo.size.width - thumbSize - inset * 2)
            let progress = min(1, dragX / maxX)

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(theme.color("surfaceSoft"))
                    .overlay(Capsule().stroke(theme.color("line"), lineWidth: 1))

                // Fill grows behind the thumb as it travels
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [theme.color("primary").opacity(0.35), theme.color("primary").opacity(0.75)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: dragX + thumbSize + inset * 2)
                    .opacity(progress > 0.01 ? 1 : 0)

                // Hint label fades as the thumb travels
                HStack(spacing: 6) {
                    Text(enabled ? "Slide to load your chords" : "Pick a song or write chords first")
                        .font(summitBody(14, weight: .semibold))
                        .foregroundStyle(theme.color(enabled ? "deep" : "muted"))
                    if enabled {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.color("primaryStrong"))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.color("primaryStrong").opacity(0.45))
                    }
                }
                .frame(maxWidth: .infinity)
                .opacity(1 - Double(progress) * 1.6)

                // Thumb
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.color("primary"), theme.color("primaryStrong")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: theme.color("shadow"), radius: isDragging ? 10 : 5, y: 3)
                    // The glyph climbs as it travels (an ascent, degree by
                    // degree); the checkmark never does — an upside-down check
                    // reads as a bug. Separate views, so no rotation can leak
                    // onto the check.
                    if summited {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(Double(progress) * -25))
                    }
                }
                .frame(width: thumbSize, height: thumbSize)
                .scaleEffect(isDragging ? 1.06 : (summited ? 1.08 : 1))
                .offset(x: inset + dragX)
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            guard enabled, !summited else { return }
                            isDragging = true
                            dragX = min(maxX, max(0, value.translation.width))
                            updateHaptics(progress: min(1, dragX / maxX))
                        }
                        .onEnded { _ in
                            isDragging = false
                            guard enabled, !summited else { return }
                            if dragX > maxX * 0.85 {
                                complete(maxX: maxX)
                            } else {
                                armed = false
                                lastDetent = 0
                                withAnimation(SummitMotion.springSoft) { dragX = 0 }
                            }
                        }
                )
            }
            .contentShape(Capsule())
            .onTapGesture {
                guard enabled, !summited, !isDragging else { return }
                nudge(maxX: maxX)
            }
        }
        .frame(height: height)
        .opacity(enabled ? 1 : 0.55)
        .animation(.easeOut(duration: 0.25), value: enabled)
        // Feel it the whole way: soft ticks along the track, a firmer click as
        // it arms at the release line, the success buzz on reaching the top.
        .sensoryFeedback(.selection, trigger: tick) { _, _ in sound.hapticsEnabled }
        .sensoryFeedback(.impact(weight: .medium), trigger: armed) { _, now in
            sound.hapticsEnabled && now
        }
        .sensoryFeedback(.success, trigger: successTrigger) { _, _ in sound.hapticsEnabled }
        // VoiceOver skips the gesture entirely: one honest button.
        .accessibilityRepresentation {
            Button("Load chords") { if enabled { onLoad() } }
        }
    }

    /// One tick per detent crossed, and a click the moment the release line is
    /// crossed (either way) — so the track has texture under her thumb.
    private func updateHaptics(progress: Double) {
        // `tick` only ever counts UP — it's a trigger, not a position. (Storing
        // the detent itself fired a phantom tick at touch-down on every drag
        // after the first, when it fell from the last drag's detent back to 0.)
        let detent = Int(progress * 8)
        if detent != lastDetent {
            lastDetent = detent
            tick += 1
        }
        let nowArmed = progress > 0.85
        if nowArmed != armed { armed = nowArmed }
    }

    /// Ride the thumb home, mark the summit, fire the load, then glide back for next time.
    private func complete(maxX: CGFloat) {
        successTrigger += 1
        armed = false
        lastDetent = 0
        withAnimation(SummitMotion.springSoft) {
            dragX = maxX
            summited = true
        }
        onLoad()
        resetGeneration += 1
        let expected = resetGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            guard resetGeneration == expected else { return }
            withAnimation(SummitMotion.springSoft) {
                dragX = 0
                summited = false
            }
        }
    }

    /// A tap on the track teaches the gesture: the thumb hops forward and settles
    /// back. Under reduce-motion the tap just loads (no lesson, no barrier).
    private func nudge(maxX: CGFloat) {
        if reduceMotion || !theme.motionEnabled {
            complete(maxX: maxX)
            return
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { dragX = min(maxX, 34) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            guard !isDragging, !summited else { return }
            withAnimation(SummitMotion.springSoft) { dragX = 0 }
        }
    }
}
