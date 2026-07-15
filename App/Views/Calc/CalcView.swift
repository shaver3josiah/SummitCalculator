import SwiftUI
import SummitCore

struct CalcView: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(CalcStore.self) private var calcStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(MusicStore.self) private var musicStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeSolver: MathSolver?

    private let keypadRows: [[KeyDef]] = [
        [KeyDef(label: "AC", key: "C", event: "clear", accent: true),
         KeyDef(label: "+/−", key: "±", event: "operator", accent: true),
         KeyDef(label: "%", key: "%", event: "operator", accent: true),
         KeyDef(label: "÷", key: "/", event: "operator", accent: true)],
        [KeyDef(label: "7", key: "7", event: "tap"),
         KeyDef(label: "8", key: "8", event: "tap"),
         KeyDef(label: "9", key: "9", event: "tap"),
         KeyDef(label: "×", key: "*", event: "operator", accent: true)],
        [KeyDef(label: "4", key: "4", event: "tap"),
         KeyDef(label: "5", key: "5", event: "tap"),
         KeyDef(label: "6", key: "6", event: "tap"),
         KeyDef(label: "−", key: "-", event: "operator", accent: true)],
        [KeyDef(label: "1", key: "1", event: "tap"),
         KeyDef(label: "2", key: "2", event: "tap"),
         KeyDef(label: "3", key: "3", event: "tap"),
         KeyDef(label: "+", key: "+", event: "operator", accent: true)],
        [KeyDef(label: "0", key: "0", event: "tap"),
         KeyDef(label: ".", key: ".", event: "tap"),
         KeyDef(label: "⌫", key: "⌫", event: "clear"),
         KeyDef(label: "=", key: "=", event: "equals", strong: true)]
    ]

    var body: some View {
        // Everything is sized from CalcView's real slot so NOTHING can clip, and it
        // scales up (never just leaves a void) on larger devices:
        //   • keys grow 44→72pt (44 floor keeps them tappable on an SE)
        //   • the card is the residual after the keypad, clamped 128–210 — so on
        //     phones it fills (cluster ≈ slot, keypad sits near the bottom) and on a
        //     tablet it caps at a generous 210 rather than ballooning
        //   • resultFont tracks the card (the DEVICE), never the digit count, so the
        //     number is a constant size and long values scroll instead of shrinking
        // The cluster is CENTERED: on phones the residual card makes the margin ~14pt
        // (still bottom-anchored feel); on iPad the capped elements center with
        // balanced margins instead of dumping a ~380pt gap under the card.
        GeometryReader { geo in
            let slack = geo.size.height - 98            // 98 = ~memory bar + gaps
            let keyHeight = min(72.0, max(44.0, (slack - 190) / 5))
            let keypadBlock = keyHeight * 5 + 40        // 5 rows + 4×10 gaps
            let cardHeight = min(210.0, max(128.0, slack - keypadBlock))
            let resultFont = min(92.0, max(40.0, cardHeight * 0.44))
            VStack(spacing: 16) {
                displayArea(resultFont: resultFont)
                    .frame(height: cardHeight)
                // The tappable cluster caps at 460 centered so keys don't become
                // ~160pt slabs on iPad. On compact phones (<460) these don't constrain.
                memoryBar
                    .frame(maxWidth: 460)
                keypad(keyHeight: keyHeight)
                    .frame(maxWidth: 460)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .overlay {
            // Confetti celebration on an easter-egg result — flies across the whole pad.
            if themeStore.leavesOn {
                LeafBurstView(trigger: calcStore.eggEpoch, originX: 0.5, originY: 0.3)
                    .allowsHitTesting(false)
            }
        }
        .sheet(item: $activeSolver) { solver in
            MathSolverSheet(solver: solver) { value in
                calcStore.sendValue(value)
            }
        }
    }

    // Whether the left column (log + wheel) is present at all. When both toggles are
    // off it vanishes entirely and the result column takes the full card width.
    private var showLeftColumn: Bool {
        themeStore.showCalcLog || themeStore.showChordWheel
    }

    // The display card. Height is set explicitly in `body` (slot minus fixed chrome),
    // never scavenged from VStack arbitration. Two-line calculator layout on the right:
    // the live expression fills the top band (previously empty), the fixed-size result
    // sits below it and scrolls horizontally instead of shrinking.
    private func displayArea(resultFont: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if showLeftColumn {
                leftColumn
            }
            resultColumn(fontSize: resultFont)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .background(themeStore.color("surfaceSoft"))
        .clipShape(RoundedRectangle(cornerRadius: themeStore.radius))
        .overlay {
            // The encircle traces the display card each time a result lands, and
            // again whenever the tab remounts (RootView's .id(selectedTab)) —
            // the same greet-on-arrival trace the kitchen pill and QR use.
            if themeStore.shimmerOn {
                EncircleOutline(
                    trigger: calcStore.resultEpoch,
                    cornerRadius: themeStore.radius,
                    lineWidth: 1.5,
                    settleOpacity: 0.4
                )
            }
        }
        .background {
            // Summit sits behind the opaque card and is left unclipped, so leaves
            // only show where they rise past the card's edges.
            if themeStore.leavesOn {
                ResultSummitView(trigger: calcStore.resultEpoch)
                    .padding(-34)
                    .allowsHitTesting(false)
            }
        }
    }

    // Right side of the card: a slim live-expression line up top (the one thing the
    // history log — which only holds completed calcs — never shows), and below it the
    // result at a fixed device-sized font. Long results scroll to the trailing edge
    // like a cash-register tape; the digits keep their size, the tape moves.
    private func resultColumn(fontSize: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(calcStore.expression)
                .font(summitNumber(20, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
                .lineLimit(1)
                .truncationMode(.head)   // keep the newest (right) end of a long expression
                .frame(maxWidth: .infinity, alignment: .trailing)

            Spacer(minLength: 0)

            // The result at a fixed size. GeometryReader gives the row width so short
            // values right-align and long ones overflow into a horizontal scroll,
            // trailing-anchored — the digits never resize, the "tape" moves.
            ScrollViewReader { proxy in
                GeometryReader { geo in
                    ScrollView(.horizontal, showsIndicators: false) {
                        RollingNumberText(
                            text: calcStore.display,
                            font: summitNumber(fontSize, weight: .semibold),
                            color: themeStore.color("text")
                        )
                        .lineLimit(1)
                        .fixedSize()                                         // never shrink
                        .padding(.leading, 6)                                // minimal scroll headroom
                        .frame(minWidth: geo.size.width, alignment: .trailing)
                        .frame(height: geo.size.height, alignment: .bottom)  // sit on the baseline
                        .id("summitResult")
                    }
                    .defaultScrollAnchor(.trailing)
                    .onChange(of: calcStore.display) { _, _ in
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                            proxy.scrollTo("summitResult", anchor: .trailing)
                        }
                    }
                }
                .frame(height: fontSize * 1.15)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }

    // Fixed-width (100) left stack: calc log above, chord strip below. Wrapped in a
    // scroll view that only scrolls when the content genuinely exceeds the card's
    // inner height (a short SE card with chords present) — so it can never clip a
    // strip, and on taller cards it shows everything with no scroll. Each element is
    // gated by its own toggle; showLeftColumn removes the whole reservation when both
    // are off so the numbers get the full width.
    private var leftColumn: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 6) {
                if themeStore.showCalcLog {
                    calcLog
                }
                if themeStore.showChordWheel {
                    chordStrip
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(width: 54)   // narrow, tucked column; frees width so the result stops clipping
    }

    // Recently played chords, newest first, as a soft scrollable strip — the
    // raw iOS wheel picker's grey selection band read as unfinished on the card.
    // Newest chord is emphasized; the strip scrolls for older ones. Empty until you
    // play something, so it reserves no awkward box on the calculator screen.
    @ViewBuilder
    private var chordStrip: some View {
        if !musicStore.playedChordNames.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text("CHORDS")
                    .font(summitBody(8, weight: .semibold))
                    .tracking(0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(themeStore.color("muted"))
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(Array(musicStore.playedChordNames.prefix(10).enumerated()), id: \.offset) { idx, name in
                            Text(name)
                                .font(summitBody(idx == 0 ? 13 : 11, weight: idx == 0 ? .bold : .regular))
                                .foregroundStyle(idx == 0 ? themeStore.color("primaryStrong") : themeStore.color("muted"))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 70)
            }
            .padding(7)
            .background(
                RoundedRectangle(cornerRadius: 10).fill(themeStore.color("surface2"))
            )
            // Fills the narrow left column, tucked directly under the history so the
            // two read as one compact column.
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // Left-side running log: last 3 completed calcs, oldest→newest top-to-bottom.
    // Sourced from history (calc entries carry extra["tokens"] + value); tapping a
    // line replays it via the same replayTokens the recycle sheet uses. Fills the
    // 100pt left column (its parent reserves the width).
    private var calcLog: some View {
        let recent = historyStore.entries
            .filter { $0.type == "calc" && !($0.extra["tokens"] ?? "").isEmpty }
            .prefix(3)
            .reversed()
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(recent)) { entry in
                Button {
                    if let tokens = entry.extra["tokens"] {
                        calcStore.replayTokens(tokens)
                    }
                } label: {
                    Text("\(entry.extra["tokens"] ?? "") = \(entry.value)")
                        .font(summitBody(11))
                        .foregroundStyle(themeStore.color("muted"))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var memoryBar: some View {
        HStack(spacing: 10) {
            modeLabelButton
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    modeContent
                }
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeStore.color("surface2"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var modeLabelButton: some View {
        Button {
            calcStore.cycleMathMode()
        } label: {
            HStack(spacing: 4) {
                Text(calcStore.mathMode.title)
                    .font(summitBody(10, weight: .semibold))
                    .foregroundStyle(themeStore.color("muted"))
                if calcStore.mathMode == .memory, calcStore.memoryValue != 0 {
                    Circle()
                        .fill(themeStore.color("primaryStrong"))
                        .frame(width: 6, height: 6)
                }
                Image(systemName: "chevron.forward")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(themeStore.color("primaryStrong"))
            }
        }
        .buttonStyle(.plain)
        .fixedSize()
    }

    @ViewBuilder
    private var modeContent: some View {
        switch calcStore.mathMode {
        case .memory:
            memoryControls
        case .complex:
            complexStrip
        case .trig:
            trigStrip
        }
    }

    private var memoryControls: some View {
        HStack(spacing: 8) {
            memoryButton("MC")
            memoryButton("MR")
            memoryButton("M-")
            memoryButton("M+")
            Text(Formatters.plain(calcStore.memoryValue))
                .font(summitBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("text"))
                .lineLimit(1)
                .frame(minWidth: 40, alignment: .trailing)
        }
    }

    private var complexStrip: some View {
        HStack(spacing: 8) {
            mathChip("x·y") { activeSolver = .xy }
            mathChip("Quad") { activeSolver = .quadratic }
            mathChip("Pyth") { activeSolver = .pythagorean }
            mathChip("Frac") { activeSolver = .fraction }
            angleChip
        }
    }

    private var trigStrip: some View {
        HStack(spacing: 8) {
            ForEach(TrigFunction.allCases, id: \.self) { fn in
                mathChip(fn.rawValue) { calcStore.applyTrig(fn) }
            }
            angleChip
        }
    }

    private var angleChip: some View {
        Button {
            calcStore.toggleAngleMode()
        } label: {
            Text(calcStore.angleMode.shortLabel)
                .font(summitBody(11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 999).fill(themeStore.color("primaryStrong")))
        }
        .buttonStyle(.plain)
    }

    private func mathChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(summitBody(11, weight: .semibold))
                .foregroundStyle(themeStore.color("primaryStrong"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 999).fill(themeStore.color("surfaceSoft")))
        }
        .buttonStyle(.plain)
    }

    private func memoryButton(_ label: String) -> some View {
        Button {
            calcStore.press(label)
        } label: {
            Text(label)
                .font(summitBody(11, weight: .semibold))
                .foregroundStyle(themeStore.color("primaryStrong"))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }

    private func keypad(keyHeight: CGFloat) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(keypadRows.flatMap { $0 }) { def in
                KeypadButton(
                    label: def.label,
                    soundEvent: def.event,
                    isAccent: def.accent,
                    isStrong: def.strong,
                    isPending: calcStore.pendingOpKey == def.key,
                    height: keyHeight
                ) {
                    calcStore.press(def.key)
                }
            }
        }
    }
}

private struct KeyDef: Identifiable {
    let label: String
    let key: String
    let event: String
    var accent: Bool = false
    var strong: Bool = false
    var id: String { key + label }
}
