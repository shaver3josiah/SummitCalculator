import SwiftUI
import SummitCore

struct ProjectionView: View {
    @Environment(ThemeStore.self) private var themeStore
    @State private var selectedPanel = "Grow"

    private let panels = ["Grow", "Baby", "Trump", "Whole life", "Retire", "Match", "Real rate", "Compare", "Rule of 72", "Beat market"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                KTabBar(items: panels, selection: $selectedPanel)
                panelContent
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private var panelContent: some View {
        switch selectedPanel {
        case "Grow":
            GrowPanel()
        case "Baby":
            BabyPanel()
        case "Trump":
            TrumpPanel()
        case "Whole life":
            WholeLifePanel()
        case "Retire":
            RetirePanel()
        case "Match":
            MatchPanel()
        case "Real rate":
            RealRatePanel()
        case "Compare":
            ComparePanel()
        case "Beat market":
            ReturnsChart()
        default:
            RuleOf72Panel()
        }
    }
}
