import SwiftUI
import SummitCore

struct RuleOf72Panel: View {
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @State private var rateText = "8"
    @State private var showResult = false
    @State private var yearsResult: Double = 0

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ProjectionFormField(label: "Return % / yr", text: $rateText)
                ProjectionCalcButton(label: "Years to double", action: calculate)
                if showResult {
                    ProjectionResultStat(label: "Money doubles in about", value: "\(Formatters.plain(yearsResult)) yrs", isGrowth: true)
                }
                ProjectionDisclaimer(text: "Illustrative only. The rule of 72 is a quick estimate. Not financial advice.")
            }
        }
    }

    private func calculate() {
        let rate = Double(rateText) ?? 0
        yearsResult = FinanceMath.ruleOf72(ratePct: rate)
        showResult = true

        historyStore.add(
            type: "proj",
            title: "Rule of 72",
            value: "\(Formatters.plain(yearsResult)) yrs",
            extra: ["ratePct": rateText]
        )
        soundStore.play("success")
    }
}
