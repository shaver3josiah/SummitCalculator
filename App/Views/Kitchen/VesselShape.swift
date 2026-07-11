import SwiftUI

// Measuring vessels, redrawn after sturdy camp-kitchen kit: cups have a pour
// spout, a loop handle and embossed tick marks; spoon sets hang from a ring on
// a slender handle, with the tablespoon a deep oval bowl and the teaspoon a
// smaller oval. Outlines use the app's ridge→amber gradient (the mode button
// language), rims and rings pick out the amber.

enum MeasureKind {
    case cup, tablespoon, teaspoon

    /// Fraction of the glyph height (from the bottom) that the bowl occupies —
    /// liquid fills only this region, never the handle.
    var bowlSpan: CGFloat {
        switch self {
        case .cup: return 0.88
        case .tablespoon: return 0.56
        case .teaspoon: return 0.50
        }
    }
}

/// Vintage measuring-cup body: flared rim with a left pour spout, gently
/// tapered walls, rounded bottom. Fillable (used for both outline and liquid).
struct CupBody: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }
        p.move(to: pt(0.22, 0.10))                                  // rim, left of spout
        p.addLine(to: pt(0.04, 0.02))                               // spout tip
        p.addQuadCurve(to: pt(0.16, 0.24), control: pt(0.06, 0.16)) // spout underside
        p.addLine(to: pt(0.26, 0.82))                               // left wall (tapers in)
        p.addQuadCurve(to: pt(0.74, 0.82), control: pt(0.50, 0.98)) // rounded bottom
        p.addLine(to: pt(0.84, 0.10))                               // right wall
        p.addLine(to: pt(0.22, 0.10))                               // rim
        p.closeSubpath()
        return p
    }
}

/// Loop handle on the cup's right side (stroke only).
struct CupHandle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }
        // Loop bulges a touch further right than a wire handle would, so the 2×
        // stroke (goldDetails) still leaves a visible opening against the body.
        p.move(to: pt(0.83, 0.22))
        p.addQuadCurve(to: pt(1.02, 0.42), control: pt(1.10, 0.25))
        p.addQuadCurve(to: pt(0.80, 0.62), control: pt(1.05, 0.62))
        return p
    }
}

/// Spoon silhouette: bowl at the bottom (so liquid fills it first), slender
/// handle rising to a hang ring. Tablespoon = deep oval; teaspoon = smaller oval.
struct SpoonBody: Shape {
    var smallBowl: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height

        let handleW: CGFloat = smallBowl ? 0.10 : 0.12
        let handleTop: CGFloat = smallBowl ? 0.17 : 0.16
        let handleBottom: CGFloat = smallBowl ? 0.56 : 0.50
        p.addRoundedRect(
            in: CGRect(
                x: rect.minX + (0.5 - handleW / 2) * w,
                y: rect.minY + handleTop * h,
                width: handleW * w,
                height: (handleBottom - handleTop) * h
            ),
            cornerSize: CGSize(width: handleW * w / 2, height: handleW * w / 2)
        )

        if smallBowl {
            // Smaller oval bowl in box x 0.20–0.80, y 0.50–0.98.
            p.addEllipse(in: CGRect(
                x: rect.minX + 0.20 * w,
                y: rect.minY + 0.50 * h,
                width: 0.60 * w,
                height: 0.48 * h
            ))
        } else {
            // Deep oval bowl.
            p.addEllipse(in: CGRect(
                x: rect.minX + 0.14 * w,
                y: rect.minY + 0.44 * h,
                width: 0.72 * w,
                height: 0.54 * h
            ))
        }
        return p
    }
}

/// The hang ring at the top of a spoon handle (stroke only, picked out in gold).
struct SpoonRing: Shape {
    var small: Bool

    func path(in rect: CGRect) -> Path {
        let r = (small ? 0.055 : 0.065) * rect.width
        let center = CGPoint(x: rect.midX, y: rect.minY + (small ? 0.10 : 0.09) * rect.height)
        return Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
    }
}

/// One measuring vessel with an animated liquid fill. The single glyph used
/// everywhere: big converter illustration and small count grids.
struct MeasureGlyph: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let kind: MeasureKind
    let fraction: Double
    var height: CGFloat = 140

    var body: some View {
        GeometryReader { geo in
            ZStack {
                vesselPath(in: geo)
                    .fill(theme.color("surface"))

                liquid(in: geo)

                vesselPath(in: geo)
                    .stroke(outlineGradient, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))

                goldDetails(in: geo)
            }
        }
        .frame(height: height)
    }

    private func vesselPath(in geo: GeometryProxy) -> Path {
        switch kind {
        case .cup: return CupBody().path(in: CGRect(origin: .zero, size: geo.size))
        case .tablespoon: return SpoonBody(smallBowl: false).path(in: CGRect(origin: .zero, size: geo.size))
        case .teaspoon: return SpoonBody(smallBowl: true).path(in: CGRect(origin: .zero, size: geo.size))
        }
    }

    private func liquid(in geo: GeometryProxy) -> some View {
        vesselPath(in: geo)
            .fill(
                LinearGradient(
                    colors: [theme.color("primary"), theme.color("primaryStrong")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask(alignment: .bottom) {
                Rectangle()
                    .frame(height: geo.size.height * kind.bowlSpan * clampedFraction)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.85), value: fraction)
    }

    @ViewBuilder
    private func goldDetails(in geo: GeometryProxy) -> some View {
        let rect = CGRect(origin: .zero, size: geo.size)
        let gold = theme.color("flowerCenter")
        switch kind {
        case .cup:
            // Handle reads as a solid loop, not a wire — 2× the old weight,
            // proportional to the glyph so the small count-grid cups keep the
            // same sturdy look as the hero.
            CupHandle().path(in: rect)
                .stroke(outlineGradient, style: StrokeStyle(lineWidth: max(rect.height * 0.09, 5.2), lineCap: .round))
            // Gold rim.
            Path { p in
                p.move(to: CGPoint(x: 0.22 * rect.width, y: 0.10 * rect.height))
                p.addLine(to: CGPoint(x: 0.84 * rect.width, y: 0.10 * rect.height))
            }
            .stroke(gold, lineWidth: 1.4)
            // Embossed ¼/½/¾ measure lines, mapped bottom-up onto the body.
            Path { p in
                for tick in cupTicks {
                    p.move(to: CGPoint(x: 0.32 * rect.width, y: tick.y * rect.height))
                    p.addLine(to: CGPoint(x: 0.46 * rect.width, y: tick.y * rect.height))
                }
            }
            .stroke(gold.opacity(0.7), lineWidth: 1)
            // Labels only on the large hero glyph; small count-grid cups stay clean.
            if height >= 100 {
                ForEach(cupTicks.indices, id: \.self) { i in
                    Text(cupTicks[i].label)
                        .font(summitBody(8, weight: .semibold))
                        .foregroundStyle(gold.opacity(0.8))
                        .position(x: 0.52 * rect.width, y: cupTicks[i].y * rect.height)
                }
            }
        case .tablespoon:
            SpoonRing(small: false).path(in: rect)
                .stroke(gold, lineWidth: 1.4)
        case .teaspoon:
            SpoonRing(small: true).path(in: rect)
                .stroke(gold, lineWidth: 1.4)
        }
    }

    private var outlineGradient: LinearGradient {
        LinearGradient(
            colors: [theme.color("primary"), theme.color("flowerCenter")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var clampedFraction: Double {
        min(max(fraction, 0), 1)
    }

    /// Embossed measure lines at ¼/½/¾ of the cup body. The body reads from
    /// rim (y≈0.10) to bottom (y≈0.86), a 0.76 span; liquid rises bottom-up, so
    /// fill fraction f sits at y = 0.86 − f·0.76 (¾ highest, ¼ lowest).
    private var cupTicks: [(y: CGFloat, label: String)] {
        [(0.29, "¾"), (0.48, "½"), (0.67, "¼")]
    }
}

/// Big converter cup — kept as the old name so call sites stay small.
struct VesselFill: View {
    let fraction: Double
    var height: CGFloat = 140

    var body: some View {
        MeasureGlyph(kind: .cup, fraction: fraction, height: height)
    }
}

// Kitchen scale (weight conversions), with the gradient dial to match.
struct ScaleDial: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.34)
        let radius = rect.height * 0.3
        var path = Path()
        path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        return path
    }
}

struct ScaleBase: Shape {
    func path(in rect: CGRect) -> Path {
        let topY = rect.minY + rect.height * 0.62
        let bottomY = rect.maxY - rect.height * 0.06
        let topInset = rect.width * 0.32
        let bottomInset = rect.width * 0.22
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + topInset, y: topY))
        path.addLine(to: CGPoint(x: rect.maxX - topInset, y: topY))
        path.addLine(to: CGPoint(x: rect.maxX - bottomInset, y: bottomY))
        path.addLine(to: CGPoint(x: rect.minX + bottomInset, y: bottomY))
        path.closeSubpath()
        return path
    }
}

struct ScaleNeedle: Shape {
    var angleDegrees: Double

    var animatableData: Double {
        get { angleDegrees }
        set { angleDegrees = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.34)
        let radius = Double(rect.height) * 0.24
        let radians = angleDegrees * Double.pi / 180
        let dx = radius * sin(radians)
        let dy = radius * cos(radians)
        let tip = CGPoint(x: center.x + CGFloat(dx), y: center.y - CGFloat(dy))
        var path = Path()
        path.move(to: center)
        path.addLine(to: tip)
        return path
    }
}

struct ScaleFill: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ScaleBase()
                    .stroke(
                        LinearGradient(
                            colors: [theme.color("primary"), theme.color("flowerCenter")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.6
                    )
                ScaleDial()
                    .fill(theme.color("surface"))
                ScaleDial()
                    .stroke(
                        LinearGradient(
                            colors: [theme.color("primary"), theme.color("flowerCenter")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.6
                    )

                ScaleNeedle(angleDegrees: needleAngle)
                    .stroke(theme.color("primaryStrong"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.85), value: fraction)

                // Gold pivot cap over the needle base.
                Circle()
                    .fill(theme.color("flowerCenter"))
                    .frame(width: 7, height: 7)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.34)
            }
        }
        .frame(height: 140)
    }

    private var clampedFraction: Double {
        min(max(fraction, 0), 1)
    }

    private var needleAngle: Double {
        clampedFraction * 130
    }
}
