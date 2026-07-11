import SwiftUI
import SummitCore

struct ProjectionView: View {
    @Environment(ThemeStore.self) private var themeStore
    @State private var selectedPanel = "Grow"

    private let panels = ["Grow", "Retire", "Match", "Real rate", "Compare", "Rule of 72"]

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
        case "Retire":
            RetirePanel()
        case "Match":
            MatchPanel()
        case "Real rate":
            RealRatePanel()
        case "Compare":
            ComparePanel()
        default:
            RuleOf72Panel()
        }
    }
}
