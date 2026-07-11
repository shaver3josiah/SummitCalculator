import SwiftUI

struct ParticleSpec {
    var seedTime: Double
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var rotation: Double
    var rotationSpeed: Double
    var size: Double
    var colorIndex: Int
    var lifetime: Double
}

private func makeSparkle(index: Int, baseTime: Double) -> ParticleSpec {
    var rng = SeededGenerator(seed: index &* 7919 &+ 13)
    return ParticleSpec(
        seedTime: baseTime + Double.random(in: 0...2.4, using: &rng),
        x: Double.random(in: 0...1, using: &rng),
        y: Double.random(in: 0.16...0.84, using: &rng),
        vx: Double.random(in: -0.35...0.35, using: &rng),
        vy: Double.random(in: -1.1...(-0.3), using: &rng),
        rotation: Double.random(in: 0...360, using: &rng),
        rotationSpeed: Double.random(in: -170...170, using: &rng),
        size: Double.random(in: 6...15, using: &rng),
        colorIndex: index,
        lifetime: Double.random(in: 1.3...2.5, using: &rng)
    )
}

private func timeSeed(_ baseTime: Double) -> Int {
    // Fold the spawn time into the seed so no two bursts match (spec: "never the exact same twice").
    Int(baseTime.truncatingRemainder(dividingBy: 100_000) * 1000)
}

private func makeLeaf(index: Int, baseTime: Double, originX: Double, originY: Double) -> ParticleSpec {
    var rng = SeededGenerator(seed: index &* 4451 &+ timeSeed(baseTime))
    let angle = Double(index) / 24.0 * 2 * .pi + Double.random(in: -0.35...0.35, using: &rng)
    return ParticleSpec(
        seedTime: baseTime,
        x: originX,
        y: originY,
        vx: cos(angle) * Double.random(in: 0.5...1.1, using: &rng),
        vy: sin(angle) * Double.random(in: 0.5...1.1, using: &rng),
        rotation: Double.random(in: 0...360, using: &rng),
        rotationSpeed: Double.random(in: -220...220, using: &rng),
        size: Double.random(in: 8...16, using: &rng),
        colorIndex: index,
        lifetime: Double.random(in: 0.95...1.65, using: &rng)
    )
}

private func makeSummitLeaf(index: Int, baseTime: Double) -> ParticleSpec {
    var rng = SeededGenerator(seed: index &* 3307 &+ timeSeed(baseTime))
    let spread = Double.random(in: -0.42...0.42, using: &rng)
    return ParticleSpec(
        seedTime: baseTime + Double.random(in: 0...0.12, using: &rng),
        x: 0.5 + spread * 0.5,
        y: 0.62,
        vx: spread + Double.random(in: -0.15...0.15, using: &rng),
        vy: -Double.random(in: 0.55...1.0, using: &rng),   // upward — rises out from behind the card
        rotation: Double.random(in: 0...360, using: &rng),
        rotationSpeed: Double.random(in: -120...120, using: &rng),
        size: Double.random(in: 9...16, using: &rng),
        colorIndex: index,
        lifetime: Double.random(in: 1.1...1.7, using: &rng)
    )
}

private func makeCurtainLeaf(index: Int, baseTime: Double) -> ParticleSpec {
    var rng = SeededGenerator(seed: index &* 6151 &+ timeSeed(baseTime))
    return ParticleSpec(
        seedTime: baseTime + Double.random(in: 0...0.35, using: &rng),
        x: Double.random(in: 0.04...0.96, using: &rng),
        y: 0,
        vx: 0,
        vy: 0,
        rotation: Double.random(in: 0...(2 * .pi), using: &rng),   // used as sway phase
        rotationSpeed: Double.random(in: -35...35, using: &rng),   // barely spins
        size: Double.random(in: 9...16, using: &rng),
        colorIndex: index,
        lifetime: Double.random(in: 1.25...1.95, using: &rng)
    )
}

/// Mostly ridge-colored with the occasional amber leaf (~14%).
private func leafToken(_ index: Int) -> String {
    if index % 7 == 0 { return "flowerCenter" }
    return index % 2 == 0 ? "primary" : "primaryStrong"
}

private func makeRainDrop(index: Int, baseTime: Double) -> ParticleSpec {
    var rng = SeededGenerator(seed: index &* 2609 &+ 5)
    return ParticleSpec(
        seedTime: baseTime - Double.random(in: 0...5, using: &rng),
        x: Double.random(in: 0...1, using: &rng),
        y: 0,
        vx: 0,
        vy: 0,
        rotation: Double.random(in: 0...360, using: &rng),
        rotationSpeed: Double.random(in: -55...55, using: &rng),
        size: Double.random(in: 10...19, using: &rng),
        colorIndex: index,
        lifetime: Double.random(in: 3.6...6.2, using: &rng)
    )
}

private func drawLeaf(_ ctx: inout GraphicsContext, spec: ParticleSpec, x: Double, y: Double, rotationDeg: Double, alpha: Double, color: Color) {
    var layer = ctx
    layer.opacity = alpha
    layer.translateBy(x: x, y: y)
    layer.rotate(by: .degrees(rotationDeg))
    // Pointed-tip leaf (was Bloom's petal ellipse): two quad curves meeting at
    // the tip and stem, like a birch or willow leaf drifting down.
    let h = spec.size
    let w = spec.size * 0.44
    var leaf = Path()
    leaf.move(to: CGPoint(x: 0, y: -h / 2))
    leaf.addQuadCurve(to: CGPoint(x: 0, y: h / 2), control: CGPoint(x: w, y: 0))
    leaf.addQuadCurve(to: CGPoint(x: 0, y: -h / 2), control: CGPoint(x: -w, y: 0))
    leaf.closeSubpath()
    layer.fill(leaf, with: .color(color))
}

struct SparkleFieldView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let colorTokens: [String]

    private static let poolSize = 24
    @State private var pool: [ParticleSpec] = []
    @State private var baseTime: Double = 0

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            TimelineView(.animation) { context in
                Canvas { ctx, size in
                    let now = context.date.timeIntervalSinceReferenceDate
                    for spec in pool {
                        let cycle = spec.lifetime + 0.6
                        let elapsed = (now - spec.seedTime).truncatingRemainder(dividingBy: cycle)
                        guard elapsed >= 0, elapsed < spec.lifetime else { continue }
                        let t = elapsed / spec.lifetime
                        let px = spec.x * size.width + spec.vx * elapsed * 60
                        let py = spec.y * size.height + spec.vy * elapsed * 60
                        let alpha = 1.0 - t
                        let rot = spec.rotation + spec.rotationSpeed * elapsed
                        let token = colorTokens[spec.colorIndex % max(colorTokens.count, 1)]
                        drawLeaf(&ctx, spec: spec, x: px, y: py, rotationDeg: rot, alpha: alpha, color: theme.color(token))
                    }
                }
            }
            .onAppear(perform: seed)
        }
    }

    private func seed() {
        guard pool.isEmpty else { return }
        let now = Date.timeIntervalSinceReferenceDate
        baseTime = now
        pool = (0..<Self.poolSize).map { makeSparkle(index: $0, baseTime: now) }
    }
}

/// Celebration burst — fires only on `trigger` change, not on appear.
/// The timeline is paused whenever no leaves are alive: an always-running
/// `TimelineView(.animation)` redraws its Canvas every frame forever, and with
/// several mounted at once that main-thread churn made taps feel sticky.
struct LeafBurstView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let trigger: Int
    let originX: Double
    let originY: Double

    private static let count = 24
    private static let maxAge: Double = 1.8   // longest lifetime + margin
    @State private var pool: [ParticleSpec] = []
    @State private var active = false
    @State private var generation = 0

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            TimelineView(.animation(minimumInterval: nil, paused: !active)) { context in
                Canvas { ctx, size in
                    let now = context.date.timeIntervalSinceReferenceDate
                    for spec in pool {
                        let age = now - spec.seedTime
                        guard age >= 0, age < spec.lifetime else { continue }
                        let t = age / spec.lifetime
                        let ease = 1 - pow(1 - t, 2)
                        let px = spec.x * size.width + spec.vx * ease * 140
                        let py = spec.y * size.height + spec.vy * ease * 140 + 60 * t * t
                        let alpha = 1.0 - t
                        let rot = spec.rotation + spec.rotationSpeed * age
                        drawLeaf(&ctx, spec: spec, x: px, y: py, rotationDeg: rot, alpha: alpha, color: theme.color(leafToken(spec.colorIndex)))
                    }
                }
            }
            .onChange(of: trigger) { _, _ in spawnBurst() }
        }
    }

    private func spawnBurst() {
        guard trigger > 0 else { return }
        let now = Date.timeIntervalSinceReferenceDate
        pool = (0..<Self.count).map { makeLeaf(index: $0, baseTime: now, originX: originX, originY: originY) }
        wake()
    }

    /// Run the timeline only while leaves live; a newer burst extends the window.
    private func wake() {
        active = true
        generation += 1
        let expected = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.maxAge) {
            if generation == expected { active = false }
        }
    }
}

/// Result summit — leaves rise up out from behind the display when a calc lands.
/// Placed behind the display card so they only peek out around its edges.
struct ResultSummitView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let trigger: Int

    private static let count = 12
    private static let maxAge: Double = 2.0   // seed offset + longest lifetime
    @State private var pool: [ParticleSpec] = []
    @State private var active = false
    @State private var generation = 0

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            TimelineView(.animation(minimumInterval: nil, paused: !active)) { context in
                Canvas { ctx, size in
                    let now = context.date.timeIntervalSinceReferenceDate
                    for spec in pool {
                        let age = now - spec.seedTime
                        guard age >= 0, age < spec.lifetime else { continue }
                        let t = age / spec.lifetime
                        let glide = 1 - pow(1 - t, 3)   // expo-out, matches the glide token
                        let px = spec.x * size.width + spec.vx * glide * 120
                        let py = spec.y * size.height + spec.vy * glide * 170
                        let alpha = (1 - t) * 0.9
                        let rot = spec.rotation + spec.rotationSpeed * age
                        drawLeaf(&ctx, spec: spec, x: px, y: py, rotationDeg: rot, alpha: alpha, color: theme.color(leafToken(spec.colorIndex)))
                    }
                }
            }
            .onChange(of: trigger) { _, _ in spawn() }
        }
    }

    private func spawn() {
        guard trigger > 0 else { return }
        let now = Date.timeIntervalSinceReferenceDate
        pool = (0..<Self.count).map { makeSummitLeaf(index: $0, baseTime: now) }
        active = true
        generation += 1
        let expected = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.maxAge) {
            if generation == expected { active = false }
        }
    }
}

/// Soft leaf curtain that drifts down over the seam on a mode change.
/// One-shot per `trigger` change; leaves sway on an S-path and barely spin.
struct LeafCurtainView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let trigger: Int

    private static let count = 16
    private static let maxAge: Double = 2.5   // 0.35 stagger + 1.95 lifetime + margin
    @State private var pool: [ParticleSpec] = []
    @State private var active = false
    @State private var generation = 0

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            TimelineView(.animation(minimumInterval: nil, paused: !active)) { context in
                Canvas { ctx, size in
                    let now = context.date.timeIntervalSinceReferenceDate
                    for spec in pool {
                        let age = now - spec.seedTime
                        guard age >= 0, age < spec.lifetime else { continue }
                        let t = age / spec.lifetime
                        let px = spec.x * size.width + sin(t * .pi * 2 + spec.rotation) * 22
                        let py = -30 + t * (size.height + 60)
                        let alpha = sin(t * .pi) * 0.7   // fade in, then out
                        let rot = spec.rotation * 57 + spec.rotationSpeed * age
                        drawLeaf(&ctx, spec: spec, x: px, y: py, rotationDeg: rot, alpha: alpha, color: theme.color(leafToken(spec.colorIndex)))
                    }
                }
            }
            .onChange(of: trigger) { _, _ in spawn() }
        }
    }

    private func spawn() {
        let now = Date.timeIntervalSinceReferenceDate
        pool = (0..<Self.count).map { makeCurtainLeaf(index: $0, baseTime: now) }
        active = true
        generation += 1
        let expected = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.maxAge) {
            if generation == expected { active = false }
        }
    }
}

struct LeafRainView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let count = 22
    @State private var pool: [ParticleSpec] = []

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            TimelineView(.animation) { context in
                Canvas { ctx, size in
                    let now = context.date.timeIntervalSinceReferenceDate
                    for spec in pool {
                        let elapsed = (now - spec.seedTime).truncatingRemainder(dividingBy: spec.lifetime)
                        let clamped = elapsed < 0 ? elapsed + spec.lifetime : elapsed
                        let t = clamped / spec.lifetime
                        let px = spec.x * size.width + sin(t * 6 + spec.rotation) * 18
                        let py = t * (size.height + 40) - 20
                        let rot = spec.rotation + spec.rotationSpeed * clamped
                        let token = ["primary", "primaryStrong"][spec.colorIndex % 2]
                        drawLeaf(&ctx, spec: spec, x: px, y: py, rotationDeg: rot, alpha: 0.85, color: theme.color(token))
                    }
                }
            }
            .onAppear(perform: seed)
        }
    }

    private func seed() {
        guard pool.isEmpty else { return }
        let now = Date.timeIntervalSinceReferenceDate
        pool = (0..<Self.count).map { makeRainDrop(index: $0, baseTime: now) }
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
