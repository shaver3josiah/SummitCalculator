import SwiftUI

// Pack 3 — seasonings, meat, and produce drawn as "storybook grocery" art.
// Each struct draws in normalized Canvas space (fractions of `size`) with no
// fixed frames, so the caller (VisualizePanel) can size it anywhere 40→120pt.
// Pure Path/Shape/gradient only: no text, SF Symbols, images, or app deps.

// MARK: - Shared palette + helpers

private enum Pack3Palette {
    static let kraft = Color(red: 0.85, green: 0.74, blue: 0.58)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let labelGreen = Color(red: 0.42, green: 0.56, blue: 0.45)
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.42)
    static let ink = Color(red: 0.33, green: 0.20, blue: 0.16)

    static var stroke: Color { ink.opacity(0.35) }

    /// Outline width: 2.8% of the smaller dimension, floored at 1.2pt.
    static func line(_ s: CGSize) -> CGFloat { max(1.2, min(s.width, s.height) * 0.028) }
}

// MARK: - 1. Salt — shaker: rounded body, domed cap with 3 hole dots

struct SaltArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack3Palette.line(size)
            let sk = Pack3Palette.stroke

            let body = Path(roundedRect: CGRect(x: w * 0.30, y: h * 0.34, width: w * 0.40, height: h * 0.52),
                            cornerSize: CGSize(width: w * 0.12, height: w * 0.12))
            ctx.fill(body, with: .color(Pack3Palette.cream))
            ctx.stroke(body, with: .color(sk), lineWidth: lw)

            // domed cap over the body top
            var cap = Path()
            cap.move(to: CGPoint(x: w * 0.28, y: h * 0.36))
            cap.addLine(to: CGPoint(x: w * 0.28, y: h * 0.28))
            cap.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.28), control: CGPoint(x: w * 0.50, y: h * 0.12))
            cap.addLine(to: CGPoint(x: w * 0.72, y: h * 0.36))
            cap.closeSubpath()
            ctx.fill(cap, with: .color(Pack3Palette.labelGreen))
            ctx.stroke(cap, with: .color(sk), lineWidth: lw)

            // 3 hole dots on the dome
            let holes: [CGFloat] = [0.42, 0.50, 0.58]
            let d = w * 0.05
            for fx in holes {
                ctx.fill(Path(ellipseIn: CGRect(x: w * fx - d / 2, y: h * 0.24, width: d, height: d)),
                         with: .color(Pack3Palette.ink.opacity(0.7)))
            }
            // charm: soft body highlight
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.36, y: h * 0.44, width: w * 0.07, height: h * 0.24)),
                     with: .color(.white.opacity(0.35)))
        }
    }
}

// MARK: - 2. Pepper — mill: waisted silhouette + cap knob (vs salt's shaker)

struct PepperArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack3Palette.line(size)
            let sk = Pack3Palette.stroke
            let wood = Color(red: 0.62, green: 0.44, blue: 0.30)

            // waisted body: shoulder wide, pinched waist, flared base
            var body = Path()
            body.move(to: CGPoint(x: w * 0.50, y: h * 0.20))
            body.addQuadCurve(to: CGPoint(x: w * 0.68, y: h * 0.32), control: CGPoint(x: w * 0.66, y: h * 0.22))
            body.addQuadCurve(to: CGPoint(x: w * 0.60, y: h * 0.55), control: CGPoint(x: w * 0.68, y: h * 0.44))
            body.addQuadCurve(to: CGPoint(x: w * 0.70, y: h * 0.86), control: CGPoint(x: w * 0.58, y: h * 0.72))
            body.addLine(to: CGPoint(x: w * 0.70, y: h * 0.90))
            body.addLine(to: CGPoint(x: w * 0.30, y: h * 0.90))
            body.addLine(to: CGPoint(x: w * 0.30, y: h * 0.86))
            body.addQuadCurve(to: CGPoint(x: w * 0.40, y: h * 0.55), control: CGPoint(x: w * 0.42, y: h * 0.72))
            body.addQuadCurve(to: CGPoint(x: w * 0.32, y: h * 0.32), control: CGPoint(x: w * 0.32, y: h * 0.44))
            body.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.20), control: CGPoint(x: w * 0.34, y: h * 0.22))
            body.closeSubpath()
            ctx.fill(body, with: .color(wood))
            ctx.stroke(body, with: .color(sk), lineWidth: lw)

            // cap knob
            let knob = Path(ellipseIn: CGRect(x: w * 0.44, y: h * 0.06, width: w * 0.12, height: w * 0.12))
            ctx.fill(knob, with: .color(wood))
            ctx.stroke(knob, with: .color(sk), lineWidth: lw)

            // grinder-head seam across the shoulder
            var seam = Path()
            seam.move(to: CGPoint(x: w * 0.34, y: h * 0.34))
            seam.addQuadCurve(to: CGPoint(x: w * 0.66, y: h * 0.34), control: CGPoint(x: w * 0.50, y: h * 0.37))
            ctx.stroke(seam, with: .color(sk), lineWidth: lw * 0.8)
            // charm: sheen line
            var sheen = Path()
            sheen.move(to: CGPoint(x: w * 0.40, y: h * 0.40))
            sheen.addLine(to: CGPoint(x: w * 0.40, y: h * 0.82))
            ctx.stroke(sheen, with: .color(.white.opacity(0.35)), lineWidth: lw * 0.8)
        }
    }
}

// MARK: - 3. Cocoa — squat brown tin with a lighter ellipse lid

struct CocoaArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack3Palette.line(size)
            let sk = Pack3Palette.stroke
            let brown = Color(red: 0.42, green: 0.28, blue: 0.20)
            let lidBrown = Color(red: 0.60, green: 0.45, blue: 0.34)

            let body = Path(roundedRect: CGRect(x: w * 0.22, y: h * 0.40, width: w * 0.56, height: h * 0.44),
                            cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(body, with: .color(brown))
            ctx.stroke(body, with: .color(sk), lineWidth: lw)

            let lid = Path(ellipseIn: CGRect(x: w * 0.20, y: h * 0.30, width: w * 0.60, height: h * 0.18))
            ctx.fill(lid, with: .color(lidBrown))
            ctx.stroke(lid, with: .color(sk), lineWidth: lw)

            // charm: green label band
            let label = Path(roundedRect: CGRect(x: w * 0.22, y: h * 0.54, width: w * 0.56, height: h * 0.16),
                             cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(label, with: .color(Pack3Palette.labelGreen))
            ctx.stroke(label, with: .color(sk), lineWidth: lw * 0.8)
        }
    }
}

// MARK: - 4. Cinnamon — two crossed rolled sticks with curl lines

struct CinnamonArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let m = min(w, h)
            let lw = Pack3Palette.line(size)
            let sk = Pack3Palette.stroke
            let cinnamon = Color(red: 0.60, green: 0.36, blue: 0.22)

            func stick(_ angle: CGFloat) {
                var c = ctx
                c.translateBy(x: w * 0.5, y: h * 0.5)
                c.rotate(by: .degrees(angle))
                let L = m * 0.74, T = m * 0.20
                let path = Path(roundedRect: CGRect(x: -L / 2, y: -T / 2, width: L, height: T),
                                cornerSize: CGSize(width: T / 2, height: T / 2))
                c.fill(path, with: .color(cinnamon))
                c.stroke(path, with: .color(sk), lineWidth: lw)
                // lengthwise curl line
                var curl = Path()
                curl.move(to: CGPoint(x: -L / 2 + T * 0.6, y: -T * 0.06))
                curl.addLine(to: CGPoint(x: L / 2 - T * 0.6, y: -T * 0.06))
                c.stroke(curl, with: .color(sk), lineWidth: lw * 0.7)
                // rolled-bark curl at one end
                var roll = Path()
                roll.move(to: CGPoint(x: L / 2 - T * 0.65, y: -T / 2))
                roll.addQuadCurve(to: CGPoint(x: L / 2 - T * 0.65, y: T / 2), control: CGPoint(x: L / 2 - T * 1.25, y: 0))
                c.stroke(roll, with: .color(sk), lineWidth: lw * 0.7)
            }
            stick(-24)
            stick(24)
        }
    }
}

// MARK: - 5. Chicken — drumstick: meat teardrop + knobbed bone

struct ChickenArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let m = min(w, h)
            let lw = Pack3Palette.line(size)
            let sk = Pack3Palette.stroke
            let cooked = Color(red: 0.87, green: 0.67, blue: 0.46)
            let bone = Pack3Palette.cream

            // meat teardrop, narrow tip toward the bone
            var meat = Path()
            meat.move(to: CGPoint(x: w * 0.60, y: h * 0.58))
            meat.addQuadCurve(to: CGPoint(x: w * 0.22, y: h * 0.46), control: CGPoint(x: w * 0.30, y: h * 0.66))
            meat.addQuadCurve(to: CGPoint(x: w * 0.30, y: h * 0.18), control: CGPoint(x: w * 0.16, y: h * 0.26))
            meat.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.26), control: CGPoint(x: w * 0.46, y: h * 0.12))
            meat.addQuadCurve(to: CGPoint(x: w * 0.60, y: h * 0.58), control: CGPoint(x: w * 0.66, y: h * 0.40))
            meat.closeSubpath()
            ctx.fill(meat, with: .color(cooked))
            ctx.stroke(meat, with: .color(sk), lineWidth: lw)

            // bone: rotated capsule with two knobs at the far end
            var c = ctx
            c.translateBy(x: w * 0.56, y: h * 0.54)
            c.rotate(by: .degrees(35))
            let L = m * 0.30, T = m * 0.10
            let shaft = Path(roundedRect: CGRect(x: 0, y: -T / 2, width: L, height: T),
                             cornerSize: CGSize(width: T / 2, height: T / 2))
            c.fill(shaft, with: .color(bone))
            c.stroke(shaft, with: .color(sk), lineWidth: lw)
            let r = T * 0.75
            for dy: CGFloat in [-T * 0.7, T * 0.7] {
                let knob = Path(ellipseIn: CGRect(x: L - r, y: dy - r, width: 2 * r, height: 2 * r))
                c.fill(knob, with: .color(bone))
                c.stroke(knob, with: .color(sk), lineWidth: lw)
            }
            // charm: highlight on the meat
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.30, y: h * 0.24, width: w * 0.12, height: h * 0.09)),
                     with: .color(.white.opacity(0.4)))
        }
    }
}

// MARK: - 6. Beef — shallow tray with a pink mince mound + film sheen

struct BeefArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack3Palette.line(size)
            let sk = Pack3Palette.stroke
            let trayColor = Color(red: 0.93, green: 0.92, blue: 0.90)
            let mince = Color(red: 0.86, green: 0.52, blue: 0.54)
            let minceDark = Color(red: 0.74, green: 0.40, blue: 0.44)

            let tray = Path(roundedRect: CGRect(x: w * 0.14, y: h * 0.52, width: w * 0.72, height: h * 0.30),
                            cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(tray, with: .color(trayColor))
            ctx.stroke(tray, with: .color(sk), lineWidth: lw)
            let rim = Path(roundedRect: CGRect(x: w * 0.18, y: h * 0.56, width: w * 0.64, height: h * 0.22),
                           cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.stroke(rim, with: .color(sk), lineWidth: lw * 0.7)

            // bumpy mince mound seated in the tray
            var mound = Path()
            mound.move(to: CGPoint(x: w * 0.20, y: h * 0.58))
            mound.addQuadCurve(to: CGPoint(x: w * 0.40, y: h * 0.54), control: CGPoint(x: w * 0.28, y: h * 0.34))
            mound.addQuadCurve(to: CGPoint(x: w * 0.60, y: h * 0.54), control: CGPoint(x: w * 0.50, y: h * 0.32))
            mound.addQuadCurve(to: CGPoint(x: w * 0.80, y: h * 0.58), control: CGPoint(x: w * 0.72, y: h * 0.34))
            mound.addLine(to: CGPoint(x: w * 0.20, y: h * 0.58))
            mound.closeSubpath()
            ctx.fill(mound, with: .color(mince))
            ctx.stroke(mound, with: .color(sk), lineWidth: lw)

            let dots: [(CGFloat, CGFloat)] = [(0.34, 0.48), (0.50, 0.46), (0.62, 0.49), (0.44, 0.52), (0.56, 0.53)]
            let dd = w * 0.045
            for (fx, fy) in dots {
                ctx.fill(Path(ellipseIn: CGRect(x: w * fx - dd / 2, y: h * fy - dd / 2, width: dd, height: dd)),
                         with: .color(minceDark))
            }
            // charm: film-sheen line
            var sheen = Path()
            sheen.move(to: CGPoint(x: w * 0.28, y: h * 0.40))
            sheen.addLine(to: CGPoint(x: w * 0.48, y: h * 0.52))
            ctx.stroke(sheen, with: .color(.white.opacity(0.55)), lineWidth: lw * 0.9)
        }
    }
}

// MARK: - 7. Tomato — red body with a green star calyx

struct TomatoArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let m = min(w, h)
            let lw = Pack3Palette.line(size)
            let sk = Pack3Palette.stroke
            let red = Color(red: 0.90, green: 0.36, blue: 0.30)
            let leaf = Color(red: 0.45, green: 0.66, blue: 0.36)

            let body = Path(ellipseIn: CGRect(x: w * 0.18, y: h * 0.30, width: w * 0.64, height: h * 0.56))
            ctx.fill(body, with: .color(red))
            ctx.stroke(body, with: .color(sk), lineWidth: lw)

            // stem nub behind the star
            let stem = Path(roundedRect: CGRect(x: w * 0.47, y: h * 0.14, width: w * 0.06, height: h * 0.10),
                            cornerSize: CGSize(width: w * 0.02, height: w * 0.02))
            ctx.fill(stem, with: .color(Color(red: 0.40, green: 0.56, blue: 0.30)))
            ctx.stroke(stem, with: .color(sk), lineWidth: lw * 0.7)

            // 5-point star calyx (unit coords, outer-tip up)
            let unit: [(CGFloat, CGFloat)] = [
                (0, -1), (0.235, -0.323), (0.951, -0.309), (0.380, 0.124), (0.588, 0.809),
                (0, 0.4), (-0.588, 0.809), (-0.380, 0.124), (-0.951, -0.309), (-0.235, -0.323)
            ]
            let R = m * 0.15
            let cxp = w * 0.50, cyp = h * 0.31
            var star = Path()
            for (i, p) in unit.enumerated() {
                let q = CGPoint(x: cxp + p.0 * R, y: cyp + p.1 * R)
                if i == 0 { star.move(to: q) } else { star.addLine(to: q) }
            }
            star.closeSubpath()
            ctx.fill(star, with: .color(leaf))
            ctx.stroke(star, with: .color(sk), lineWidth: lw * 0.8)

            // charm: glossy highlight
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.30, y: h * 0.42, width: w * 0.14, height: h * 0.10)),
                     with: .color(.white.opacity(0.4)))
        }
    }
}

// MARK: - 8. Onion — golden bulb, segment curves, root whiskers

struct OnionArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack3Palette.line(size)
            let sk = Pack3Palette.stroke
            let golden = Color(red: 0.92, green: 0.78, blue: 0.50)

            var onion = Path()
            onion.move(to: CGPoint(x: w * 0.50, y: h * 0.16))
            onion.addQuadCurve(to: CGPoint(x: w * 0.80, y: h * 0.56), control: CGPoint(x: w * 0.64, y: h * 0.24))
            onion.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.86), control: CGPoint(x: w * 0.82, y: h * 0.80))
            onion.addQuadCurve(to: CGPoint(x: w * 0.20, y: h * 0.56), control: CGPoint(x: w * 0.18, y: h * 0.80))
            onion.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.16), control: CGPoint(x: w * 0.36, y: h * 0.24))
            onion.closeSubpath()
            ctx.fill(onion, with: .color(golden))
            ctx.stroke(onion, with: .color(sk), lineWidth: lw)

            // vertical segment curves
            var seg1 = Path()
            seg1.move(to: CGPoint(x: w * 0.44, y: h * 0.22))
            seg1.addQuadCurve(to: CGPoint(x: w * 0.42, y: h * 0.82), control: CGPoint(x: w * 0.30, y: h * 0.52))
            ctx.stroke(seg1, with: .color(sk), lineWidth: lw * 0.7)
            var seg2 = Path()
            seg2.move(to: CGPoint(x: w * 0.56, y: h * 0.22))
            seg2.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.82), control: CGPoint(x: w * 0.70, y: h * 0.52))
            ctx.stroke(seg2, with: .color(sk), lineWidth: lw * 0.7)

            // papery top tip
            var tip = Path()
            tip.move(to: CGPoint(x: w * 0.50, y: h * 0.18))
            tip.addLine(to: CGPoint(x: w * 0.45, y: h * 0.06))
            tip.addLine(to: CGPoint(x: w * 0.55, y: h * 0.09))
            tip.closeSubpath()
            ctx.fill(tip, with: .color(Pack3Palette.kraft))
            ctx.stroke(tip, with: .color(sk), lineWidth: lw * 0.7)

            // charm: root whiskers
            let roots: [(CGFloat, CGFloat)] = [(0.46, 0.44), (0.50, 0.50), (0.54, 0.56)]
            for (fx1, fx2) in roots {
                var wk = Path()
                wk.move(to: CGPoint(x: w * fx1, y: h * 0.85))
                wk.addLine(to: CGPoint(x: w * fx2, y: h * 0.93))
                ctx.stroke(wk, with: .color(sk), lineWidth: lw * 0.7)
            }
        }
    }
}

// MARK: - 9. Garlic — white bulb, clove ridge curves, top nub

struct GarlicArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack3Palette.line(size)
            let sk = Pack3Palette.stroke
            let bulbWhite = Color(red: 0.96, green: 0.94, blue: 0.90)

            var bulb = Path()
            bulb.move(to: CGPoint(x: w * 0.50, y: h * 0.22))
            bulb.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.54), control: CGPoint(x: w * 0.66, y: h * 0.26))
            bulb.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.86), control: CGPoint(x: w * 0.80, y: h * 0.82))
            bulb.addQuadCurve(to: CGPoint(x: w * 0.22, y: h * 0.54), control: CGPoint(x: w * 0.20, y: h * 0.82))
            bulb.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.22), control: CGPoint(x: w * 0.34, y: h * 0.26))
            bulb.closeSubpath()
            ctx.fill(bulb, with: .color(bulbWhite))
            ctx.stroke(bulb, with: .color(sk), lineWidth: lw)

            // clove ridge curves fanning from the top
            var r1 = Path()
            r1.move(to: CGPoint(x: w * 0.50, y: h * 0.24))
            r1.addQuadCurve(to: CGPoint(x: w * 0.36, y: h * 0.84), control: CGPoint(x: w * 0.34, y: h * 0.52))
            ctx.stroke(r1, with: .color(sk), lineWidth: lw * 0.7)
            var r2 = Path()
            r2.move(to: CGPoint(x: w * 0.50, y: h * 0.24))
            r2.addQuadCurve(to: CGPoint(x: w * 0.64, y: h * 0.84), control: CGPoint(x: w * 0.66, y: h * 0.52))
            ctx.stroke(r2, with: .color(sk), lineWidth: lw * 0.7)

            // charm: top nub
            let nub = Path(roundedRect: CGRect(x: w * 0.45, y: h * 0.13, width: w * 0.10, height: h * 0.11),
                           cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(nub, with: .color(Pack3Palette.kraft))
            ctx.stroke(nub, with: .color(sk), lineWidth: lw * 0.7)
        }
    }
}

// MARK: - 10. Lemon — pointed-end body with a leaf

struct LemonArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack3Palette.line(size)
            let sk = Pack3Palette.stroke
            let yellow = Color(red: 0.98, green: 0.85, blue: 0.35)
            let leaf = Color(red: 0.45, green: 0.66, blue: 0.36)

            // body: two pointed ends left/right
            var lemon = Path()
            lemon.move(to: CGPoint(x: w * 0.16, y: h * 0.56))
            lemon.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.30), control: CGPoint(x: w * 0.26, y: h * 0.30))
            lemon.addQuadCurve(to: CGPoint(x: w * 0.84, y: h * 0.56), control: CGPoint(x: w * 0.74, y: h * 0.30))
            lemon.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.82), control: CGPoint(x: w * 0.74, y: h * 0.82))
            lemon.addQuadCurve(to: CGPoint(x: w * 0.16, y: h * 0.56), control: CGPoint(x: w * 0.26, y: h * 0.82))
            lemon.closeSubpath()
            ctx.fill(lemon, with: .color(yellow))
            ctx.stroke(lemon, with: .color(sk), lineWidth: lw)

            // leaf at the top-right
            var lf = Path()
            lf.move(to: CGPoint(x: w * 0.56, y: h * 0.32))
            lf.addQuadCurve(to: CGPoint(x: w * 0.80, y: h * 0.16), control: CGPoint(x: w * 0.60, y: h * 0.14))
            lf.addQuadCurve(to: CGPoint(x: w * 0.56, y: h * 0.32), control: CGPoint(x: w * 0.80, y: h * 0.30))
            lf.closeSubpath()
            ctx.fill(lf, with: .color(leaf))
            ctx.stroke(lf, with: .color(sk), lineWidth: lw * 0.8)
            var rib = Path()
            rib.move(to: CGPoint(x: w * 0.59, y: h * 0.29))
            rib.addQuadCurve(to: CGPoint(x: w * 0.76, y: h * 0.19), control: CGPoint(x: w * 0.70, y: h * 0.26))
            ctx.stroke(rib, with: .color(sk), lineWidth: lw * 0.6)

            // charm: glossy highlight
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.28, y: h * 0.44, width: w * 0.14, height: h * 0.10)),
                     with: .color(.white.opacity(0.4)))
        }
    }
}
