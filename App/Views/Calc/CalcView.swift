import SwiftUI
import SummitCore

struct CalcView: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(CalcStore.self) private var calcStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(MusicStore.self) private var musicStore
    @State private var activeSolver: MathSolver?
    @State private var wheelSelection = 0   // inert: the chord wheel is a viewer, not a control

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
        // Everything is sized from CalcView's real slot so NOTHING can clip:
        // fixed chrome = 8 top pad + ~42 memory bar + 2×16 spacing = 82. The
        // remainder splits between keypad and display card — keys run at their
        // ideal 58pt when there's room and compress (never below 44pt) on small
        // phones like the SE, with the card taking all the rest. Bigger devices
        // therefore scale the display up while the keypad stays hand-sized.
        GeometryReader { geo in
            let slack = geo.size.height - 82
            let keyHeight = min(58.0, max(44.0, (slack - 120 - 40) / 5))
            let cardHeight = max(120, slack - (keyHeight * 5 + 40))
            VStack(spacing: 16) {
                displayArea
                    .frame(height: cardHeight)
                // Display card owns the full 700 column (big result + log look glorious
                // wide); the tappable cluster caps at 460 centered so keys don't become
                // ~160pt slabs on iPad. On compact phones (<460) these don't constrain.
                memoryBar
                    .frame(maxWidth: 460)
                keypad(keyHeight: keyHeight)
                    .frame(maxWidth: 460)
            }
            .frame(maxWidth: .infinity)
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

    // The display card. Its height is set explicitly in `body` (slot height minus the
    // fixed chrome), never scavenged from VStack arbitration — the old bug: the
    // flexible card lost the arbitration to the flexible keypad and starved to
    // ~105pt, flooring the result at 58pt. The result Text auto-shrinks a 280pt font
    // to fill the slot, so "10" renders huge and "1234567.89" still fits.
    private var displayArea: some View {
        HStack(alignment: .top, spacing: 12) {
            if showLeftColumn {
                leftColumn
            }
            resultColumn
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
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

    // Result column: just the giant auto-shrinking number. The old expression line
    // ("7 + 6") is gone — the calc log at top-left already tells that story, and
    // removing it hands its height to the result. The 280pt font is a ceiling —
    // minimumScaleFactor(0.1) + the fill frame let SwiftUI scale glyphs down to fit
    // BOTH the card width and height, so short answers render enormous and long
    // ones still fit on one line, pinned bottom-trailing.
    private var resultColumn: some View {
        RollingNumberText(
            text: calcStore.display,
            font: summitNumber(280, weight: .semibold),
            color: themeStore.color("text")
        )
        .lineLimit(1)
        .minimumScaleFactor(0.1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }

    // Fixed-width (110) left stack, top-aligned: calc log above, chord wheel below.
    // Each element is gated by its own toggle; showLeftColumn removes the whole 110pt
    // reservation when both are off so the numbers get the full width.
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            if themeStore.showCalcLog {
                calcLog
            }
            if themeStore.showChordWheel {
                chordWheel
            }
            Spacer(minLength: 0)
        }
        .frame(width: 110, alignment: .leading)
    }

    // Session-only viewer of recently played chords, newest first, in an iOS wheel
    // picker (the literal number-picker feel). Selection binds to inert local state —
    // spinning it does nothing yet. A ~90pt window naturally shows ~4 rows at once.
    @ViewBuilder
    private var chordWheel: some View {
        if musicStore.playedChordNames.isEmpty {
            Text("No chords yet")
                .font(summitBody(11))
                .foregroundStyle(themeStore.color("muted"))
                .frame(width: 110, height: 90, alignment: .topLeading)
        } else {
            Picker("", selection: $wheelSelection) {
                ForEach(Array(musicStore.playedChordNames.enumerated()), id: \.offset) { idx, name in
                    Text(name)
                        .font(summitBody(11))
                        .tag(idx)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(width: 110, height: 90)
            .clipped()
        }
    }

    // Left-side running log: last 3 completed calcs, oldest→newest top-to-bottom.
    // Sourced from history (calc entries carry extra["tokens"] + value); tapping a
    // line replays it via the same replayTokens the recycle sheet uses. Fills the
    // 110pt left column (its parent reserves the width).
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
