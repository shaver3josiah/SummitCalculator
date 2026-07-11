import SwiftUI
import SummitCore

struct StatsRow: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store

    var body: some View {
        HStack(spacing: 0) {
            stat(label: "Take-home / mo", value: Formatters.money(store.takeHome), color: theme.color("good"))
            stat(label: "Planned", value: Formatters.money(store.planned), color: theme.color("text"))
            leftOverStat
        }
    }

    private var leftOverStat: some View {
        let negative = store.leftOver < 0
        let text = (negative ? "\u{2212}" : "") + Formatters.money(abs(store.leftOver))
        return stat(label: "Left over", value: text, color: negative ? theme.color("deep") : theme.color("good"))
    }

    private func stat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(summitBody(11, weight: .medium))
                .foregroundStyle(theme.color("muted"))
            Text(value)
                .font(summitNumber(18, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
