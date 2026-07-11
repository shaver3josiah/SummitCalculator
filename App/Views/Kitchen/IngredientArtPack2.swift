import SwiftUI

// Pack 2 — dairy, oils, and eggs for the kitchen countertop visualizer.
// Ten normalized SwiftUI illustrations; every coordinate is a fraction of the
// Canvas size, so each scales cleanly 40→120pt with no fixed frames. Pure
// Path/gradient only: no text, SF Symbols, Image assets, or app dependencies.

private enum Pack2Palette {
    static let kraft = Color(red: 0.85, green: 0.74, blue: 0.58)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let labelGreen = Color(red: 0.42, green: 0.56, blue: 0.45)
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.42)
    static let ink = Color(red: 0.33, green: 0.20, blue: 0.16)
    /// The one house outline used everywhere: ink at 0.35 opacity.
    static var outline: Color { ink.opacity(0.35) }
}

/// Standard outline width: 2.8% of the smaller edge, never below 1.2pt.
private func packLine(_ s: CGSize) -> CGFloat { max(1.2, min(s.width, s.height) * 0.028) }

private extension GraphicsContext {
    /// Fill a shape, then trace it with the pack's standard ink outline.
    func solid(_ path: Path, _ color: Color, _ lw: CGFloat) {
        fill(path, with: .color(color))
        stroke(path, with: .color(Pack2Palette.outline), lineWidth: lw)
    }
}

/// White jug: rounded body + short neck, soft-blue cap, and a loop handle at right.
struct MilkArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, lw = packLine(size)
            let softBlue = Color(red: 0.72, green: 0.85, blue: 0.94)
            let body = Path(roundedRect: CGRect(x: w*0.22, y: h*0.30, width: w*0.42, height: h*0.58),
                            cornerRadius: w*0.10)
            ctx.solid(body, .white, lw)
            let neck = Path(roundedRect: CGRect(x: w*0.32, y: h*0.16, width: w*0.20, height: h*0.16),
                            cornerRadius: w*0.03)
            ctx.solid(neck, .white, lw)
            let cap = Path(roundedRect: CGRect(x: w*0.30, y: h*0.10, width: w*0.24, height: h*0.09),
                           cornerRadius: w*0.03)
            ctx.solid(cap, softBlue, lw)
            // Loop handle: dark underlay + white core = a white loop with faint edges.
            var bow = Path()
            bow.move(to: CGPoint(x: w*0.62, y: h*0.40))
            bow.addCurve(to: CGPoint(x: w*0.62, y: h*0.66),
                         control1: CGPoint(x: w*0.90, y: h*0.42),
                         control2: CGPoint(x: w*0.90, y: h*0.64))
            ctx.stroke(bow, with: .color(Pack2Palette.outline), lineWidth: lw*3.2)
            ctx.stroke(bow, with: .color(.white), lineWidth: lw*1.8)
            var sheen = Path()
            sheen.move(to: CGPoint(x: w*0.30, y: h*0.42))
            sheen.addLine(to: CGPoint(x: w*0.30, y: h*0.74))
            ctx.stroke(sheen, with: .color(.white.opacity(0.7)), lineWidth: lw)
        }
    }
}

/// Small dark-amber bottle: squat body, slim neck, near-black cap, blank cream label.
struct VanillaArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, lw = packLine(size)
            let amber = Color(red: 0.55, green: 0.30, blue: 0.12)
            let body = Path(roundedRect: CGRect(x: w*0.30, y: h*0.42, width: w*0.40, height: h*0.44),
                            cornerRadius: w*0.07)
            ctx.solid(body, amber, lw)
            let neck = Path(roundedRect: CGRect(x: w*0.42, y: h*0.26, width: w*0.16, height: h*0.18),
                            cornerRadius: w*0.02)
            ctx.solid(neck, amber, lw)
            let cap = Path(roundedRect: CGRect(x: w*0.40, y: h*0.16, width: w*0.20, height: h*0.12),
                           cornerRadius: w*0.02)
            ctx.solid(cap, Pack2Palette.ink.opacity(0.75), lw)
            let label = Path(roundedRect: CGRect(x: w*0.33, y: h*0.54, width: w*0.34, height: h*0.24),
                             cornerRadius: w*0.03)
            ctx.solid(label, Pack2Palette.cream, lw)
            var sheen = Path()
            sheen.move(to: CGPoint(x: w*0.37, y: h*0.45))
            sheen.addLine(to: CGPoint(x: w*0.37, y: h*0.52))
            ctx.stroke(sheen, with: .color(.white.opacity(0.5)), lineWidth: lw)
        }
    }
}

/// Tall green glass bottle: elongated slim neck, gold cap, blank cream label.
struct OliveOilArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, lw = packLine(size)
            let glass = Color(red: 0.42, green: 0.55, blue: 0.24)
            let body = Path(roundedRect: CGRect(x: w*0.34, y: h*0.44, width: w*0.32, height: h*0.48),
                            cornerRadius: w*0.06)
            ctx.solid(body, glass, lw)
            let neck = Path(roundedRect: CGRect(x: w*0.44, y: h*0.14, width: w*0.12, height: h*0.32),
                            cornerRadius: w*0.02)
            ctx.solid(neck, glass, lw)
            let cap = Path(roundedRect: CGRect(x: w*0.43, y: h*0.07, width: w*0.14, height: h*0.09),
                           cornerRadius: w*0.02)
            ctx.solid(cap, Pack2Palette.gold, lw)
            let label = Path(roundedRect: CGRect(x: w*0.37, y: h*0.60, width: w*0.26, height: h*0.24),
                             cornerRadius: w*0.03)
            ctx.solid(label, Pack2Palette.cream, lw)
            var sheen = Path()
            sheen.move(to: CGPoint(x: w*0.40, y: h*0.48))
            sheen.addLine(to: CGPoint(x: w*0.40, y: h*0.58))
            ctx.stroke(sheen, with: .color(.white.opacity(0.35)), lineWidth: lw)
        }
    }
}

/// Wide pale-yellow plastic bottle: broad body, short neck, warm cap, blank label.
struct VegOilArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, lw = packLine(size)
            let plastic = Color(red: 0.98, green: 0.90, blue: 0.55)
            let body = Path(roundedRect: CGRect(x: w*0.22, y: h*0.34, width: w*0.56, height: h*0.54),
                            cornerRadius: w*0.13)
            ctx.solid(body, plastic, lw)
            let neck = Path(roundedRect: CGRect(x: w*0.42, y: h*0.20, width: w*0.16, height: h*0.16),
                            cornerRadius: w*0.02)
            ctx.solid(neck, plastic, lw)
            let cap = Path(roundedRect: CGRect(x: w*0.40, y: h*0.12, width: w*0.20, height: h*0.11),
                           cornerRadius: w*0.02)
            ctx.solid(cap, Color(red: 0.86, green: 0.55, blue: 0.42), lw)
            let label = Path(roundedRect: CGRect(x: w*0.28, y: h*0.50, width: w*0.44, height: h*0.28),
                             cornerRadius: w*0.04)
            ctx.solid(label, Pack2Palette.cream, lw)
            var sheen = Path()
            sheen.move(to: CGPoint(x: w*0.30, y: h*0.42))
            sheen.addLine(to: CGPoint(x: w*0.30, y: h*0.60))
            ctx.stroke(sheen, with: .color(.white.opacity(0.6)), lineWidth: lw)
        }
    }
}

/// Paper-wrapped butter stick: horizontal wrap, two creases, pale-yellow open end.
struct ButterArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, lw = packLine(size)
            let butter = Color(red: 0.98, green: 0.87, blue: 0.50)
            // Exposed butter end first; the paper wrap overlaps its left side.
            let stub = Path(roundedRect: CGRect(x: w*0.72, y: h*0.36, width: w*0.16, height: h*0.28),
                            cornerRadius: w*0.03)
            ctx.solid(stub, butter, lw)
            let wrap = Path(roundedRect: CGRect(x: w*0.12, y: h*0.34, width: w*0.66, height: h*0.32),
                            cornerRadius: w*0.03)
            ctx.solid(wrap, Pack2Palette.cream, lw)
            for x in [w*0.34, w*0.56] {
                var crease = Path()
                crease.move(to: CGPoint(x: x, y: h*0.34))
                crease.addLine(to: CGPoint(x: x, y: h*0.66))
                ctx.stroke(crease, with: .color(Pack2Palette.outline), lineWidth: lw)
            }
            var sheen = Path()
            sheen.move(to: CGPoint(x: w*0.18, y: h*0.40))
            sheen.addLine(to: CGPoint(x: w*0.30, y: h*0.40))
            ctx.stroke(sheen, with: .color(.white.opacity(0.6)), lineWidth: lw)
        }
    }
}

/// Cheese wedge: chunky left-pointing triangle, a crust seam, and three round holes.
struct CheeseArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, lw = packLine(size)
            let cheese = Color(red: 0.98, green: 0.82, blue: 0.36)
            var wedge = Path()
            wedge.move(to: CGPoint(x: w*0.16, y: h*0.52))
            wedge.addLine(to: CGPoint(x: w*0.84, y: h*0.32))
            wedge.addLine(to: CGPoint(x: w*0.84, y: h*0.74))
            wedge.closeSubpath()
            ctx.solid(wedge, cheese, lw)
            var crust = Path()
            crust.move(to: CGPoint(x: w*0.74, y: h*0.35))
            crust.addLine(to: CGPoint(x: w*0.74, y: h*0.72))
            ctx.stroke(crust, with: .color(Pack2Palette.outline), lineWidth: lw)
            let holes = [CGRect(x: w*0.44, y: h*0.46, width: w*0.10, height: h*0.10),
                         CGRect(x: w*0.60, y: h*0.56, width: w*0.08, height: h*0.08),
                         CGRect(x: w*0.58, y: h*0.40, width: w*0.06, height: h*0.06)]
            for r in holes {
                ctx.solid(Path(ellipseIn: r), Pack2Palette.gold.opacity(0.55), lw)
            }
        }
    }
}

/// Foil brick: silver block crossed by a single green center band.
struct CreamCheeseArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, lw = packLine(size)
            let foil = Color(red: 0.90, green: 0.91, blue: 0.93)
            let brick = Path(roundedRect: CGRect(x: w*0.14, y: h*0.34, width: w*0.72, height: h*0.32),
                             cornerRadius: w*0.05)
            ctx.solid(brick, foil, lw)
            let band = Path(roundedRect: CGRect(x: w*0.14, y: h*0.44, width: w*0.72, height: h*0.12),
                            cornerRadius: w*0.02)
            ctx.solid(band, Pack2Palette.labelGreen, lw)
            var sheen = Path()
            sheen.move(to: CGPoint(x: w*0.22, y: h*0.38))
            sheen.addLine(to: CGPoint(x: w*0.40, y: h*0.38))
            ctx.stroke(sheen, with: .color(.white.opacity(0.8)), lineWidth: lw)
        }
    }
}

/// Squat round tub: gently tapered body under an overhanging green lid rim.
struct SourCreamArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, lw = packLine(size)
            var tub = Path()
            tub.move(to: CGPoint(x: w*0.26, y: h*0.44))
            tub.addLine(to: CGPoint(x: w*0.74, y: h*0.44))
            tub.addLine(to: CGPoint(x: w*0.70, y: h*0.82))
            tub.addLine(to: CGPoint(x: w*0.30, y: h*0.82))
            tub.closeSubpath()
            ctx.solid(tub, Pack2Palette.cream, lw)
            let lid = Path(roundedRect: CGRect(x: w*0.22, y: h*0.32, width: w*0.56, height: h*0.14),
                           cornerRadius: w*0.04)
            ctx.solid(lid, Pack2Palette.labelGreen, lw)
            var sheen = Path()
            sheen.move(to: CGPoint(x: w*0.34, y: h*0.52))
            sheen.addLine(to: CGPoint(x: w*0.34, y: h*0.72))
            ctx.stroke(sheen, with: .color(.white.opacity(0.6)), lineWidth: lw)
        }
    }
}

/// Small gable-top carton: rectangular body, peaked roof with a folded ridge, pink band.
struct HeavyCreamArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, lw = packLine(size)
            let body = Path(roundedRect: CGRect(x: w*0.32, y: h*0.42, width: w*0.36, height: h*0.44),
                            cornerRadius: w*0.02)
            ctx.solid(body, Pack2Palette.cream, lw)
            var gable = Path()
            gable.move(to: CGPoint(x: w*0.32, y: h*0.42))
            gable.addLine(to: CGPoint(x: w*0.50, y: h*0.22))
            gable.addLine(to: CGPoint(x: w*0.68, y: h*0.42))
            gable.closeSubpath()
            ctx.solid(gable, Pack2Palette.cream, lw)
            var ridge = Path()
            ridge.move(to: CGPoint(x: w*0.50, y: h*0.22))
            ridge.addLine(to: CGPoint(x: w*0.50, y: h*0.30))
            ctx.stroke(ridge, with: .color(Pack2Palette.outline), lineWidth: lw)
            let band = Path(roundedRect: CGRect(x: w*0.32, y: h*0.56, width: w*0.36, height: h*0.14),
                            cornerRadius: w*0.02)
            ctx.solid(band, Pack2Palette.labelGreen, lw)
        }
    }
}

/// Single cream egg: a narrow-topped bézier oval with a soft top-left highlight.
struct EggArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, lw = packLine(size)
            let cx = w*0.5, topY = h*0.16, botY = h*0.86, half = w*0.24
            var egg = Path()
            egg.move(to: CGPoint(x: cx, y: topY))
            egg.addCurve(to: CGPoint(x: cx, y: botY),
                         control1: CGPoint(x: cx + half*1.15, y: topY + (botY-topY)*0.02),
                         control2: CGPoint(x: cx + half*1.30, y: botY))
            egg.addCurve(to: CGPoint(x: cx, y: topY),
                         control1: CGPoint(x: cx - half*1.30, y: botY),
                         control2: CGPoint(x: cx - half*1.15, y: topY + (botY-topY)*0.02))
            ctx.solid(egg, Pack2Palette.cream, lw)
            let hi = Path(ellipseIn: CGRect(x: cx - half*0.65, y: topY + (botY-topY)*0.16,
                                            width: half*0.5, height: half*0.7))
            ctx.fill(hi, with: .color(.white.opacity(0.55)))
        }
    }
}
