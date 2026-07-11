import SwiftUI
import SummitCore

struct MonthWrap: View {
    var body: some View {
        VStack(spacing: 16) {
            IncomeCard()
            StatsRow()
            CategoriesSection()
            GoalsCard()
        }
    }
}
