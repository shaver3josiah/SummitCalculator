import SwiftUI
import SummitCore

struct ConvertPanel: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var store
    @Environment(SoundStore.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var swapSpin: Double = 0
    @State private var illustrationBounce = false

    // Pinch-zoom state for the big illustration. zoomBaseScale/panBase carry the
    // committed value between gestures; zoomScale/panOffset are the live values.
    @State private var zoomScale: CGFloat = 1.0
    @State private var zoomBaseScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var panBase: CGSize = .zero

    private static let maxGlyphs = 16
    private static let cupGlyphHeight: CGFloat = 50
    private static let spoonGlyphHeight: CGFloat = 46
    private static let glyphColumns = [GridItem(.adaptive(minimum: 44, maximum: 56), spacing: 10)]
    private static let countableUnits: Set<String> = ["tsp", "tbsp", "cup"]

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amount")
                        .font(summitBody(12))
                        .foregroundStyle(theme.color("muted"))
                    TextField("1", value: amountBinding, format: .number, prompt: Text("1").foregroundStyle(theme.color("muted")))
                        .keyboardType(.decimalPad)
                        .font(summitNumber(18))
                        .foregroundStyle(theme.color("text"))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.color("surface"))
                        )
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(summitBody(12))
                        .foregroundStyle(theme.color("muted"))
                    Picker("From", selection: fromBinding) {
                        unitOptions
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                swapButton
                VStack(alignment: .leading, spacing: 4) {
                    Text("To")
                        .font(summitBody(12))
                        .foregroundStyle(theme.color("muted"))
                    Picker("To", selection: toBinding) {
                        unitOptions
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
            .frame(maxWidth: 520)   // keep the amount + pickers from stretching stringy on iPad

            convertIllustration
                .padding(.horizontal, 20)
                .scaleEffect(illustrationBounce ? 0.94 : 1.0)
                .animation(.spring(response: 0.32, dampingFraction: 0.55), value: illustrationBounce)
                .scaleEffect(zoomScale)
                .offset(panOffset)
                .clipped()
                .contentShape(Rectangle())
                .gesture(magnifyGesture)
                // Pan only while zoomed, so at rest the drag neither eats the
                // single-tap nor fights KitchenView's ScrollView.
                .simultaneousGesture(panGesture, including: zoomScale > 1.01 ? .all : .subviews)
                .onTapGesture(count: 2) { resetZoom() }
                .onTapGesture {
                    sound.play("tap1")
                    guard theme.motionEnabled && !reduceMotion else { return }
                    illustrationBounce = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        illustrationBounce = false
                    }
                }

            resultCard

            Text("Conversions stay within a family, volume to volume and weight to weight.")
                .font(summitBody(11))
                .foregroundStyle(theme.color("muted"))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surface"))
        )
    }

    // MARK: Pinch-zoom

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoomScale = min(max(zoomBaseScale * value.magnification, 1.0), 3.0)
            }
            .onEnded { _ in
                if zoomScale <= 1.01 {
                    resetZoom()
                } else {
                    zoomBaseScale = zoomScale
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                panOffset = CGSize(
                    width: panBase.width + value.translation.width,
                    height: panBase.height + value.translation.height
                )
            }
            .onEnded { _ in panBase = panOffset }
    }

    private func resetZoom() {
        if reduceMotion || !theme.motionEnabled {
            zoomScale = 1.0
            panOffset = .zero
        } else {
            withAnimation(SummitMotion.springSoft) {
                zoomScale = 1.0
                panOffset = .zero
            }
        }
        zoomBaseScale = 1.0
        panBase = .zero
    }

    /// Flip From/To with a half-spin — the little interactive moment of the panel.
    private var swapButton: some View {
        Button {
            let from = store.convertFromUnit
            store.convertFromUnit = store.convertToUnit
            store.convertToUnit = from
            sound.play("modeswitch")
            guard theme.motionEnabled && !reduceMotion else { return }
            withAnimation(SummitMotion.glide) { swapSpin += 180 }
        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(theme.color("primaryStrong"))
                .frame(width: 30, height: 30)
                .background(Circle().fill(theme.color("surfaceSoft")))
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
                .rotationEffect(.degrees(swapSpin))
        }
        .buttonStyle(.plain)
        .padding(.top, 18)   // optically aligns with the picker row, below the labels
        .accessibilityLabel("Swap units")
    }

    private var unitOptions: some View {
        Group {
            ForEach(UnitConvert.volumeUnits, id: \.self) { unit in
                Text(unit).tag(unit)
            }
            ForEach(UnitConvert.weightUnits, id: \.self) { unit in
                Text(unit).tag(unit)
            }
        }
    }

    @ViewBuilder
    private var convertIllustration: some View {
        if UnitConvert.weightUnits.contains(store.convertToUnit) {
            ScaleFill(fraction: store.convertWeightFraction)
        } else if Self.countableUnits.contains(store.convertToUnit), let value = store.convertedValue, value > 0 {
            targetCountIllustration(value: value, unit: store.convertToUnit)
        } else {
            VesselFill(fraction: store.convertFraction)
        }
    }

    private func targetCountIllustration(value: Double, unit: String) -> some View {
        let floored = (value + 1e-3).rounded(.down)
        let remainder = value - floored
        let showsPartial = remainder >= 0.05
        let fullCount = max(Int(floored), 0)
        let cappedCount = min(fullCount, Self.maxGlyphs)
        let overflow = fullCount > Self.maxGlyphs

        return VStack(spacing: 10) {
            LazyVGrid(columns: Self.glyphColumns, spacing: 10) {
                ForEach(0..<cappedCount, id: \.self) { _ in
                    measureGlyph(unit: unit, fraction: 1.0)
                }
                if showsPartial && !overflow {
                    measureGlyph(unit: unit, fraction: remainder)
                }
            }
            Text(targetLabel(value, unit))
                .font(summitNumber(15, weight: .semibold))
                .foregroundStyle(theme.color("text"))
                .contentTransition(.numericText())
                .animation(SummitMotion.springSoft, value: value)
        }
    }

    private func measureGlyph(unit: String, fraction: Double) -> some View {
        let kind: MeasureKind = switch unit {
        case "cup": .cup
        case "tbsp": .tablespoon
        default: .teaspoon
        }
        let height = unit == "cup" ? Self.cupGlyphHeight : Self.spoonGlyphHeight
        return MeasureGlyph(kind: kind, fraction: fraction, height: height)
    }

    private func targetLabel(_ value: Double, _ unit: String) -> String {
        let rounded = (value * 100).rounded() / 100
        return "\(Formatters.fmt(rounded)) \(unit)"
    }

    private var resultCard: some View {
        VStack(spacing: 4) {
            if let converted = store.convertedValue {
                RollingNumberText(
                    text: Formatters.fmt(converted),
                    font: summitNumber(28, weight: .semibold),
                    color: theme.color("deep")
                )
                Text(store.convertToUnit)
                    .font(summitBody(13))
                    .foregroundStyle(theme.color("muted"))
            } else {
                Text("Pick units from the same family")
                    .font(summitBody(13))
                    .foregroundStyle(theme.color("muted"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.color("surfaceSoft"))
        )
    }

    private var amountBinding: Binding<Double> {
        Binding(get: { store.convertAmount }, set: { store.convertAmount = $0 })
    }
    private var fromBinding: Binding<String> {
        Binding(get: { store.convertFromUnit }, set: { store.convertFromUnit = $0 })
    }
    private var toBinding: Binding<String> {
        Binding(get: { store.convertToUnit }, set: { store.convertToUnit = $0 })
    }
}
