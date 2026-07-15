import SwiftUI
import Charts
import SummitCore

// Extra yearly-mode visuals. YearWrap already shows income vs. planned as grouped
// bars, so these add the two views it was missing: how savings stack up over the
// year, and where the money is planned to go. All series come straight from the
// store's saved months — nothing is invented for months with no budget.

// MARK: - Cumulative savings across the year

struct YearSavingsChart: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Point: Identifiable {
        let month: Int      // 1...12
        let cum: Double
        var id: Int { month }
    }

    // Running total of (take-home − planned) over the months that actually exist.
    private var points: [Point] {
        var out: [Point] = []
        var running = 0.0
        for (idx, e) in store.yearAggregate().enumerated() where e.has {
            running += e.takeHome - e.planned
            out.append(Point(month: idx + 1, cum: running))
        }
        return out
    }

    private var yDomain: ClosedRange<Double> {
        let cums = points.map { $0.cum }
        let lo = min(0, cums.min() ?? 0)
        let hi = max(0, cums.max() ?? 0)
        let pad = max(1, (hi - lo) * 0.12)
        return (lo - pad)...(hi + pad)
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Savings building up")
                    .font(summitNumber(17, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                if points.isEmpty {
                    Text("No budgets saved in this year yet.")
                        .font(summitBody(13))
                        .foregroundStyle(theme.color("muted"))
                } else {
                    chart
                    Text(caption)
                        .font(summitBody(12))
                        .foregroundStyle(theme.color("muted"))
                }
            }
        }
    }

    private var caption: String {
        let end = points.last?.cum ?? 0
        let word = end < 0 ? "Overspent" : "Saved"
        let n = points.count
        return "Running total of take-home minus planned spending across the \(n) saved month\(n == 1 ? "" : "s"). \(word) \(Formatters.money(abs(end))) so far."
    }

    private var chart: some View {
        Chart {
            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(theme.color("line"))
                .lineStyle(StrokeStyle(lineWidth: 0.8, dash: [3, 4]))

            ForEach(points) { p in
                AreaMark(x: .value("Month", p.month), y: .value("Saved", p.cum))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.color("good").opacity(0.32), theme.color("good").opacity(0.03)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.linear)
                LineMark(x: .value("Month", p.month), y: .value("Saved", p.cum))
                    .foregroundStyle(theme.color("good"))
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round))
                    .interpolationMethod(.linear)
            }

            if let last = points.last {
                PointMark(x: .value("Month", last.month), y: .value("Saved", last.cum))
                    .foregroundStyle(theme.color("good"))
                    .symbolSize(60)
                    .annotation(position: .top, spacing: 4) {
                        Text(Formatters.money(last.cum))
                            .font(summitNumber(11, weight: .semibold))
                            .foregroundStyle(theme.color("deep"))
                    }
            }
        }
        .chartXScale(domain: 1...12)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: Array(1...12)) { value in
                if let m = value.as(Int.self) {
                    AxisValueLabel {
                        Text(monthLetter(m - 1))
                            .font(summitBody(10))
                            .foregroundStyle(theme.color("muted"))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(theme.color("line").opacity(0.5))
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(compactMoney(d))
                            .font(summitBody(10))
                            .foregroundStyle(theme.color("muted"))
                    }
                }
            }
        }
        .frame(height: 170)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: points.count)
    }
}

// MARK: - Category spending breakdown for the year

struct YearCategoryChart: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store

    private struct Slice: Identifiable {
        let name: String
        let total: Double
        let colorIndex: Int
        var id: String { name }
    }

    // Sum every category's planned total (BudgetMath.catTotal) across the months
    // present this year, keyed by category name. Top 6 by total.
    private var slices: [Slice] {
        var sums: [String: Double] = [:]
        var order: [String] = []
        for e in store.yearAggregate() where e.has {
            guard let m = store.db.months[e.key] else { continue }
            for c in m.cats {
                if sums[c.n] == nil { order.append(c.n) }
                sums[c.n, default: 0] += BudgetMath.catTotal(c)
            }
        }
        let ranked = order
            .map { (name: $0, total: sums[$0] ?? 0) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
            .prefix(6)
        return ranked.enumerated().map { Slice(name: $0.element.name, total: $0.element.total, colorIndex: $0.offset) }
    }

    private var xMax: Double {
        max(1, (slices.map { $0.total }.max() ?? 1) * 1.18)
    }

    // Domain smallest→largest so the biggest bar sits at the top of the axis.
    private var yOrder: [String] { Array(slices.map { $0.name }.reversed()) }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Where the money is planned")
                    .font(summitNumber(17, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                if slices.isEmpty {
                    Text("No budgets saved in this year yet.")
                        .font(summitBody(13))
                        .foregroundStyle(theme.color("muted"))
                } else {
                    chart
                    Text("Top \(slices.count) categories by planned spending, added up across every saved month this year.")
                        .font(summitBody(12))
                        .foregroundStyle(theme.color("muted"))
                }
            }
        }
    }

    private var chart: some View {
        Chart(slices) { row in
            BarMark(
                x: .value("Planned", row.total),
                y: .value("Category", row.name)
            )
            .foregroundStyle(Color(hex: BudgetDefaults.colors[row.colorIndex % BudgetDefaults.colors.count]) ?? theme.color("primaryStrong"))
            .cornerRadius(5)
            .annotation(position: .trailing, spacing: 4) {
                Text(compactMoney(row.total))
                    .font(summitBody(10, weight: .semibold))
                    .foregroundStyle(theme.color("muted"))
            }
        }
        .chartXScale(domain: 0...xMax)
        .chartYScale(domain: yOrder)
        .chartXAxis {
            AxisMarks(position: .bottom, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(theme.color("line").opacity(0.5))
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(compactMoney(d))
                            .font(summitBody(10))
                            .foregroundStyle(theme.color("muted"))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let s = value.as(String.self) {
                        Text(s)
                            .font(summitBody(11))
                            .foregroundStyle(theme.color("text"))
                    }
                }
            }
        }
        .frame(height: CGFloat(slices.count) * 34 + 24)
    }
}

// MARK: - Small shared helpers (file-scope)

private func monthLetter(_ index: Int) -> String {
    let letters = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
    return letters[((index % 12) + 12) % 12]
}

// Compact money for axis ticks: $450, $1.2k, $12k.
private func compactMoney(_ n: Double) -> String {
    let sign = n < 0 ? "\u{2212}" : ""
    let v = abs(n)
    if v >= 1000 {
        let k = v / 1000
        let s = k >= 10 ? String(format: "%.0f", k) : String(format: "%.1f", k)
        return sign + "$" + s + "k"
    }
    return sign + "$" + String(format: "%.0f", v)
}
