import SwiftUI

/// The Summit mark, ported from the design system's summit-mark.svg
/// (100×100 viewBox): an amber sun cresting behind a snow-capped main peak,
/// with a darker foothill on the right. All fills come from theme tokens so
/// every preset recolors the mark.
struct SummitLogo: View {
    @Environment(ThemeStore.self) private var themeStore
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            SunDisc()
                .fill(themeStore.color("flowerCenter"))
            MainPeak()
                .fill(themeStore.color("primary"))
            SnowCap()
                .fill(themeStore.color("deep"))
            Foothill()
                .fill(themeStore.color("primaryStrong"))
        }
        .frame(width: size, height: size)
    }
}

// Shapes below transcribe summit-mark.svg coordinates, scaled from its
// 100×100 viewBox into the rect.
private func pt(_ x: CGFloat, _ y: CGFloat, _ rect: CGRect) -> CGPoint {
    CGPoint(x: rect.minX + x / 100 * rect.width, y: rect.minY + y / 100 * rect.height)
}

private struct SunDisc: Shape {
    func path(in rect: CGRect) -> Path {
        let r = 11.0 / 100 * min(rect.width, rect.height)
        let c = pt(71, 27, rect)
        return Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
    }
}

private struct MainPeak: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: pt(6, 80, rect))
        p.addLine(to: pt(40, 26, rect))
        p.addLine(to: pt(74, 80, rect))
        p.closeSubpath()
        return p
    }
}

private struct SnowCap: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: pt(40, 26, rect))
        p.addLine(to: pt(50.5, 42.5, rect))
        p.addLine(to: pt(44, 49, rect))
        p.addLine(to: pt(40, 44, rect))
        p.addLine(to: pt(36, 49, rect))
        p.addLine(to: pt(29.5, 42.5, rect))
        p.closeSubpath()
        return p
    }
}

private struct Foothill: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: pt(52, 80, rect))
        p.addLine(to: pt(72, 48, rect))
        p.addLine(to: pt(94, 80, rect))
        p.closeSubpath()
        return p
    }
}

// MARK: - Interactive header mark (tap twirl · double-tap verse · 3s hold white-noise)

/// The header's mark wrapped with its signature tap delight. Leaves `SummitLogo`
/// itself pure so every other call site keeps compiling unchanged.
///
/// Single tap → a spring twirl (overshoots ~360–540° and settles), a quick scale
/// pop, and a one-shot glitter burst. Double tap → the same twirl delight, then
/// `onDoubleTap` (verse mode). 3-second hold → toggles gentle looping white-noise
/// (`WhiteNoisePlayer`); while it plays the mark slowly breathes (or shows a
/// static gold dot under reduce motion), a cue driven by the player's `isPlaying`.
/// Gesture order matters: the `count: 2` tap is attached *before* the `count: 1`
/// tap, so SwiftUI holds the single recognizer until the double fails — a genuine
/// double-tap fires only `onDoubleTap`, never the single handler. The long press is
/// a `.simultaneousGesture`, independent of that arbitration.
struct TappableSummit: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(SoundStore.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var size: CGFloat = 38
    var onDoubleTap: () -> Void = {}

    @State private var spin: Double = 0
    @State private var pop: CGFloat = 1
    @State private var pulse = false
    @State private var glitter = 0
    @State private var breathe = false
    @State private var suppressNextTap = false

    var body: some View {
        ZStack {
            SummitLogo(size: size)
                .rotationEffect(.degrees(spin))
                .scaleEffect(pop * (breathe ? 1.04 : 1.0))
                .opacity(pulse ? 0.55 : 1)
            if theme.leavesOn && !reduceMotion {
                GlitterBurst(trigger: glitter, size: size)
                    .allowsHitTesting(false)
            }
            // White-noise-active cue when the gentle breathing can't run (reduce
            // motion / motion off): a static small gold dot at the mark's corner.
            if WhiteNoisePlayer.shared.isPlaying && !breathingActive {
                Circle()
                    .fill(theme.color("flowerCenter"))
                    .frame(width: size * 0.16, height: size * 0.16)
                    .offset(x: size * 0.36, y: -size * 0.36)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { twirl(); onDoubleTap() }
        .onTapGesture(count: 1) { singleTap() }
        // 3-second hold → toggle the white-noise. `.simultaneousGesture` keeps the
        // long press fully independent of the delicate double-before-single tap
        // arbitration above, so those still resolve exactly as before; its `onEnded`
        // fires at the 3s mark while the finger is still down.
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 3).onEnded { _ in handleHold() }
        )
        .onChange(of: breathingActive) { _, active in animateBreathing(active) }
        .onAppear { animateBreathing(breathingActive) }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Summit mark")
    }

    private func singleTap() {
        // A single tap that is really the release after a successful 3s hold
        // (a simultaneous long-press can leak one) — consume it, don't twirl.
        if suppressNextTap {
            suppressNextTap = false
            return
        }
        sound.play("easteregg")
        twirl()
    }

    /// The breathing cue runs only when noise is on AND motion is allowed.
    private var breathingActive: Bool {
        WhiteNoisePlayer.shared.isPlaying && theme.motionEnabled && !reduceMotion
    }

    private func animateBreathing(_ active: Bool) {
        if active {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.4)) { breathe = false }
        }
    }

    /// 3-second hold toggles the white-noise. Fully gated on SoundStore.enabled:
    /// if sounds are off, the hold is inert. Only the *start* plays a cue.
    private func handleHold() {
        guard sound.enabled else { return }
        if WhiteNoisePlayer.shared.isPlaying {
            WhiteNoisePlayer.shared.stop()
        } else {
            sound.play("success")
            WhiteNoisePlayer.shared.start()
        }
        // Swallow the single-tap the release can leak. Self-heals after 1.5s so a
        // genuine later tap is never wrongly eaten.
        // ponytail: 1.5s window; only misses if the finger stays down >1.5s past
        // the 3s fire, which wouldn't register as a tap anyway.
        suppressNextTap = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { suppressNextTap = false }
    }

    /// The spring twirl + glitter delight, shared by single- and double-tap.
    /// (Double-tap's own sound is played by `onDoubleTap` → `toggleVerse`.)
    /// Reduce Motion / leaves off degrades to a gentle opacity pulse.
    private func twirl() {
        guard theme.leavesOn, !reduceMotion else {
            // Reduce Motion / leaves off: a gentle opacity pulse, no spin or glitter.
            withAnimation(.easeInOut(duration: 0.3)) { pulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) { pulse = false }
            }
            return
        }
        glitter += 1
        // A mountain doesn't twirl: a quick rocking tilt that springs back level,
        // plus the scale pop and glitter shared with Bloom's delight language.
        let tilt = Double(Int.random(in: 8...14)) * (Bool.random() ? 1 : -1)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            spin = tilt
            pop = 1.15
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.15)) {
            spin = 0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
            pop = 1
        }
    }
}

/// One-shot glitter emitter. On each `trigger` bump it flings ~16 tiny gold/steel
/// sparks (a mix of 4-point twinkles and dots) radially from the mark's center
/// with an eased-out throw, then fades + drifts them down and self-clears after
/// ~1.2s. Individually-animated lightweight views (never more than 16 alive),
/// seeded off `trigger` so no two bursts match. Mount behind `theme.leavesOn`.
struct GlitterBurst: View {
    @Environment(ThemeStore.self) private var theme
    let trigger: Int
    var size: CGFloat = 38

    @State private var sparks: [GlitterSpark] = []
    @State private var flung = false
    @State private var faded = false
    @State private var generation = 0

    private static let colorTokens = ["flowerCenter", "primary", "white"]

    var body: some View {
        ZStack {
            ForEach(sparks) { spark in
                sparkView(spark)
                    .frame(width: spark.size, height: spark.size)
                    .rotationEffect(.degrees(flung ? spark.spin : 0))
                    .offset(
                        x: flung ? cos(spark.angle) * spark.distance : 0,
                        y: flung ? sin(spark.angle) * spark.distance + spark.fall : 0
                    )
                    .scaleEffect(flung ? 0.5 : 1)
                    .opacity(faded ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in burst() }
    }

    @ViewBuilder
    private func sparkView(_ spark: GlitterSpark) -> some View {
        let fill = color(spark.colorIndex)
        if spark.isStar {
            FourPointStar().fill(fill)
        } else {
            Circle().fill(fill)
        }
    }

    private func color(_ index: Int) -> Color {
        let token = Self.colorTokens[index % Self.colorTokens.count]
        return token == "white" ? .white : theme.color(token)
    }

    private func burst() {
        guard trigger > 0 else { return }
        sparks = GlitterSpark.make(count: 16, size: size, seed: trigger)
        flung = false
        faded = false
        generation += 1
        let expected = generation
        // Establish the rest state for one frame, then throw + fade.
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.95)) { flung = true }
            withAnimation(.easeIn(duration: 0.55).delay(0.5)) { faded = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if generation == expected { sparks = [] }
        }
    }
}

private struct GlitterSpark: Identifiable {
    let id: Int
    let angle: Double
    let distance: CGFloat
    let fall: CGFloat
    let size: CGFloat
    let spin: Double
    let colorIndex: Int
    let isStar: Bool

    static func make(count: Int, size: CGFloat, seed: Int) -> [GlitterSpark] {
        (0..<count).map { i in
            var rng = SeededGenerator(seed: seed &* 2971 &+ i &* 131 &+ 17)
            let jitter = Double.random(in: -0.3...0.3, using: &rng)
            let angle = (Double(i) / Double(count)) * 2 * .pi + jitter
            let star = Double.random(in: 0...1, using: &rng) < 0.55
            return GlitterSpark(
                id: i,
                angle: angle,
                distance: size * CGFloat.random(in: 0.85...1.7, using: &rng),
                fall: size * CGFloat.random(in: 0.12...0.32, using: &rng),
                size: star ? CGFloat.random(in: 4...7, using: &rng)
                           : CGFloat.random(in: 3...5, using: &rng),
                spin: Double.random(in: -220...220, using: &rng),
                colorIndex: Int.random(in: 0...2, using: &rng),
                isStar: star
            )
        }
    }
}

/// A thin concave four-pointed twinkle used for the glitter sparks.
private struct FourPointStar: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let w = r * 0.28   // concave waist → thin sparkle arms
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x + w, y: c.y - w))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: CGPoint(x: c.x + w, y: c.y + w))
        p.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: CGPoint(x: c.x - w, y: c.y + w))
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x - w, y: c.y - w))
        p.closeSubpath()
        return p
    }
}
