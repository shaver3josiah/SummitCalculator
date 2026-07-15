import SwiftUI
import SummitCore
import UIKit
import ImageIO   // re-exported by UIKit; explicit for the downsampling APIs below

struct VisualizePanel: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var store
    @Environment(ListsStore.self) private var lists
    @Environment(SoundStore.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var rawText = ""
    @State private var scale: Double = 1.0
    @State private var customScale = ""
    @State private var useCustom = false
    @State private var parsed: [ParsedIngredient] = []
    @State private var failed: [String] = []
    @State private var placements: [Placement] = []
    @FocusState private var textFocused: Bool

    @State private var addedFlash = false   // "Added!" confirmation pulse on the shopping-list button
    @State private var flashGeneration = 0   // invalidates a pending flash reset when re-tapped
    @State private var addBurst = 0          // fires a leaf burst from the button

    // Pinch-zoom / pan state for the countertop. `*Base` hold the value committed
    // at the end of the last gesture so the next one composes on top of it.
    @State private var zoom: CGFloat = 1
    @State private var zoomBase: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var panBase: CGSize = .zero

    private static let counterHeight: CGFloat = 300

    private static let artNames: Set<String> = [
        "croissant", "cupcake", "honeypot", "hotbev", "shortcake", "teacup"
    ]

    /// Volume / weight / vague-portion measures. Everything measured in one of
    /// these is *bulk* (one labeled graphic); units NOT in this set — nil or a
    /// discrete-portion word like "clove"/"slice" — are *countable*.
    private static let measureUnits: Set<String> = [
        "tsp", "tbsp", "cup", "oz", "fl oz", "lb", "g", "kg", "mL", "L",
        "pinch", "can", "pkg", "stick"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Paste recipe text", text: $rawText, prompt: Text("Paste recipe text").foregroundStyle(theme.color("muted")), axis: .vertical)
                .font(summitBody(14))
                .foregroundStyle(theme.color("text"))
                .lineLimit(4...8)
                .focused($textFocused)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))

            scalePicker

            Button {
                parseText()
            } label: {
                Text("Visualize")
                    .font(summitBody(14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("primaryStrong")))
                    .foregroundStyle(.white)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            finishPicker
            countertop

            if !parsed.isEmpty || !failed.isEmpty {
                Button {
                    addAllToList()   // plays the success sound
                    flashAdded()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: addedFlash ? "checkmark.circle.fill" : "cart.badge.plus")
                        Text(addedFlash ? "Added!" : "Add to shopping list")
                    }
                    .font(summitBody(13, weight: .semibold))
                    .foregroundStyle(addedFlash ? .white : theme.color("primaryStrong"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule().fill(addedFlash ? theme.color("primaryStrong") : theme.color("surfaceSoft"))
                    )
                    .scaleEffect(addedFlash ? 1.05 : 1.0)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .overlay {
                    if theme.leavesOn {
                        LeafBurstView(trigger: addBurst, originX: 0.5, originY: 0.5)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
        .onChange(of: scale) { _, _ in placements = buildPlacements() }
    }

    // MARK: - Scale picker

    private var scalePicker: some View {
        HStack(spacing: 10) {
            ForEach([0.5, 1.0, 2.0], id: \.self) { value in
                Button {
                    useCustom = false
                    scale = value
                } label: {
                    Text(scaleLabel(value))
                        .font(summitBody(13, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 999)
                                .fill(!useCustom && scale == value ? theme.color("primaryStrong") : theme.color("surfaceSoft"))
                        )
                        .foregroundStyle(!useCustom && scale == value ? .white : theme.color("text"))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            TextField("custom", text: $customScale, prompt: Text("custom").foregroundStyle(theme.color("muted")))
                .keyboardType(.decimalPad)
                .font(summitBody(13))
                .foregroundStyle(theme.color("text"))
                .frame(width: 56)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.color("surfaceSoft")))
                .onChange(of: customScale) { _, newValue in
                    if let v = Double(newValue), v > 0 {
                        useCustom = true
                        scale = v
                    }
                }
        }
    }

    private func scaleLabel(_ value: Double) -> String {
        value == 0.5 ? "0.5x" : value == 1.0 ? "1x" : "2x"
    }

    // MARK: - Finish picker

    private var finishPicker: some View {
        HStack(spacing: 8) {
            finishChip(.marble, "Marble")
            finishChip(.wood, "Wood")
            Spacer()
        }
    }

    private func finishChip(_ finish: CounterFinish, _ label: String) -> some View {
        let active = store.counterFinish == finish
        return Button {
            store.counterFinish = finish
            sound.play("tap1")
        } label: {
            Text(label)
                .font(summitBody(12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(active ? theme.color("primaryStrong") : theme.color("surfaceSoft")))
                .foregroundStyle(active ? .white : theme.color("text"))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Countertop (surface + mise en place + zoom)

    private var countertop: some View {
        GeometryReader { geo in
            ZStack {
                CounterFinishView(finish: store.counterFinish, veinTint: theme.color("deep"))
                // Clean-polished glint: marble only (wood is satin — a travelling
                // specular band would misread its finish). Gated + reduce-motion safe.
                if store.counterFinish == .marble && theme.shimmerOn && !reduceMotion {
                    CounterShimmer(grainAngle: CounterFinishView.grainAngle)
                }
                if placements.isEmpty {
                    Text("Paste a recipe and tap Visualize to set the counter.")
                        .font(summitBody(12))
                        .foregroundStyle(theme.color("muted"))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 220)
                } else {
                    miseView(placements, in: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            // scaleEffect + offset are visual-only; the trailing fixed .frame
            // re-establishes the container box so .clipShape crops the zoomed
            // content to the counter rather than letting it spill into the page.
            .scaleEffect(zoom, anchor: .center)
            .offset(pan)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(theme.color("line"), lineWidth: 1)
            )
            // Pinch never conflicts with the outer ScrollView (two fingers).
            .gesture(magnifyGesture(size: geo.size))
            // ponytail: pan drag is disabled at zoom 1 (mask .subviews) so the
            // one-finger scroll of the page wins; it only claims the touch once
            // zoomed in. Cleanest way to not fight the out-of-scope ScrollView.
            .highPriorityGesture(panGesture(size: geo.size), including: zoom > 1 ? .all : .subviews)
            .onTapGesture(count: 2) { resetZoom() }
        }
        // Grow the counter on iPad (regular width) so it doesn't read as a thin
        // band in the wide column; phones (compact) keep the 300pt height.
        .frame(height: hSize == .regular ? 380 : Self.counterHeight)
    }

    private func miseView(_ items: [Placement], in size: CGSize) -> some View {
        let cols = max(1, min(items.count, Int(size.width / 96)))
        let rows = max(1, Int((Double(items.count) / Double(cols)).rounded(.up)))
        let cellW = size.width / CGFloat(cols)
        let cellH = min((size.height - 20) / CGFloat(rows), 120)
        let contentH = cellH * CGFloat(rows)
        let topInset = max(14, (size.height - contentH) / 2)
        let artBase = min(max(min(cellW, cellH) * 0.42, 24), 46)

        return ZStack {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let col = index % cols
                let row = index / cols
                let j = jitter(index)
                placementView(item, artSize: artBase, rotation: j.rot)
                    .position(
                        x: cellW * (CGFloat(col) + 0.5) + j.x,
                        y: topInset + cellH * (CGFloat(row) + 0.5) + j.y
                    )
            }
        }
    }

    /// Seeded hand-placed jitter for a mise-en-place item: ±4pt offset, ±6°
    /// rotation. Seeded by index so items never shuffle between renders.
    private func jitter(_ index: Int) -> (x: CGFloat, y: CGFloat, rot: Double) {
        var rng = SeededGenerator(seed: index &* 2999 &+ 17)
        return (
            CGFloat(Double.random(in: -4...4, using: &rng)),
            CGFloat(Double.random(in: -4...4, using: &rng)),
            Double.random(in: -6...6, using: &rng)
        )
    }

    private func placementView(_ item: Placement, artSize: CGFloat, rotation: Double) -> some View {
        VStack(spacing: 4) {
            clusterView(item, base: artSize)
                .rotationEffect(.degrees(rotation))
            captionView(item)
        }
    }

    /// One graphic per copy, arranged in a compact pile (≤12 drawn), with a
    /// "×N" badge when the real count runs past the 12-copy display cap.
    private func clusterView(_ item: Placement, base: CGFloat) -> some View {
        let display = min(item.count, 12)
        let per = display <= 3 ? display : Int(Double(display).squareRoot().rounded(.up))
        let rowCount = max(1, Int((Double(display) / Double(max(1, per))).rounded(.up)))
        let copySize = display <= 1 ? base : max(16, base * (display <= 4 ? 0.66 : 0.5))

        return VStack(spacing: 1) {
            ForEach(0..<rowCount, id: \.self) { r in
                HStack(spacing: 1) {
                    ForEach(0..<max(1, per), id: \.self) { c in
                        let k = r * per + c
                        if k < display {
                            artUnit(art: item.art, glyph: item.glyph, artKey: item.artKey, size: copySize)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if item.count > 12 {
                Text("×\(item.count)")
                    .font(summitBody(9, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(theme.color("primaryStrong")))
                    .foregroundStyle(.white)
                    .offset(x: 6, y: -4)
            }
        }
    }

    private func captionView(_ item: Placement) -> some View {
        VStack(spacing: 0) {
            Text(item.name)
                .font(summitBody(11, weight: .semibold))
                .foregroundStyle(theme.color("text"))
                .lineLimit(1)
            if !item.qtyLabel.isEmpty {
                Text(item.qtyLabel)
                    .font(summitBody(10))
                    .foregroundStyle(theme.color("deep"))
                    .lineLimit(1)
            }
        }
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.75)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .frame(maxWidth: 104)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.color("surface").opacity(0.86))
        )
        .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1)
    }

    @ViewBuilder
    private func artUnit(art: AnyView?, glyph: String, artKey: String?, size: CGFloat) -> some View {
        if let art {
            // Registry art fills the same square the PNG/emoji would occupy.
            art.frame(width: size, height: size)
        } else if let key = artKey, Self.artNames.contains(key), let uiImage = Self.loadArt(key) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Text(glyph)
                .font(.system(size: size))
        }
    }

    // MARK: - Zoom / pan gestures

    private func magnifyGesture(size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = min(max(zoomBase * value.magnification, 1), 3)
                pan = clampPan(pan, size: size)
            }
            .onEnded { _ in
                // Snap to exactly 1 below a perceptible epsilon: the pan mask engages
                // on `zoom > 1`, so a pinch left resting at e.g. 1.005 would silently
                // steal one-finger scrolls from the outer ScrollView forever.
                if zoom <= 1.02 {
                    zoom = 1
                    zoomBase = 1
                    pan = .zero
                    panBase = .zero
                } else {
                    zoomBase = zoom
                    panBase = pan
                }
            }
    }

    private func panGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard zoom > 1 else { return }
                let raw = CGSize(
                    width: panBase.width + value.translation.width,
                    height: panBase.height + value.translation.height
                )
                pan = clampPan(raw, size: size)
            }
            .onEnded { _ in panBase = pan }
    }

    /// Keep the scaled content from being dragged fully off the counter. With a
    /// centered scaleEffect the content overhangs by (zoom-1)*dimension/2 a side.
    private func clampPan(_ p: CGSize, size: CGSize) -> CGSize {
        let maxX = (zoom - 1) * size.width / 2
        let maxY = (zoom - 1) * size.height / 2
        return CGSize(
            width: min(max(p.width, -maxX), maxX),
            height: min(max(p.height, -maxY), maxY)
        )
    }

    private func resetZoom() {
        if theme.motionEnabled && !reduceMotion {
            withAnimation(SummitMotion.springSoft) {
                zoom = 1; zoomBase = 1; pan = .zero; panBase = .zero
            }
        } else {
            zoom = 1; zoomBase = 1; pan = .zero; panBase = .zero
        }
    }

    // MARK: - Placement building

    private struct Placement: Identifiable {
        let id: Int
        let glyph: String
        let artKey: String?
        /// Registry art resolved by ingredient/food name; wins over PNG + glyph.
        let art: AnyView?
        let name: String
        let qtyLabel: String
        let count: Int
    }

    private func buildPlacements() -> [Placement] {
        var out: [Placement] = []
        var idx = 0
        for ing in parsed {
            let scaled = RecipeParse.scale(ing, by: scale)
            let food = FoodLibrary.match(ing.name)
            // Registry first: matched Food name, then the raw parsed name (so
            // "flour" still hits when FoodLibrary missed). Falls through to nil.
            let art = food.flatMap { IngredientArt.view(for: $0.name) }
                ?? IngredientArt.view(for: ing.name)
            out.append(Placement(
                id: idx,
                glyph: food?.glyph ?? "🥣",
                artKey: food?.artKey,
                art: art,
                name: food?.name ?? scaled.name.capitalized,
                qtyLabel: scaledLabel(scaled),
                count: Self.copyCount(for: scaled)
            ))
            idx += 1
        }
        for line in failed {
            out.append(Placement(
                id: idx,
                glyph: "🧺",
                artKey: nil,
                art: nil,
                name: line.capitalized,
                qtyLabel: "as written",
                count: 1
            ))
            idx += 1
        }
        return out
    }

    /// Countability rule for the mise-en-place counter.
    ///
    /// Returns how many copies of an ingredient's graphic to lay on the counter.
    /// An ingredient is *countable* — one graphic per unit — when it denotes a
    /// discrete whole thing: a whole-ish quantity ≥ 1 whose unit is either absent
    /// ("2 eggs") or a discrete-portion word ("3 cloves", "2 slices"), and NOT a
    /// volume/weight measure. Anything measured in a cup, spoon, or on a scale
    /// (cups, tsp, tbsp, grams, mL, pinches, cans, packages, sticks) is *bulk*
    /// and returns 1: two flour piles would misread as "2 cups", so bulk shows a
    /// single labeled graphic instead. Non-whole quantities (1½) are treated as
    /// bulk too. The returned count is uncapped; the view draws at most 12 copies
    /// and badges any remainder as "×N".
    private static func copyCount(for ing: ParsedIngredient) -> Int {
        guard let qty = ing.qty, qty >= 0.5 else { return 1 }
        if let unit = ing.unit, measureUnits.contains(unit) { return 1 }
        // Only duplicate near-whole counts; 1.5 eggs → a single labeled graphic.
        guard abs(qty - qty.rounded()) <= 0.2 else { return 1 }
        return max(1, Int(qty.rounded()))
    }

    private func scaledLabel(_ ing: ParsedIngredient) -> String {
        guard let qty = ing.qty else { return ing.unit ?? "" }
        let qtyText = RecipeParse.fmtQty(qty)
        guard let unit = ing.unit else { return qtyText }
        return "\(qtyText) \(unit)"
    }

    // MARK: - Art loading

    /// Bounded, self-evicting cache of downsampled FoodArt. `countLimit` caps the
    /// entry count and `totalCostLimit` caps decoded bytes (cost = pixel bytes);
    /// NSCache also evicts on its own under memory pressure, unlike the old
    /// unbounded `[String: UIImage]` that never released.
    private static let artCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 24
        cache.totalCostLimit = 8 * 1024 * 1024   // ~8 MB of decoded pixels
        return cache
    }()

    /// Thumbnail ceiling. On-screen art is ≤ 46pt (see `miseView`/`clusterView`);
    /// even a 64pt slot at 3x is 192px, so 192 is oversharp for every device and
    /// the decoded backing never exceeds what's drawn.
    private static let artMaxPixel: CGFloat = 192

    /// One-time memory-warning registration. A static-let initializer runs the
    /// first time it's referenced (from `loadArt`), so `_ = registersPurge` wires
    /// the purge handler up exactly once for the app's lifetime. Belt-and-braces
    /// over NSCache's own under-pressure eviction.
    private static let registersPurge: Void = {
        MemoryPressure.onWarning { artCache.removeAllObjects() }
    }()

    private static func loadArt(_ key: String) -> UIImage? {
        _ = registersPurge   // force the one-time purge registration
        let nsKey = key as NSString
        if let cached = artCache.object(forKey: nsKey) {
            return cached
        }
        guard let resolved = resolveArt(key) else {
            return nil
        }
        // Cost in decoded bytes: pixel count (points × scale²) × 4 (RGBA8).
        let pxW = resolved.size.width * resolved.scale
        let pxH = resolved.size.height * resolved.scale
        artCache.setObject(resolved, forKey: nsKey, cost: Int(pxW * pxH) * 4)
        return resolved
    }

    private static func resolveArt(_ key: String) -> UIImage? {
        // Same keys and same subdirectory search order as before; only the decode
        // changed (ImageIO downsample instead of a full-size UIImage(data:)).
        let subdirectories = ["FoodArt/png", "Resources/FoodArt/png"]
        for subdirectory in subdirectories {
            if let url = Bundle.main.url(forResource: key, withExtension: "png", subdirectory: subdirectory),
               let image = downsampledImage(at: url) {
                return image
            }
        }
        if let url = Bundle.main.url(forResource: key, withExtension: "png"),
           let image = downsampledImage(at: url) {
            return image
        }
        // Asset-catalog fallback LAST: can't be downsampled here, but catalog art
        // is already delivered at the device-appropriate size.
        return UIImage(named: key)
    }

    /// Decode straight to a ≤`artMaxPixel` thumbnail via ImageIO so the backing
    /// bitmap is created at draw size, never the full source resolution.
    private static func downsampledImage(at url: URL) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: artMaxPixel,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        // scale 1.0 matches the old UIImage(data:) path; the view already sizes it
        // with .resizable().scaledToFit() into a ≤46pt frame, so rendering is identical.
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Actions

    private func parseText() {
        textFocused = false
        let lines = rawText.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        var good: [ParsedIngredient] = []
        var bad: [String] = []
        for line in lines {
            if let ing = RecipeParse.parseLine(line) {
                good.append(ing)
            } else {
                bad.append(line)
            }
        }
        parsed = good
        failed = bad
        placements = buildPlacements()
        resetZoom()
        sound.play("tap1")
        theme.triggerCurtain()
    }

    private func addAllToList() {
        for ing in parsed {
            let scaled = RecipeParse.scale(ing, by: scale)
            let rawQty = scaled.qty ?? 1
            let roundedQty = (rawQty * 100).rounded() / 100
            let displayName = foldedIngredientName(scaled)
            lists.addIngredient(name: displayName, qty: roundedQty)
        }
        for line in failed {
            lists.addIngredient(name: line, qty: 1)
        }
        sound.play("success")
    }

    /// Confirmation flourish for the shopping-list button: a spring pop to "Added!"
    /// plus a leaf burst, settling back after ~1.4s. Respects the motion gates.
    private func flashAdded() {
        addBurst += 1   // LeafBurstView is gated on leavesOn at the call site
        flashGeneration += 1
        let expected = flashGeneration
        if theme.motionEnabled && !reduceMotion {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { addedFlash = true }
        } else {
            addedFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            guard flashGeneration == expected else { return }
            if theme.motionEnabled && !reduceMotion {
                withAnimation(.easeOut(duration: 0.3)) { addedFlash = false }
            } else {
                addedFlash = false
            }
        }
    }

    private func foldedIngredientName(_ ing: ParsedIngredient) -> String {
        guard let unit = ing.unit else {
            return ing.name
        }
        return "\(ing.name) (\(unit))"
    }
}

// MARK: - Procedural counter finishes

/// Static, seeded procedural counter surfaces drawn with a single Canvas each.
/// Seeds are fixed constants so veins/planks/knots never shift between renders.
private struct CounterFinishView: View {
    let finish: CounterFinish
    /// Theme "deep" tone, mixed in a hint into the vein ink so the stone quietly
    /// echoes the active palette. Marble only; wood ignores it.
    var veinTint: Color = Color(red: 0.40, green: 0.20, blue: 0.30)

    /// Diagonal grain shared by the veins and the specular shimmer, so the stone
    /// and the light that slides over it read as one material.
    static let grainAngle: Double = 20   // degrees; veins descend left→right

    var body: some View {
        Canvas { context, size in
            switch finish {
            case .marble: Self.drawMarble(context, size, tint: veinTint)
            case .wood: Self.drawWood(context, size)
            }
        }
    }

    // MARK: Marble (Carrara-style: warm-white base, soft clouds, diagonal veins)

    private static func drawMarble(_ ctx: GraphicsContext, _ size: CGSize, tint: Color) {
        let w = size.width, h = size.height
        let full = Path(CGRect(origin: .zero, size: size))

        // 1. Barely-warm near-white base.
        ctx.fill(full, with: .color(Color(red: 0.975, green: 0.969, blue: 0.958)))

        // 2. Big soft tonal clouds so the slab isn't flat — three low-opacity gray
        //    radial washes; the fade-to-clear gives a blurred blob for free.
        for c in 0..<3 {
            var rng = SeededGenerator(seed: c &* 7331 &+ 41)
            let cx = w * CGFloat(Double.random(in: 0.1...0.9, using: &rng))
            let cy = h * CGFloat(Double.random(in: 0.1...0.9, using: &rng))
            let r = max(w, h) * CGFloat(Double.random(in: 0.45...0.75, using: &rng))
            let gray = Double.random(in: 0.60...0.72, using: &rng)
            let blob = Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
            ctx.fill(blob, with: .radialGradient(
                Gradient(colors: [Color(white: gray).opacity(0.06), Color(white: gray).opacity(0)]),
                center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: r
            ))
        }

        // Vein ink: cool gray carrying a hint of the theme's deep tone.
        let ink = blend(Color(red: 0.34, green: 0.36, blue: 0.40), tint, 0.22)
        let slope = CGFloat(tan(grainAngle * .pi / 180))

        // 3. Two primary veins on the shared grain, each a soft wide underlay + a
        //    crisp darker core, plus one short tapering tributary that fades out.
        for v in 0..<2 {
            var rng = SeededGenerator(seed: v &* 9173 &+ 211)
            let y0 = h * CGFloat(Double.random(in: 0.30...0.70, using: &rng))
            let pts = veinPoints(w: w, h: h, y0: y0, slope: slope, rng: &rng)
            let path = smoothPath(pts)
            ctx.stroke(path, with: .color(ink.opacity(0.10)), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
            ctx.stroke(path, with: .color(ink.opacity(0.20)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            drawBranch(ctx, from: pts, slope: slope, ink: ink, rng: &rng)
        }

        // 4. Faint hairline veins parallel-ish to the grain, very low opacity.
        for f in 0..<4 {
            var rng = SeededGenerator(seed: f &* 4909 &+ 83)
            let y0 = h * CGFloat(Double.random(in: 0.12...0.88, using: &rng))
            let pts = veinPoints(w: w, h: h, y0: y0, slope: slope, rng: &rng)
            ctx.stroke(smoothPath(pts), with: .color(ink.opacity(0.06)), style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
        }

        // 5. A couple of tiny speckle clusters.
        for s in 0..<2 {
            var rng = SeededGenerator(seed: s &* 6607 &+ 29)
            let bx = w * CGFloat(Double.random(in: 0.2...0.8, using: &rng))
            let by = h * CGFloat(Double.random(in: 0.2...0.8, using: &rng))
            for _ in 0..<7 {
                let dx = CGFloat(Double.random(in: -10...10, using: &rng))
                let dy = CGFloat(Double.random(in: -10...10, using: &rng))
                let d = CGFloat(Double.random(in: 0.6...1.6, using: &rng))
                ctx.fill(Path(ellipseIn: CGRect(x: bx + dx, y: by + dy, width: d, height: d)),
                         with: .color(ink.opacity(0.14)))
            }
        }

        // 6. Faint static top-leading sheen for baseline depth. The live "clean"
        //    glint is the animated CounterShimmer layered on top when motion is on.
        ctx.fill(full, with: .linearGradient(
            Gradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0)]),
            startPoint: .zero, endPoint: CGPoint(x: w * 0.6, y: h * 0.7)
        ))
    }

    /// Points for one vein: a straight baseline on the grain plus a single gentle
    /// low-frequency sine bow (seeded phase/amplitude). One slow wave — never a
    /// zigzag — so `smoothPath` renders it as geology, not a scribble.
    private static func veinPoints(w: CGFloat, h: CGFloat, y0: CGFloat, slope: CGFloat, rng: inout SeededGenerator) -> [CGPoint] {
        let margin: CGFloat = 24
        let n = 8
        let phase = Double.random(in: 0...(.pi * 2), using: &rng)
        let waves = Double.random(in: 0.8...1.6, using: &rng)   // < 2 gentle bows across
        let amp = h * CGFloat(Double.random(in: 0.03...0.06, using: &rng))
        var pts: [CGPoint] = []
        for i in 0...n {
            let t = Double(i) / Double(n)
            let x = -margin + CGFloat(t) * (w + margin * 2)
            let baseY = y0 + (x - w / 2) * slope
            let wander = amp * CGFloat(sin(phase + t * waves * .pi * 2))
            pts.append(CGPoint(x: x, y: baseY + wander))
        }
        return pts
    }

    /// Chained quad curves through midpoints (C1-smooth) — no sharp corners even
    /// if the input points jitter.
    private static func smoothPath(_ pts: [CGPoint]) -> Path {
        var path = Path()
        guard let first = pts.first else { return path }
        path.move(to: first)
        guard pts.count >= 3 else {
            for p in pts.dropFirst() { path.addLine(to: p) }
            return path
        }
        for i in 1..<(pts.count - 1) {
            let mid = CGPoint(x: (pts[i].x + pts[i + 1].x) / 2, y: (pts[i].y + pts[i + 1].y) / 2)
            path.addQuadCurve(to: mid, control: pts[i])
        }
        path.addLine(to: pts[pts.count - 1])
        return path
    }

    /// Short tributary forking off a vein at a shallow angle, drawn as three
    /// successive segments with decreasing opacity + width so it tapers away.
    private static func drawBranch(_ ctx: GraphicsContext, from pts: [CGPoint], slope: CGFloat, ink: Color, rng: inout SeededGenerator) {
        guard pts.count > 3 else { return }
        let start = pts[Int.random(in: 2...(pts.count - 2), using: &rng)]
        let kick = CGFloat(Double.random(in: -0.35...0.35, using: &rng))   // shallow angular offset from the grain
        let dir = CGVector(dx: 1, dy: slope + kick)
        let len = hypot(dir.dx, dir.dy)
        let ux = dir.dx / len, uy = dir.dy / len
        let step = CGFloat(Double.random(in: 26...40, using: &rng))
        let opacities: [Double] = [0.16, 0.10, 0.05]
        let widths: [CGFloat] = [1.1, 0.8, 0.5]
        var p = start
        for k in 0..<3 {
            let next = CGPoint(x: p.x + ux * step, y: p.y + uy * step)
            var seg = Path()
            seg.move(to: p)
            let ctrl = CGPoint(x: (p.x + next.x) / 2, y: (p.y + next.y) / 2 - step * 0.12)
            seg.addQuadCurve(to: next, control: ctrl)
            ctx.stroke(seg, with: .color(ink.opacity(opacities[k])), style: StrokeStyle(lineWidth: widths[k], lineCap: .round))
            p = next
        }
    }

    /// Linear RGB blend of two Colors (t = 0 → a, 1 → b).
    private static func blend(_ a: Color, _ b: Color, _ t: CGFloat) -> Color {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(a).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(b).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t, blue: b1 + (b2 - b1) * t)
    }

    private static func drawWood(_ ctx: GraphicsContext, _ size: CGSize) {
        let bands = 5
        let bandH = size.height / CGFloat(bands)
        let toneA = Color(red: 0.56, green: 0.40, blue: 0.24)
        let toneB = Color(red: 0.50, green: 0.35, blue: 0.20)
        let seam = Color(red: 0.30, green: 0.19, blue: 0.10).opacity(0.5)

        for b in 0..<bands {
            let rect = CGRect(x: 0, y: CGFloat(b) * bandH, width: size.width, height: bandH)
            ctx.fill(Path(rect), with: .color(b % 2 == 0 ? toneA : toneB))
            if b > 0 {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: CGFloat(b) * bandH))
                line.addLine(to: CGPoint(x: size.width, y: CGFloat(b) * bandH))
                ctx.stroke(line, with: .color(seam), lineWidth: 1.5)
            }
        }

        // A couple of seeded knots at low opacity.
        for k in 0..<2 {
            var rng = SeededGenerator(seed: k &* 5407 &+ 61)
            let kx = size.width * CGFloat(Double.random(in: 0.2...0.8, using: &rng))
            let ky = size.height * CGFloat(Double.random(in: 0.15...0.85, using: &rng))
            let rw = CGFloat(Double.random(in: 10...18, using: &rng))
            let rh = rw * 0.7
            let ring = Path(ellipseIn: CGRect(x: kx - rw, y: ky - rh, width: rw * 2, height: rh * 2))
            ctx.stroke(ring, with: .color(Color(red: 0.28, green: 0.17, blue: 0.09).opacity(0.35)), lineWidth: 2)
            let core = Path(ellipseIn: CGRect(x: kx - rw * 0.5, y: ky - rh * 0.5, width: rw, height: rh))
            ctx.fill(core, with: .color(Color(red: 0.30, green: 0.19, blue: 0.10).opacity(0.18)))
        }

        // Gentle top sheen.
        let sheen = Gradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0)])
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            sheen,
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: size.height * 0.5)
        ))
    }
}

/// Slow specular band that glides once across the polished marble (~1.5s) then
/// rests off-slab for the rest of a ~6.5s loop — the counter-scale echo of
/// AmbientShimmer's glint-then-rest philosophy. Transform-only: a single animated
/// `.offset` on a static gradient (no TimelineView, no Canvas, no per-frame body
/// re-eval). Mount is gated to marble + `shimmerOn && !reduceMotion` at the call
/// site; the band is narrow versus its travel, so the loop reset lands off-slab
/// and never reads as a continuous strobe.
private struct CounterShimmer: View {
    var grainAngle: Double
    var cornerRadius: CGFloat = 20
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white.opacity(0.04), location: 0.42),
                    .init(color: .white.opacity(0.12), location: 0.5),
                    .init(color: .white.opacity(0.04), location: 0.58),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.42)
            .rotationEffect(.degrees(grainAngle))
            // Travel ~6w against a 0.42w band → on the stone only ~1/4 of the loop.
            .offset(x: (-1.3 + phase * 6) * geo.size.width)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 6.5).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}
