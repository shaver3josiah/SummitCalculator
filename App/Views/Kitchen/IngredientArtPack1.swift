import SwiftUI

// Pack 1 — pantry staples drawn as "storybook grocery" containers.
// Each struct draws in normalized Canvas space (fractions of `size`) with no
// fixed frames, so the caller (VisualizePanel) can size it anywhere 40→120pt.
// Pure Path/Shape/gradient only: no text, SF Symbols, images, or app deps.

// MARK: - Shared palette + helpers

private enum Pack1Palette {
    static let kraft = Color(red: 0.85, green: 0.74, blue: 0.58)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let labelGreen = Color(red: 0.42, green: 0.56, blue: 0.45)
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.42)
    static let ink = Color(red: 0.33, green: 0.20, blue: 0.16)

    static var stroke: Color { ink.opacity(0.35) }

    /// Outline width: 2.8% of the smaller dimension, floored at 1.2pt.
    static func line(_ s: CGSize) -> CGFloat { max(1.2, min(s.width, s.height) * 0.028) }

    /// Tapered bag body: narrower at `top`, full width at `bottom`, rounded
    /// bottom corners. `halfBottom`/`taper` are width fractions.
    static func bagBody(_ s: CGSize, top: CGFloat, bottom: CGFloat,
                        halfBottom: CGFloat, taper: CGFloat) -> Path {
        let w = s.width
        let midX = w / 2
        let hb = w * halfBottom
        let ht = hb * (1 - taper)
        let c = w * 0.05
        var p = Path()
        p.move(to: CGPoint(x: midX - ht, y: top))
        p.addLine(to: CGPoint(x: midX - hb, y: bottom - c))
        p.addQuadCurve(to: CGPoint(x: midX - hb + c, y: bottom), control: CGPoint(x: midX - hb, y: bottom))
        p.addLine(to: CGPoint(x: midX + hb - c, y: bottom))
        p.addQuadCurve(to: CGPoint(x: midX + hb, y: bottom - c), control: CGPoint(x: midX + hb, y: bottom))
        p.addLine(to: CGPoint(x: midX + ht, y: top))
        p.closeSubpath()
        return p
    }
}

// MARK: - 1. Flour — kraft bag, rolled top, cream label patch

struct FlourArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack1Palette.line(size)
            let body = Pack1Palette.bagBody(size, top: h * 0.24, bottom: h * 0.9, halfBottom: 0.32, taper: 0.18)
            ctx.fill(body, with: .color(Pack1Palette.kraft))
            ctx.stroke(body, with: .color(Pack1Palette.stroke), lineWidth: lw)

            let roll = Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.1, width: w * 0.52, height: h * 0.16),
                            cornerSize: CGSize(width: h * 0.08, height: h * 0.08))
            ctx.fill(roll, with: .color(Pack1Palette.kraft))
            ctx.fill(roll, with: .color(Pack1Palette.ink.opacity(0.08)))
            ctx.stroke(roll, with: .color(Pack1Palette.stroke), lineWidth: lw)
            var seam = Path()
            seam.move(to: CGPoint(x: w * 0.28, y: h * 0.18))
            seam.addLine(to: CGPoint(x: w * 0.72, y: h * 0.18))
            ctx.stroke(seam, with: .color(Pack1Palette.ink.opacity(0.22)), lineWidth: lw * 0.6)

            let label = Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.46, width: w * 0.4, height: h * 0.28),
                             cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(label, with: .color(Pack1Palette.cream))
            ctx.stroke(label, with: .color(Pack1Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold dot
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.47, y: h * 0.5, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack1Palette.gold))
        }
    }
}

// MARK: - 2. Sugar — cream bag, crimped zigzag top, green label

struct SugarArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack1Palette.line(size)
            let body = Pack1Palette.bagBody(size, top: h * 0.22, bottom: h * 0.9, halfBottom: 0.32, taper: 0.14)
            ctx.fill(body, with: .color(Pack1Palette.cream))
            ctx.stroke(body, with: .color(Pack1Palette.stroke), lineWidth: lw)

            // crimped zigzag top band (differs from flour's rolled top)
            let leftX = w * 0.2, rightX = w * 0.8
            let topY = h * 0.08, baseY = h * 0.24, midY = (topY + baseY) / 2
            let teeth = 6
            let segW = (rightX - leftX) / CGFloat(teeth)
            var z = Path()
            z.move(to: CGPoint(x: leftX, y: baseY))
            z.addLine(to: CGPoint(x: leftX, y: midY))
            for i in 0..<teeth {
                let x0 = leftX + segW * CGFloat(i)
                z.addLine(to: CGPoint(x: x0 + segW * 0.5, y: topY))
                z.addLine(to: CGPoint(x: x0 + segW, y: midY))
            }
            z.addLine(to: CGPoint(x: rightX, y: baseY))
            z.closeSubpath()
            ctx.fill(z, with: .color(Pack1Palette.cream))
            ctx.stroke(z, with: .color(Pack1Palette.stroke), lineWidth: lw)

            let label = Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.44, width: w * 0.4, height: h * 0.28),
                             cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(label, with: .color(Pack1Palette.labelGreen))
            ctx.stroke(label, with: .color(Pack1Palette.stroke), lineWidth: lw * 0.8)
            // charm: white sheen line
            var sheen = Path()
            sheen.move(to: CGPoint(x: w * 0.35, y: h * 0.5))
            sheen.addLine(to: CGPoint(x: w * 0.55, y: h * 0.5))
            ctx.stroke(sheen, with: .color(.white.opacity(0.6)), lineWidth: lw * 0.8)
        }
    }
}

// MARK: - 3. Brown sugar — kraft bag, rolled top, deep-brown label band

struct BrownSugarArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack1Palette.line(size)
            let body = Pack1Palette.bagBody(size, top: h * 0.24, bottom: h * 0.9, halfBottom: 0.32, taper: 0.16)
            ctx.fill(body, with: .color(Pack1Palette.kraft))
            ctx.stroke(body, with: .color(Pack1Palette.stroke), lineWidth: lw)

            let roll = Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.1, width: w * 0.52, height: h * 0.16),
                            cornerSize: CGSize(width: h * 0.08, height: h * 0.08))
            ctx.fill(roll, with: .color(Pack1Palette.kraft))
            ctx.fill(roll, with: .color(Pack1Palette.ink.opacity(0.1)))
            ctx.stroke(roll, with: .color(Pack1Palette.stroke), lineWidth: lw)

            // deep-brown band across the body middle (vs flour's cream patch)
            let deepBrown = Color(red: 0.45, green: 0.28, blue: 0.15)
            let band = Path(CGRect(x: w * 0.24, y: h * 0.5, width: w * 0.52, height: h * 0.16))
            ctx.fill(band, with: .color(deepBrown))
            ctx.stroke(band, with: .color(Pack1Palette.stroke), lineWidth: lw * 0.8)
            // charm: gold dot on band
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.47, y: h * 0.535, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack1Palette.gold))
        }
    }
}

// MARK: - 4. Rice — cream bag, folded flap top, window of rice grains

struct RiceArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack1Palette.line(size)
            let body = Pack1Palette.bagBody(size, top: h * 0.22, bottom: h * 0.9, halfBottom: 0.32, taper: 0.14)
            ctx.fill(body, with: .color(Pack1Palette.cream))
            ctx.stroke(body, with: .color(Pack1Palette.stroke), lineWidth: lw)

            let flap = Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.1, width: w * 0.52, height: h * 0.14),
                            cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(flap, with: .color(Pack1Palette.cream))
            ctx.fill(flap, with: .color(Pack1Palette.ink.opacity(0.06)))
            ctx.stroke(flap, with: .color(Pack1Palette.stroke), lineWidth: lw)

            let winP = Path(roundedRect: CGRect(x: w * 0.34, y: h * 0.42, width: w * 0.32, height: h * 0.3),
                            cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(winP, with: .color(Color(red: 0.9, green: 0.94, blue: 0.98)))
            ctx.stroke(winP, with: .color(Pack1Palette.stroke), lineWidth: lw * 0.8)
            // rice grains: tiny ivory ovals
            let grain = Color(red: 0.98, green: 0.97, blue: 0.9)
            let pts: [(CGFloat, CGFloat)] = [(0.4, 0.5), (0.5, 0.48), (0.6, 0.52), (0.44, 0.6), (0.56, 0.62), (0.5, 0.68)]
            for (fx, fy) in pts {
                let g = Path(ellipseIn: CGRect(x: w * fx - w * 0.03, y: h * fy - h * 0.015, width: w * 0.06, height: h * 0.03))
                ctx.fill(g, with: .color(grain))
                ctx.stroke(g, with: .color(Pack1Palette.ink.opacity(0.25)), lineWidth: max(0.6, lw * 0.4))
            }
        }
    }
}

// MARK: - 5. Pasta — tall box, top flap, vertical window of spaghetti

struct PastaArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack1Palette.line(size)
            let box = Path(roundedRect: CGRect(x: w * 0.28, y: h * 0.12, width: w * 0.44, height: h * 0.78),
                           cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(box, with: .color(Pack1Palette.labelGreen.opacity(0.85)))
            ctx.stroke(box, with: .color(Pack1Palette.stroke), lineWidth: lw)

            // thin top-flap band
            ctx.fill(Path(CGRect(x: w * 0.28, y: h * 0.12, width: w * 0.44, height: h * 0.08)),
                     with: .color(Pack1Palette.ink.opacity(0.08)))
            var flapLine = Path()
            flapLine.move(to: CGPoint(x: w * 0.28, y: h * 0.2))
            flapLine.addLine(to: CGPoint(x: w * 0.72, y: h * 0.2))
            ctx.stroke(flapLine, with: .color(Pack1Palette.stroke), lineWidth: lw * 0.7)

            let winP = Path(roundedRect: CGRect(x: w * 0.42, y: h * 0.24, width: w * 0.16, height: h * 0.6),
                            cornerSize: CGSize(width: w * 0.02, height: w * 0.02))
            ctx.fill(winP, with: .color(Pack1Palette.cream))
            ctx.stroke(winP, with: .color(Pack1Palette.stroke), lineWidth: lw * 0.8)
            // charm: spaghetti lines
            for i in 0..<4 {
                let x = w * (0.45 + 0.035 * CGFloat(i))
                var s = Path()
                s.move(to: CGPoint(x: x, y: h * 0.26))
                s.addLine(to: CGPoint(x: x, y: h * 0.82))
                ctx.stroke(s, with: .color(Pack1Palette.gold), lineWidth: max(1, lw * 0.6))
            }
        }
    }
}

// MARK: - 6. Oats — round canister, lid ellipse, label band

struct OatsArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack1Palette.line(size)
            let body = Path(roundedRect: CGRect(x: w * 0.26, y: h * 0.2, width: w * 0.48, height: h * 0.68),
                            cornerSize: CGSize(width: w * 0.06, height: w * 0.06))
            ctx.fill(body, with: .color(Pack1Palette.kraft.opacity(0.9)))
            ctx.stroke(body, with: .color(Pack1Palette.stroke), lineWidth: lw)

            let band = Path(CGRect(x: w * 0.26, y: h * 0.42, width: w * 0.48, height: h * 0.28))
            ctx.fill(band, with: .color(Pack1Palette.cream))
            ctx.stroke(band, with: .color(Pack1Palette.stroke), lineWidth: lw * 0.8)

            let lid = Path(ellipseIn: CGRect(x: w * 0.24, y: h * 0.12, width: w * 0.52, height: h * 0.16))
            ctx.fill(lid, with: .color(Pack1Palette.gold))
            ctx.stroke(lid, with: .color(Pack1Palette.stroke), lineWidth: lw)
            // charm: green dot on band
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.47, y: h * 0.52, width: w * 0.06, height: w * 0.06)),
                     with: .color(Pack1Palette.labelGreen))
        }
    }
}

// MARK: - 7. Chocolate chips — brown bag, folded top, scattered chip dots

struct ChocChipsArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack1Palette.line(size)
            let brown = Color(red: 0.42, green: 0.28, blue: 0.2)
            let body = Pack1Palette.bagBody(size, top: h * 0.22, bottom: h * 0.9, halfBottom: 0.32, taper: 0.14)
            ctx.fill(body, with: .color(brown))
            ctx.stroke(body, with: .color(Pack1Palette.stroke), lineWidth: lw)

            let flap = Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.1, width: w * 0.52, height: h * 0.14),
                            cornerSize: CGSize(width: w * 0.03, height: w * 0.03))
            ctx.fill(flap, with: .color(brown))
            ctx.fill(flap, with: .color(Pack1Palette.ink.opacity(0.15)))
            ctx.stroke(flap, with: .color(Pack1Palette.stroke), lineWidth: lw)

            // charm: scattered chip dots
            let chip = Color(red: 0.28, green: 0.16, blue: 0.1)
            let pts: [(CGFloat, CGFloat)] = [(0.4, 0.4), (0.55, 0.45), (0.46, 0.55), (0.6, 0.6), (0.38, 0.66), (0.54, 0.72)]
            for (fx, fy) in pts {
                let c = Path(ellipseIn: CGRect(x: w * fx - w * 0.035, y: h * fy - w * 0.035, width: w * 0.07, height: w * 0.07))
                ctx.fill(c, with: .color(chip))
            }
        }
    }
}

// MARK: - 8. Baking soda — small orange box, top flap, blank circle badge

struct BakingSodaArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack1Palette.line(size)
            let orange = Color(red: 0.95, green: 0.66, blue: 0.4)
            let box = Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.24, width: w * 0.52, height: h * 0.6),
                           cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(box, with: .color(orange))
            ctx.stroke(box, with: .color(Pack1Palette.stroke), lineWidth: lw)

            // thin top-flap band
            ctx.fill(Path(CGRect(x: w * 0.24, y: h * 0.24, width: w * 0.52, height: h * 0.09)),
                     with: .color(Pack1Palette.ink.opacity(0.1)))
            var line = Path()
            line.move(to: CGPoint(x: w * 0.24, y: h * 0.33))
            line.addLine(to: CGPoint(x: w * 0.76, y: h * 0.33))
            ctx.stroke(line, with: .color(Pack1Palette.stroke), lineWidth: lw * 0.7)

            // blank circle badge (charm)
            let badge = Path(ellipseIn: CGRect(x: w * 0.38, y: h * 0.42, width: w * 0.24, height: w * 0.24))
            ctx.fill(badge, with: .color(Pack1Palette.cream))
            ctx.stroke(badge, with: .color(Pack1Palette.stroke), lineWidth: lw * 0.8)
        }
    }
}

// MARK: - 9. Baking powder — squat tin, lid ellipse, warm label band

struct BakingPowderArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack1Palette.line(size)
            // squat body (wider + shorter than the oats canister)
            let body = Path(roundedRect: CGRect(x: w * 0.2, y: h * 0.34, width: w * 0.6, height: h * 0.5),
                            cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(body, with: .color(Color(red: 0.86, green: 0.8, blue: 0.72)))
            ctx.stroke(body, with: .color(Pack1Palette.stroke), lineWidth: lw)

            let band = Path(CGRect(x: w * 0.2, y: h * 0.48, width: w * 0.6, height: h * 0.24))
            ctx.fill(band, with: .color(Pack1Palette.gold))
            ctx.stroke(band, with: .color(Pack1Palette.stroke), lineWidth: lw * 0.8)

            let lid = Path(ellipseIn: CGRect(x: w * 0.18, y: h * 0.26, width: w * 0.64, height: h * 0.16))
            ctx.fill(lid, with: .color(Color(red: 0.78, green: 0.72, blue: 0.64)))
            ctx.stroke(lid, with: .color(Pack1Palette.stroke), lineWidth: lw)
            // charm: sheen line down the tin
            var sheen = Path()
            sheen.move(to: CGPoint(x: w * 0.28, y: h * 0.4))
            sheen.addLine(to: CGPoint(x: w * 0.28, y: h * 0.8))
            ctx.stroke(sheen, with: .color(.white.opacity(0.4)), lineWidth: lw * 0.8)
        }
    }
}

// MARK: - 10. Yeast — packet with folded corner notch, sprinkle dots

struct YeastArt: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lw = Pack1Palette.line(size)
            let left = w * 0.26, right = w * 0.74, top = h * 0.16, bottom = h * 0.84
            let notch = w * 0.12
            var packet = Path()
            packet.move(to: CGPoint(x: left, y: top))
            packet.addLine(to: CGPoint(x: right - notch, y: top))
            packet.addLine(to: CGPoint(x: right, y: top + notch))
            packet.addLine(to: CGPoint(x: right, y: bottom))
            packet.addLine(to: CGPoint(x: left, y: bottom))
            packet.closeSubpath()
            ctx.fill(packet, with: .color(Pack1Palette.labelGreen.opacity(0.85)))
            ctx.stroke(packet, with: .color(Pack1Palette.stroke), lineWidth: lw)

            // folded corner triangle
            var fold = Path()
            fold.move(to: CGPoint(x: right - notch, y: top))
            fold.addLine(to: CGPoint(x: right - notch, y: top + notch))
            fold.addLine(to: CGPoint(x: right, y: top + notch))
            fold.closeSubpath()
            ctx.fill(fold, with: .color(Pack1Palette.ink.opacity(0.12)))
            ctx.stroke(fold, with: .color(Pack1Palette.stroke), lineWidth: lw * 0.7)

            let label = Path(roundedRect: CGRect(x: w * 0.33, y: h * 0.4, width: w * 0.34, height: h * 0.26),
                             cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(label, with: .color(Pack1Palette.cream))
            ctx.stroke(label, with: .color(Pack1Palette.stroke), lineWidth: lw * 0.8)
            // charm: three fanned sprinkle dots
            for i in 0..<3 {
                ctx.fill(Path(ellipseIn: CGRect(x: w * (0.4 + 0.08 * CGFloat(i)), y: h * 0.5, width: w * 0.04, height: w * 0.04)),
                         with: .color(Pack1Palette.gold))
            }
        }
    }
}
