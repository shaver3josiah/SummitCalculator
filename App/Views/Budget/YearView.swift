import SwiftUI
import Charts
import SummitCore

struct YearWrap: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store

    private var entries: [BudgetYearEntry] { store.yearAggregate() }

    private var maxValue: Double {
        let values = entries.flatMap { [$0.planned, $0.takeHome] }
        return max(1, (values.max() ?? 1) * 1.1)
    }

    private var existingKeys: [String] {
        store.db.months.keys.filter { BudgetMath.parseYM($0)?.year == store.yearSel }.sorted()
    }

    var body: some View {
        VStack(spacing: 16) {
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    legendLine
                    yearChart
                    headRow
                    monthRows
                }
            }
            YearSavingsChart()
            YearCategoryChart()
        }
    }

    private var header: some View {
        HStack {
            Text("The year at a glance")
                .font(summitNumber(17, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
            Spacer()
            HStack(spacing: 6) {
                EncirclePressButton(cornerRadius: 12, lineWidth: 1.5) {
                    store.shiftYear(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Previous year")
                EncirclePressButton(cornerRadius: 12, lineWidth: 1.5) {
                    store.shiftYear(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Next year")
            }
            .foregroundStyle(theme.color("primaryStrong"))
        }
    }

    private var legendLine: some View {
        HStack(spacing: 4) {
            Circle().fill(theme.color("good")).frame(width: 8, height: 8)
            Text("take-home")
                .font(summitBody(12))
                .foregroundStyle(theme.color("muted"))
            Text("\u{2002}\u{2002}")
            Circle().fill(theme.color("primaryStrong")).frame(width: 8, height: 8)
            Text("planned spending. Tap a month below to open it.")
                .font(summitBody(12))
                .foregroundStyle(theme.color("muted"))
        }
    }

    private var yearChart: some View {
        Chart {
            ForEach(Array(entries.enumerated()), id: \.offset) { pair in
                let (idx, entry) = pair
                if entry.has {
                    BarMark(
                        x: .value("Month", Double(idx + 1)),
                        y: .value("Take-home", entry.takeHome),
                        width: .ratio(0.32)
                    )
                    .foregroundStyle(theme.color("good").opacity(0.45))
                    .position(by: .value("Series", "th"))
                    BarMark(
                        x: .value("Month", Double(idx + 1)),
                        y: .value("Planned", entry.planned),
                        width: .ratio(0.32)
                    )
                    .foregroundStyle(theme.color("primaryStrong"))
                    .position(by: .value("Series", "pl"))
                }
            }
        }
        .chartYScale(domain: 0...maxValue)
        .chartXScale(domain: 0.5...12.5)
        .chartXAxis {
            AxisMarks(values: (1...12).map(Double.init)) { value in
                if let m = value.as(Double.self) {
                    AxisValueLabel {
                        Text(monthLetter(Int(m) - 1))
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .frame(height: 150)
    }

    private func monthLetter(_ index: Int) -> String {
        let letters = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
        return letters[index]
    }

    private var headRow: some View {
        HStack {
            Text("Month").font(summitBody(11, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading)
            Text("Take-home").font(summitBody(11, weight: .semibold)).frame(maxWidth: .infinity, alignment: .trailing)
            Text("Planned").font(summitBody(11, weight: .semibold)).frame(maxWidth: .infinity, alignment: .trailing)
            Text("Left").font(summitBody(11, weight: .semibold)).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .foregroundStyle(theme.color("muted"))
    }

    @ViewBuilder
    private var monthRows: some View {
        if existingKeys.isEmpty {
            Text("No budgets saved in this year yet.")
                .font(summitBody(13))
                .foregroundStyle(theme.color("muted"))
        } else {
            VStack(spacing: 8) {
                ForEach(existingKeys, id: \.self) { key in
                    yearRow(key)
                }
                totalsRow
            }
        }
    }

    private func yearRow(_ key: String) -> some View {
        let m = store.db.months[key]
        let th = m.map { BudgetMath.takeHome(of: $0) } ?? 0
        let pl = m.map { BudgetMath.planned(of: $0) } ?? 0
        let left = th - pl
        let isCurrent = key == store.db.cur
        return Button {
            store.switchMonth(to: key)
            store.view = "month"
        } label: {
            HStack {
                Text(String(BudgetMath.monthLabel(key).prefix(3)) + " " + key.prefix(4))
                    .font(summitBody(13, weight: isCurrent ? .semibold : .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(Formatters.money(th)).font(summitBody(13)).frame(maxWidth: .infinity, alignment: .trailing)
                Text(Formatters.money(pl)).font(summitBody(13)).frame(maxWidth: .infinity, alignment: .trailing)
                Text((left < 0 ? "\u{2212}" : "") + Formatters.money(abs(left)))
                    .font(summitBody(13, weight: .semibold))
                    .foregroundStyle(left < 0 ? theme.color("deep") : theme.color("good"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .foregroundStyle(theme.color("text"))
        }
        .buttonStyle(.plain)
    }

    private var totalsRow: some View {
        let months = existingKeys.compactMap { store.db.months[$0] }
        let totalTh = months.reduce(0) { $0 + BudgetMath.takeHome(of: $1) }
        let totalPl = months.reduce(0) { $0 + BudgetMath.planned(of: $1) }
        let totalLeft = totalTh - totalPl
        return HStack {
            Text("Year so far").font(summitBody(13, weight: .semibold)).frame(maxWidth: .infinity, alignment: .leading)
            Text(Formatters.money(totalTh)).font(summitBody(13, weight: .semibold)).frame(maxWidth: .infinity, alignment: .trailing)
            Text(Formatters.money(totalPl)).font(summitBody(13, weight: .semibold)).frame(maxWidth: .infinity, alignment: .trailing)
            Text((totalLeft < 0 ? "\u{2212}" : "") + Formatters.money(abs(totalLeft)))
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(totalLeft < 0 ? theme.color("deep") : theme.color("good"))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .foregroundStyle(theme.color("text"))
        .padding(.top, 4)
    }
}
