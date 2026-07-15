import SwiftUI
import SummitCore

struct GoalsCard: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("Spending goals")
                    .font(summitNumber(17, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                Text("Tick a category checkbox (or single rows) to watch it. Each one gets its own line, paced across this month.")
                    .font(summitBody(12))
                    .foregroundStyle(theme.color("muted"))

                let active = store.activeCategories()
                if active.isEmpty {
                    Text("Nothing selected yet. Tap a checkbox next to any category to graph it.")
                        .font(summitBody(13))
                        .foregroundStyle(theme.color("muted"))
                } else {
                    VStack(spacing: 10) {
                        ForEach(active, id: \.index) { entry in
                            goalRow(entry)
                        }
                    }
                    BudgetChart(active: active)
                    legend(active)
                }

                Text("Even-pace projection: each line spreads its monthly amount across the days of this month. Goals compare against the month-end total. Saved on this device.")
                    .font(summitBody(11))
                    .foregroundStyle(theme.color("muted"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func goalRow(_ entry: (index: Int, category: BudgetCategory, sel: Double)) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: BudgetDefaults.colors[entry.index % BudgetDefaults.colors.count]) ?? theme.color("primaryStrong"))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.category.n)
                    .font(summitBody(13, weight: .semibold))
                    .foregroundStyle(theme.color("text"))
                Text("\(Formatters.money(entry.sel)) / mo selected")
                    .font(summitBody(10))
                    .foregroundStyle(theme.color("muted"))
            }
            Spacer()
            TextField(String(format: "%.0f", BudgetMath.jsRound(entry.sel)), text: goalBinding(entry.index), prompt: Text(String(format: "%.0f", BudgetMath.jsRound(entry.sel))).foregroundStyle(theme.color("muted")))
                .keyboardType(.decimalPad)
                .font(summitBody(13))
                .frame(width: 70)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(theme.color("surfaceSoft"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            verdictText(entry)
        }
    }

    private func verdictText(_ entry: (index: Int, category: BudgetCategory, sel: Double)) -> some View {
        let goal = entry.category.goal
        let text: String
        let color: Color
        if goal == nil {
            text = "set a goal"
            color = theme.color("muted")
        } else if entry.sel <= goal! {
            text = "fits \u{B7} \(Formatters.money(goal! - entry.sel)) room"
            color = theme.color("good")
        } else {
            text = "over by \(Formatters.money(entry.sel - goal!))"
            color = theme.color("deep")
        }
        return Text(text)
            .font(summitBody(11, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 92, alignment: .trailing)
    }

    private func legend(_ active: [(index: Int, category: BudgetCategory, sel: Double)]) -> some View {
        let days = store.monthDays
        let today = store.todayDay
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(active, id: \.index) { entry in
                    legendChip(entry, days: days, today: today)
                }
                if active.count > 1 {
                    allSelectedChip(active)
                }
            }
        }
    }

    private func legendChip(_ entry: (index: Int, category: BudgetCategory, sel: Double), days: Int, today: Int?) -> some View {
        let perDay = BudgetMath.perDay(sel: entry.sel, days: days)
        var text = "\(entry.category.n) \u{B7} \(Formatters.money(perDay))/day"
        if let today {
            let byToday = BudgetMath.byToday(sel: entry.sel, today: today, days: days)
            text += " \u{B7} \(Formatters.money(byToday)) by today"
        }
        return HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: BudgetDefaults.colors[entry.index % BudgetDefaults.colors.count]) ?? theme.color("primaryStrong"))
                .frame(width: 8, height: 8)
            Text(text)
                .font(summitBody(11, weight: .medium))
                .foregroundStyle(theme.color("text"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(theme.color("surfaceSoft")))
    }

    private func allSelectedChip(_ active: [(index: Int, category: BudgetCategory, sel: Double)]) -> some View {
        let total = active.reduce(0) { $0 + $1.sel }
        return HStack(spacing: 6) {
            Circle()
                .fill(theme.color("deep"))
                .frame(width: 8, height: 8)
            Text("All selected \u{B7} \(Formatters.money(total)) / mo")
                .font(summitBody(11, weight: .medium))
                .foregroundStyle(theme.color("text"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(theme.color("surfaceSoft")))
    }

    private func goalBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: {
                guard let goal = store.month.cats[safe: index]?.goal else { return "" }
                return Formatters.plain(goal)
            },
            set: { newValue in
                if newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                    store.setGoal(index, value: nil)
                } else {
                    store.setGoal(index, value: Double(newValue) ?? 0)
                }
            }
        )
    }
}
