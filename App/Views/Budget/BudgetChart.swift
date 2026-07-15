import SwiftUI
import Charts
import SummitCore

struct BudgetChart: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var active: [(index: Int, category: BudgetCategory, sel: Double)]

    private var days: Int { store.monthDays }
    private var today: Int? { store.todayDay }

    private var yMax: Double {
        let sels = active.map { $0.sel }
        let goals = active.compactMap { $0.category.goal }
        return BudgetMath.chartYMax(sels: sels, goals: goals)
    }

    private var headroomBase: Double { yMax / 1.08 }

    private var aggregateTotal: Double {
        active.reduce(0) { $0 + $1.sel }
    }

    var body: some View {
        Chart {
            ForEach([0.5, 1.0], id: \.self) { fraction in
                RuleMark(y: .value("Grid", headroomBase * fraction))
                    .foregroundStyle(theme.color("line"))
                    .lineStyle(StrokeStyle(lineWidth: 0.6, dash: [3, 4]))
            }

            if active.count > 1 {
                LineMark(x: .value("Day", 0), y: .value("Amount", 0))
                    .foregroundStyle(theme.color("deep").opacity(0.55))
                    .lineStyle(StrokeStyle(lineWidth: 1.6, dash: [6, 4]))
                    .interpolationMethod(.linear)
                LineMark(x: .value("Day", Double(days)), y: .value("Amount", aggregateTotal))
                    .foregroundStyle(theme.color("deep").opacity(0.55))
                    .lineStyle(StrokeStyle(lineWidth: 1.6, dash: [6, 4]))
                    .interpolationMethod(.linear)
            }

            ForEach(active, id: \.index) { entry in
                let color = Color(hex: BudgetDefaults.colors[entry.index % BudgetDefaults.colors.count]) ?? theme.color("primaryStrong")

                LineMark(x: .value("Day", 0), y: .value("Amount", 0), series: .value("Category", entry.category.n))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round))
                LineMark(x: .value("Day", Double(days)), y: .value("Amount", entry.sel), series: .value("Category", entry.category.n))
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round))

                if let today {
                    let byToday = BudgetMath.byToday(sel: entry.sel, today: today, days: days)
                    PointMark(x: .value("Day", Double(today)), y: .value("Amount", byToday))
                        .foregroundStyle(color)
                        .symbolSize(50)
                }

                if let goal = entry.category.goal, goal > 0 {
                    PointMark(x: .value("Day", Double(days)), y: .value("Amount", goal))
                        .symbolSize(1)
                        .foregroundStyle(.clear)
                        .annotation(position: .overlay) {
                            Circle()
                                .strokeBorder(color, lineWidth: 1.8)
                                .frame(width: 9, height: 9)
                        }
                }
            }
        }
        .chartXScale(domain: 0...Double(days))
        .chartYScale(domain: 0...yMax)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .accessibilityLabel("Spending pace chart")
        .accessibilityValue("\(active.count) \(active.count == 1 ? "category" : "categories") paced over \(days) days, \(Formatters.money(aggregateTotal)) at month end")
        .frame(height: 170)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: active.map { $0.sel })
    }
}
