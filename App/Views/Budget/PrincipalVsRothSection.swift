import SwiftUI
import Charts
import SummitCore

/// "Extra mortgage principal vs Roth IRA" decision calculator, Summit-styled.
/// A live, collapsible card: change any input and the verdict, stat strip, and
/// both charts recompute from `MortgageMath.simulate` (all series come straight
/// from the engine rows, so a chart can never contradict the verdict).
struct PrincipalVsRothSection: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Inputs — local @State only (a live calculator needs no persistence).
    // Defaults mirror the HTML's initial input values.
    @State private var expanded = false
    @State private var balanceStr = "180000"
    @State private var paymentStr = "1161"
    @State private var homeStr = "200000"
    @State private var pmiStr = "0"
    @State private var rothStr = "17500"
    @State private var aprPct = 5.7
    @State private var appreciationPct = 4.5
    @State private var extra = 306.0
    @State private var returnPct = 10.0
    @State private var horizonYears = 24.0
    @State private var itemize = false
    @State private var bracket = 0.22
    @State private var investIdx = 0   // index into investPresets — seeds the return
    @State private var loanIdx = 0     // index into loanPresets — seeds the APR + which fields show

    private let brackets: [Double] = [0.10, 0.12, 0.22, 0.24, 0.32, 0.35, 0.37]

    // Vehicle presets. Picking one seeds the matching slider; the slider still
    // overrides afterward. Rates are illustrative defaults, not guarantees.
    private struct Vehicle { let name: String; let rate: Double; let note: String }
    private struct Loan { let name: String; let rate: Double; let note: String; let isMortgage: Bool }

    private static let investPresets: [Vehicle] = [
        Vehicle(name: "Index / Roth", rate: 10,  note: "Broad market, tax-free in a Roth."),
        Vehicle(name: "Real estate",  rate: 8,   note: "Leverage can amplify returns; illiquid. Not fully modeled."),
        Vehicle(name: "Bonds",        rate: 4.5, note: "Steadier, lower expected return."),
        Vehicle(name: "401(k)",       rate: 9,   note: "An employer match is free return this tool doesn't add."),
        Vehicle(name: "ESOP",         rate: 10,  note: "Concentrated in one company \u{2014} higher risk."),
    ]
    private static let loanPresets: [Loan] = [
        Loan(name: "Mortgage",            rate: 5.7, note: "Home value, PMI, and appreciation are all part of the picture.", isMortgage: true),
        Loan(name: "Small business loan", rate: 9,   note: "Paying it down is guaranteed \u{2014} but the business itself may return MORE than the rate, the upside prepaying gives up.", isMortgage: false),
        Loan(name: "Solar panels",        rate: 6,   note: "The panels also cut your power bill \u{2014} an effective return on top of the debt.", isMortgage: false),
        Loan(name: "Electric car",        rate: 6.5, note: "Fuel + maintenance savings offset the rate.", isMortgage: false),
    ]

    // MARK: derived

    private var isMortgage: Bool { Self.loanPresets[loanIdx].isMortgage }
    private var effItemize: Bool { isMortgage && itemize }   // interest deduction is mortgage-only here

    private var inputs: MortgageInputs {
        MortgageInputs(
            balance: parse(balanceStr, 180_000),
            apr: aprPct / 100,
            itemize: effItemize,
            tax: bracket,
            payment: parse(paymentStr, 1161),
            home: parse(homeStr, 200_000),
            pmi: isMortgage ? parse(pmiStr, 0) : 0,                 // PMI/appreciation are mortgage-only
            extra: extra,
            roth0: parse(rothStr, 17_500),
            annualReturn: returnPct / 100,
            appreciation: isMortgage ? appreciationPct / 100 : 0,
            horizonYears: horizonYears
        )
    }

    private var effRate: Double { inputs.apr * (1 - (effItemize ? bracket : 0)) }
    private var minPayment: Double { inputs.balance * inputs.apr / 12 }
    private var paymentCoversInterest: Bool { inputs.payment > minPayment }

    private var accent: Color { theme.color("primaryStrong") }   // invest / Roth path (brand)
    private var deep: Color { theme.color("deep") }            // prepay / house path

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: expanded ? 18 : 0) {
                header
                if expanded {
                    inputSection
                    if paymentCoversInterest {
                        // Simulate once per body evaluation — the helpers below all read it.
                        let result = MortgageMath.simulate(inputs)
                        verdictSection(result)
                        statStrip(result)
                        chartOne(result)
                        if isMortgage { chartTwo(result) }   // home-vs-balance only applies to a mortgage
                        chartThree(result)
                    } else {
                        Text("That payment doesn't cover interest — set it above \(Formatters.usd(minPayment))/mo to run the comparison.")
                            .font(summitBody(13))
                            .foregroundStyle(deep)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: header

    private var header: some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { expanded.toggle() }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Principal vs Roth")
                        .font(summitNumber(17, weight: .semibold))
                        .foregroundStyle(deep)
                    Text("Should the extra go to the mortgage or the market?")
                        .font(summitBody(12))
                        .foregroundStyle(theme.color("muted"))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(width: 32, height: 32)
                    .background(theme.color("surfaceSoft"))
                    .clipShape(Circle())
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: inputs

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            vehicleSection

            HStack(spacing: 12) {
                moneyField("Balance", $balanceStr)
                moneyField("Payment / mo", $paymentStr)
            }
            if isMortgage {
                HStack(spacing: 12) {
                    moneyField("Home value", $homeStr)
                    moneyField("PMI / mo", $pmiStr)
                }
            }
            moneyField("Current Roth", $rothStr)

            slider("Interest rate", value: $aprPct, in: 0.25...15, step: 0.05,
                   display: pct(aprPct))
            slider("Extra per month", value: $extra, in: 25...1500, step: 1,
                   display: Formatters.usd(extra))
            slider("Assumed annual return", value: $returnPct, in: 3...14, step: 0.1,
                   display: pct(returnPct))
            if isMortgage {
                slider("Home appreciation / yr", value: $appreciationPct, in: 0...8, step: 0.1,
                       display: pct(appreciationPct))
            }
            slider("Compare over", value: $horizonYears, in: 5...40, step: 1,
                   display: "\(Int(horizonYears)) yrs")

            if isMortgage {
                Toggle(isOn: $itemize) {
                    Text("I itemize & deduct mortgage interest")
                        .font(summitBody(13, weight: .medium))
                        .foregroundStyle(theme.color("text"))
                }
                .tint(accent)

                if itemize {
                    HStack {
                        Text("Marginal bracket")
                            .font(summitBody(13, weight: .medium))
                            .foregroundStyle(theme.color("muted"))
                        Spacer()
                        Picker("Marginal bracket", selection: $bracket) {
                            ForEach(brackets, id: \.self) { b in
                                Text("\(Int(b * 100))%").tag(b)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(accent)
                    }
                }
            }
        }
    }

    // MARK: vehicle pickers — seed the return / APR, then the sliders override

    private var vehicleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            pickerBlock(title: "Invest the extra in",
                        titles: Self.investPresets.map(\.name),
                        selected: investIdx, accent: accent,
                        note: Self.investPresets[investIdx].note) { idx in
                investIdx = idx
                returnPct = min(max(Self.investPresets[idx].rate, 3), 14)   // clamp to slider range
            }
            pickerBlock(title: "Debt to pay down",
                        titles: Self.loanPresets.map(\.name),
                        selected: loanIdx, accent: deep,
                        note: Self.loanPresets[loanIdx].note) { idx in
                loanIdx = idx
                aprPct = min(max(Self.loanPresets[idx].rate, 0.25), 15)
            }
        }
    }

    private func pickerBlock(title: String, titles: [String], selected: Int,
                             accent: Color, note: String,
                             pick: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(summitBody(12, weight: .medium))
                .foregroundStyle(theme.color("muted"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(titles.enumerated()), id: \.offset) { idx, name in
                        let on = idx == selected
                        Button {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { pick(idx) }
                        } label: {
                            Text(name)
                                .font(summitBody(12, weight: .medium))
                                .foregroundStyle(on ? .white : theme.color("muted"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(on ? accent : theme.color("surfaceSoft"))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }
            Text(note)
                .font(summitBody(11))
                .foregroundStyle(theme.color("muted"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func moneyField(_ label: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(summitBody(12, weight: .medium))
                .foregroundStyle(theme.color("muted"))
            TextField("", text: text)
                .keyboardType(.decimalPad)
                .font(summitBody(15))
                .foregroundStyle(theme.color("text"))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(theme.color("surfaceSoft"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func slider(_ label: String, value: Binding<Double>, in range: ClosedRange<Double>,
                        step: Double, display: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(summitBody(12, weight: .medium))
                    .foregroundStyle(theme.color("muted"))
                Spacer()
                Text(display)
                    .font(summitNumber(14, weight: .medium))
                    .foregroundStyle(theme.color("text"))
            }
            Slider(value: value, in: range, step: step)
                .tint(accent)
        }
    }

    // MARK: verdict

    private func diff(_ result: MortgageResult) -> Double { result.last.netB - result.last.netA }        // + favors investing
    private func intSaved(_ result: MortgageResult) -> Double { result.interestB - result.interestA }
    private func isTie(_ result: MortgageResult) -> Bool { abs(inputs.annualReturn - effRate) < 0.0005 && abs(diff(result)) < 1 }

    private func verdictSection(_ result: MortgageResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verdictHeadline(result))
                .font(summitNumber(21, weight: .semibold))
                .foregroundStyle(verdictColor(result))
                .fixedSize(horizontal: false, vertical: true)
            Text(verdictSub(result))
                .font(summitBody(13))
                .foregroundStyle(theme.color("muted"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func verdictColor(_ result: MortgageResult) -> Color {
        if isTie(result) { return deep }
        return diff(result) > 0 ? accent : deep
    }

    private func verdictHeadline(_ result: MortgageResult) -> String {
        if isTie(result) { return "The two strategies tie." }
        return diff(result) > 0 ? "Investing the extra wins." : "Paying down the loan wins."
    }

    private var rateWord: String {
        if effItemize { return "effective mortgage cost" }
        return isMortgage ? "mortgage rate" : "loan rate"
    }

    private func verdictSub(_ result: MortgageResult) -> String {
        if isTie(result) {
            return "At a \(pct(returnPct)) return — exactly your \(rateWord) — both futures land within pennies after \(Int(horizonYears)) years. Below it prepaying wins; above it investing wins."
        }
        if diff(result) > 0 {
            return "At an assumed \(pct(returnPct)) return, investing \(Formatters.usd(extra))/mo ends \(Int(horizonYears)) years ahead by \(Formatters.usd(diff(result))). The catch is the word assumed: prepaying's \(pct(effRate * 100)) is contractual; the market's isn't. Below \(pct(effRate * 100)) it reverses."
        }
        return "At an assumed \(pct(returnPct)) return — below your \(pct(effRate * 100)) \(rateWord) — prepaying wins by \(Formatters.usd(-diff(result))) after \(Int(horizonYears)) years, and its return is guaranteed."
    }

    // MARK: stat strip

    private func statStrip(_ result: MortgageResult) -> some View {
        let L = result.last
        let d = diff(result)
        return VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                stat(signedMoney(d), d >= 0 ? "invest advantage" : "prepay advantage",
                     color: d >= 0 ? accent : deep)
                stat(result.payoffA.map(yrs) ?? "beyond horizon", "debt-free if you prepay",
                     color: deep)
            }
            HStack(alignment: .top, spacing: 12) {
                stat(Formatters.usd(intSaved(result)), "interest saved by prepaying", color: deep)
                stat(Formatters.usd(L.investedB), "the extra dollars, invested", color: accent)
            }
        }
        .padding(.top, 2)
    }

    private func stat(_ value: String, _ caption: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(summitNumber(19, weight: .medium))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .font(summitBody(11))
                .foregroundStyle(theme.color("muted"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: chart 1 — two strategies compared (net position)

    private func chartOne(_ result: MortgageResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            chartTitle("Two strategies compared",
                       "Net position = savings − remaining debt. The house cancels, so this is the whole gap.")
            legend([("House first", deep), ("Roth first", accent)])
            lineChart(
                result: result,
                specs: [
                    LineSpec(name: "House first", color: deep, values: result.rows.map(\.netA), dashed: false),
                    LineSpec(name: "Roth first", color: accent, values: result.rows.map(\.netB), dashed: false),
                ],
                milestones: result.payoffA.map { [Milestone(year: Double($0) / 12, color: deep, label: "paid off")] } ?? [],
                includesZero: false
            )
        }
    }

    // MARK: chart 2 — the home as an asset

    private func chartTwo(_ result: MortgageResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            chartTitle("The home as an asset",
                       "Appreciating value against the shrinking loan. The gap between the lines is your equity.")
            legend([("Home value", theme.color("muted")), ("Loan · normal", accent), ("Loan · prepaying", deep)])
            lineChart(
                result: result,
                specs: [
                    LineSpec(name: "Home value", color: theme.color("muted"), values: result.rows.map(\.homeValue), dashed: true),
                    LineSpec(name: "Loan · normal", color: accent, values: result.rows.map(\.balanceB), dashed: false),
                    LineSpec(name: "Loan · prepaying", color: deep, values: result.rows.map(\.balanceA), dashed: false),
                ],
                milestones: [],
                includesZero: true
            )
        }
    }

    // MARK: chart 3 — interest handed to the lender (cumulative, straight from rows)

    private func chartThree(_ result: MortgageResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            chartTitle("Interest paid to the lender",
                       "Cumulative interest each path hands over. Prepaying bends its curve down early — that gap is the guaranteed saving.")
            legend([("Normal schedule", accent), ("Prepaying", deep)])
            lineChart(
                result: result,
                specs: [
                    LineSpec(name: "Normal schedule", color: accent, values: result.rows.map(\.interestB), dashed: false),
                    LineSpec(name: "Prepaying", color: deep, values: result.rows.map(\.interestA), dashed: false),
                ],
                milestones: result.payoffA.map { [Milestone(year: Double($0) / 12, color: deep, label: "paid off")] } ?? [],
                includesZero: true
            )
        }
    }

    private func chartTitle(_ title: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(summitBody(14, weight: .semibold))
                .foregroundStyle(theme.color("text"))
            Text(sub)
                .font(summitBody(11))
                .foregroundStyle(theme.color("muted"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: reusable chart

    private struct LineSpec {
        let name: String
        let color: Color
        let values: [Double]   // one per month, parallel to result.rows
        let dashed: Bool
    }
    private struct Milestone {
        let year: Double
        let color: Color
        let label: String
    }

    @ChartContentBuilder
    private func series(_ spec: LineSpec) -> some ChartContent {
        ForEach(Array(spec.values.enumerated()), id: \.offset) { item in
            LineMark(
                x: .value("Year", Double(item.offset + 1) / 12),
                y: .value("Dollars", item.element),
                series: .value("Plan", spec.name)
            )
            .foregroundStyle(spec.color)
            .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round,
                                   dash: spec.dashed ? [6, 5] : []))
        }
        // endpoint emphasis
        if let last = spec.values.last {
            PointMark(
                x: .value("Year", Double(spec.values.count) / 12),
                y: .value("Dollars", last)
            )
            .foregroundStyle(spec.color)
            .symbolSize(60)
        }
    }

    private func lineChart(result: MortgageResult, specs: [LineSpec], milestones: [Milestone], includesZero: Bool) -> some View {
        let maxYear = Double(result.months) / 12
        let strideYears: Double = maxYear > 24 ? 10 : maxYear > 12 ? 5 : 2
        return Chart {
            if !includesZero {
                RuleMark(y: .value("Zero", 0.0))
                    .foregroundStyle(theme.color("line"))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 4]))
            }
            ForEach(Array(specs.enumerated()), id: \.offset) { item in
                series(item.element)
            }
            ForEach(Array(milestones.enumerated()), id: \.offset) { item in
                RuleMark(x: .value("Year", item.element.year))
                    .foregroundStyle(item.element.color.opacity(0.45))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    .annotation(position: .top, alignment: .leading, spacing: 2) {
                        Text("\(item.element.label) · \(yrs(Int((item.element.year * 12).rounded())))")
                            .font(summitBody(9, weight: .semibold))
                            .foregroundStyle(item.element.color)
                    }
            }
        }
        .chartXScale(domain: 0.0...maxYear)
        .chartYScale(domain: .automatic(includesZero: includesZero))
        .chartXAxis {
            AxisMarks(values: .stride(by: strideYears)) { value in
                AxisGridLine().foregroundStyle(theme.color("line").opacity(0.5))
                AxisValueLabel {
                    if let y = value.as(Double.self) {
                        Text("yr \(Int(y))")
                            .font(summitBody(9))
                            .foregroundStyle(theme.color("muted"))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(theme.color("line").opacity(0.5))
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(compact(d))
                            .font(summitBody(9))
                            .foregroundStyle(theme.color("muted"))
                    }
                }
            }
        }
        .frame(height: 200)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: result.months)
    }

    private func legend(_ items: [(String, Color)]) -> some View {
        HStack(spacing: 14) {
            ForEach(Array(items.enumerated()), id: \.offset) { item in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(item.element.1)
                        .frame(width: 16, height: 3)
                    Text(item.element.0)
                        .font(summitBody(11, weight: .medium))
                        .foregroundStyle(theme.color("muted"))
                }
            }
        }
    }

    // MARK: formatting helpers

    private func parse(_ s: String, _ fallback: Double) -> Double {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return fallback }
        return Double(trimmed) ?? 0
    }

    private func pct(_ v: Double) -> String { String(format: "%.1f%%", v) }

    private func yrs(_ months: Int) -> String { String(format: "%.1f yrs", Double(months) / 12) }

    private func signedMoney(_ v: Double) -> String {
        (v >= 0 ? "+" : "\u{2212}") + Formatters.usd(abs(v))
    }

    /// Compact axis money: $180k, $1.2M.
    private func compact(_ v: Double) -> String {
        let a = abs(v)
        let sign = v < 0 ? "\u{2212}$" : "$"
        if a >= 1_000_000 { return sign + String(format: "%.1fM", a / 1_000_000) }
        if a >= 1_000 { return sign + String(format: "%.0fk", a / 1_000) }
        return sign + String(format: "%.0f", a)
    }
}
