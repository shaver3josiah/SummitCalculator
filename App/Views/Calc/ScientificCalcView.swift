import SwiftUI
import SummitCore

// Landscape-only scientific calculator. RootView shows this INSTEAD of the portrait
// layout when verticalSizeClass == .compact (iPhone landscape) on the calc tab; it is
// never reached on iPad (its landscape is .regular) or in portrait. Everything is sized
// from the live safe-area rect so no key can land under the notch or home indicator.
struct ScientificCalcView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(CalcStore.self) private var calc
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeSolver: MathSolver?

    // 8-col × 5-row grid, row-major. LEFT 4 cols = scientific, RIGHT 4 cols = standard.
    // Blanks keep the grid aligned where there's no key (15 sci items in 20 sci cells).
    //   Row1: MC   MR   M+   M-   | AC  ±  %  ÷
    //   Row2: sin  cos  tan  Rad/Deg | 7  8  9  ×
    //   Row3: asin acos atan x·y  | 4  5  6  −
    //   Row4: Quad Pyth Frac  ·   | 1  2  3  +
    //   Row5:  ·    ·    ·    ·   | 0  .  ⌫  =
    private var cells: [GridCell] {
        var id = 0
        func next(_ k: GridCell.Kind) -> GridCell { defer { id += 1 }; return GridCell(id: id, kind: k) }
        let trig = TrigFunction.allCases   // sin, cos, tan, asin, acos, atan (in order)
        return [
            // Row 1
            next(.mem("MC")), next(.mem("MR")), next(.mem("M+")), next(.mem("M-")),
            next(.std("AC", "C", "clear", accent: true, strong: false)),
            next(.std("+/−", "±", "operator", accent: true, strong: false)),
            next(.std("%", "%", "operator", accent: true, strong: false)),
            next(.std("÷", "/", "operator", accent: true, strong: false)),
            // Row 2
            next(.trig(trig[0])), next(.trig(trig[1])), next(.trig(trig[2])), next(.angle),
            next(.std("7", "7", "tap", accent: false, strong: false)),
            next(.std("8", "8", "tap", accent: false, strong: false)),
            next(.std("9", "9", "tap", accent: false, strong: false)),
            next(.std("×", "*", "operator", accent: true, strong: false)),
            // Row 3
            next(.trig(trig[3])), next(.trig(trig[4])), next(.trig(trig[5])), next(.solver(.xy, "x·y")),
            next(.std("4", "4", "tap", accent: false, strong: false)),
            next(.std("5", "5", "tap", accent: false, strong: false)),
            next(.std("6", "6", "tap", accent: false, strong: false)),
            next(.std("−", "-", "operator", accent: true, strong: false)),
            // Row 4
            next(.solver(.quadratic, "Quad")), next(.solver(.pythagorean, "Pyth")), next(.solver(.fraction, "Frac")), next(.blank),
            next(.std("1", "1", "tap", accent: false, strong: false)),
            next(.std("2", "2", "tap", accent: false, strong: false)),
            next(.std("3", "3", "tap", accent: false, strong: false)),
            next(.std("+", "+", "operator", accent: true, strong: false)),
            // Row 5
            next(.blank), next(.blank), next(.blank), next(.blank),
            next(.std("0", "0", "tap", accent: false, strong: false)),
            next(.std(".", ".", "tap", accent: false, strong: false)),
            next(.std("⌫", "⌫", "clear", accent: false, strong: false)),
            next(.std("=", "=", "equals", accent: false, strong: true))
        ]
    }

    var body: some View {
        ZStack {
            theme.color("bg").ignoresSafeArea()   // bg is full-bleed; content below stays in the safe area
            GeometryReader { geo in
                // geo.size is ALREADY the safe-area rect (only the bg ignores it), so
                // there's nothing under the notch/home indicator. Worst targets:
                //   SE landscape      ≈ 667 × 375   |  notched 16/17 landscape ≈ 734 × 350
                // cellW = (usableW - 2*hPad - 7*gap) / 8
                //   SE:      (667 - 24 - 56)/8 = 587/8 = 73.4   ≥ 44 ✓
                //   notched: (734 - 24 - 56)/8 = 654/8 = 81.75  ≥ 44 ✓
                // rowH  = (usableH - vChrome - displayH - 4*gap) / 5   (vChrome = 6+6+6 = 18)
                //   SE:      displayH = .21*375 = 78.75 → (375-18-78.75-32)/5 = 246.25/5 = 49.25 ≥ 44 ✓
                //   notched: displayH = .21*350 = 73.5  → (350-18-73.5-32)/5 = 226.5/5  = 45.3  ≥ 44 ✓
                // Every cell clears the 44pt tap target on the shortest supported screen.
                let hPad: CGFloat = 12
                let vPad: CGFloat = 6
                let gap: CGFloat = 8
                let usableH = geo.size.height
                let displayH = usableH * 0.21
                let rowH = max(44, (usableH - 2 * vPad - vPad - displayH - 4 * gap) / 5)

                VStack(spacing: vPad) {
                    displayArea
                        .frame(height: displayH)
                    keypad(rowH: rowH, gap: gap)
                }
                .padding(.horizontal, hPad)
                .padding(.vertical, vPad)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .sheet(item: $activeSolver) { solver in
            MathSolverSheet(solver: solver) { value in
                calc.sendValue(value)
            }
        }
        // Match the app-wide type-size cap so the fixed-height grid renders as designed.
        .dynamicTypeSize(...DynamicTypeSize.large)
    }

    // Right-aligned display: a slim live-expression line above a fixed-size result that
    // scrolls horizontally (never shrinks) — same "cash-register tape" idea as portrait.
    private var displayArea: some View {
        // resultFont 44: line ≈ 44*1.2 = 52.8, and the result band is displayH minus the
        // expression line (≈ 54pt tall on the 350-tall notched screen), so it never clips.
        let resultFont: CGFloat = 44
        return VStack(alignment: .trailing, spacing: 2) {
            Text(calc.expression)
                .font(summitNumber(13, weight: .medium))
                .foregroundStyle(theme.color("muted"))
                .lineLimit(1)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .trailing)

            ScrollViewReader { proxy in
                GeometryReader { rowGeo in
                    ScrollView(.horizontal, showsIndicators: false) {
                        RollingNumberText(
                            text: calc.display,
                            font: summitNumber(resultFont, weight: .semibold),
                            color: theme.color("text")
                        )
                        .lineLimit(1)
                        .fixedSize()                                       // never shrink the digits
                        .padding(.leading, 24)                             // scroll headroom
                        .frame(minWidth: rowGeo.size.width, alignment: .trailing)
                        .frame(height: rowGeo.size.height, alignment: .bottom)
                        .id("sciResult")
                    }
                    .defaultScrollAnchor(.trailing)
                    .onChange(of: calc.display) { _, _ in
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                            proxy.scrollTo("sciResult", anchor: .trailing)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func keypad(rowH: CGFloat, gap: CGFloat) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: gap), count: 8)
        return LazyVGrid(columns: columns, spacing: gap) {
            ForEach(cells) { cell in
                cellView(cell, rowH: rowH)
            }
        }
    }

    @ViewBuilder
    private func cellView(_ cell: GridCell, rowH: CGFloat) -> some View {
        switch cell.kind {
        case .blank:
            Color.clear.frame(height: rowH)
        case let .std(label, key, event, accent, strong):
            KeypadButton(
                label: label,
                soundEvent: event,
                isAccent: accent,
                isStrong: strong,
                isPending: calc.pendingOpKey == key,
                height: rowH
            ) {
                calc.press(key)
            }
        case let .mem(label):
            sciButton(label, height: rowH) { calc.press(label) }
        case let .trig(fn):
            sciButton(fn.rawValue, height: rowH) { calc.applyTrig(fn) }
        case .angle:
            sciButton(calc.angleMode.shortLabel, height: rowH) { calc.toggleAngleMode() }
        case let .solver(solver, label):
            sciButton(label, height: rowH) { activeSolver = solver }
        }
    }

    // Lightweight on-theme key for scientific functions: surface2 tile, primaryStrong
    // label — quieter than the standard KeypadButton so the number pad stays the hero.
    private func sciButton(_ label: String, height: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(summitBody(15, weight: .semibold))
                .foregroundStyle(theme.color("primaryStrong"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(theme.color("surface2"))
                .clipShape(RoundedRectangle(cornerRadius: theme.radius * 0.6))
        }
        .buttonStyle(.plain)
    }
}

private struct GridCell: Identifiable {
    let id: Int
    let kind: Kind

    enum Kind {
        case blank
        case std(_ label: String, _ key: String, _ event: String, accent: Bool, strong: Bool)
        case mem(String)                    // press(label): MC/MR/M+/M-
        case trig(TrigFunction)             // applyTrig(fn)
        case angle                          // toggleAngleMode(), label = angleMode.shortLabel
        case solver(MathSolver, String)     // set activeSolver, with its display label
    }
}
