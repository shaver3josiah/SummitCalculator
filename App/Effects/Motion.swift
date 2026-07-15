import SwiftUI

/// Shared motion tokens from the Summit design system (see the Motion reference).
/// Durations are seconds; easings are the documented cubic-beziers so the app
/// matches the spec instead of scattering magic numbers across views.
enum SummitMotion {
    static let outlineDraw: Double = 0.72
    static let panelGlide: Double = 0.56
    static let shimmerHalf: Double = 1.7   // 3.4s breathe loop (autoreverses)

    /// Panel glide — expo-out, cubic-bezier(.16,1,.3,1).
    static let glide = Animation.timingCurve(0.16, 1, 0.3, 1, duration: panelGlide)
    /// Outline draw — cubic-bezier(.35,0,.15,1).
    static let draw = Animation.timingCurve(0.35, 0, 0.15, 1, duration: outlineDraw)
    /// Soft presentation spring shared by toasts, overlays and result reveals.
    static let springSoft = Animation.spring(response: 0.45, dampingFraction: 0.8)
}

/// Feathered clear→white→clear gloss, angled 18° and sized to half the given
/// `full` width. Shared by the idle glint and the per-press echo so they are
/// literally the same band of light — same angle, width and direction; only the
/// `peak` white opacity differs (the press burns brighter). The soft shoulders
/// (feathered stops instead of a hard white middle) make it read as light on a
/// surface, not a printed stripe.
private func glossBand(peak: Double, full: CGFloat) -> some View {
    LinearGradient(
        stops: [
            .init(color: .clear, location: 0),
            .init(color: .white.opacity(peak * 0.3), location: 0.38),
            .init(color: .white.opacity(peak), location: 0.5),
            .init(color: .white.opacity(peak * 0.3), location: 0.62),
            .init(color: .clear, location: 1),
        ],
        startPoint: .leading, endPoint: .trailing
    )
    .frame(width: full * 0.5)
    .rotationEffect(.degrees(18))
}

/// A glossy highlight band that sweeps once across on each `trigger` flip — the
/// brighter, faster echo of the `=` key's idle glint (same 18° band, same
/// left→right direction). `intense` gives the darker accent keys a brighter
/// shine. Reduce-motion safe.
struct ShimmerSweep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let trigger: Bool
    var intense: Bool = false
    var cornerRadius: CGFloat = 12

    @State private var phase: CGFloat = -1.2

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            GeometryReader { geo in
                glossBand(peak: intense ? 0.5 : 0.28, full: geo.size.width)
                    .offset(x: phase * geo.size.width * 1.25)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .allowsHitTesting(false)
            .onChange(of: trigger) { _, _ in
                phase = -1.2
                withAnimation(.easeOut(duration: 0.5)) { phase = 1.2 }
            }
        }
    }
}

/// The signature ridge→amber hairline that traces once around a rounded rect on
/// `trigger` change, then settles into a soft presence. This is the app-wide
/// "encircling" language (first used on the mode buttons) — reuse this instead
/// of hand-rolling per-view copies. Gate mounting behind `theme.shimmerOn`.
struct EncircleOutline<Trigger: Equatable>: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let trigger: Trigger
    var cornerRadius: CGFloat = 12
    var lineWidth: CGFloat = 1
    var settleOpacity: Double = 0.55

    @State private var drawEnd: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .trim(from: 0, to: reduceMotion ? 1 : drawEnd)
            .stroke(
                LinearGradient(
                    colors: [theme.color("primary"), theme.color("flowerCenter")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .opacity(reduceMotion ? settleOpacity * 0.8 : settleOpacity)
            .allowsHitTesting(false)
            // Trace on appear too: sites like the kitchen pill and the QR reveal
            // mount a fresh instance with the new trigger value, so onChange alone
            // would never fire for them.
            .onAppear {
                if reduceMotion { drawEnd = 1 } else { trace() }
            }
            .onChange(of: trigger) { _, _ in
                guard !reduceMotion else { return }
                trace()
            }
    }

    private func trace() {
        drawEnd = 0
        withAnimation(SummitMotion.draw) { drawEnd = 1 }
    }
}

/// Ambient "jewel glint" for the single hero CTA (the `=` key). Deliberately a
/// low-contrast directional gloss that eases once across — slow in, quick through
/// the middle, soft out — then parks off-screen and rests ~3.9s before the next
/// glint. It is NOT a looping opacity/breathe pulse (the AI-slop "breathing CTA"
/// fingerprint): each cycle is a single glint→rest, never a continuous shimmer.
/// The band itself is feathered (soft shoulders, peak white ≤0.2) so it reads as
/// light on a surface, and a static top-left specular dot gives the key material
/// depth. One element only, gated behind the motion toggle + Reduce Motion, so it
/// reads as specular material, not a status indicator. See the debate in v0.1.19.
struct AmbientShimmer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var cornerRadius: CGFloat = 12

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            ZStack {
                // Static specular highlight, pinned top-left — pure material depth,
                // never animates.
                RadialGradient(
                    colors: [.white.opacity(0.15), .clear],
                    center: UnitPoint(x: 0.3, y: 0.25),
                    startRadius: 0, endRadius: 20
                )
                GeometryReader { geo in
                    glossBand(peak: 0.2, full: geo.size.width)
                        .keyframeAnimator(initialValue: CGFloat(-1.1), repeating: true) { view, x in
                            view.offset(x: x * geo.size.width)
                        } keyframes: { _ in
                            KeyframeTrack {
                                CubicKeyframe(1.1, duration: 1.1)
                                LinearKeyframe(1.1, duration: 3.9)
                                MoveKeyframe(-1.1)
                            }
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .allowsHitTesting(false)
        }
    }
}
