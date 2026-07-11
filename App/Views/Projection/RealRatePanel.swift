import SwiftUI
import SummitCore

struct RealRatePanel: View {
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @State private var nominalText = "7"
    @State private var inflationText = "2.5"
    @State private var showResult = false
    @State private var realResult: Double = 0

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ProjectionFieldRow(leftLabel: "Nominal return %", leftText: $nominalText, rightLabel: "Inflation %", rightText: $inflationText)
                ProjectionCalcButton(label: "Find the real rate", action: calculate)
                if showResult {
                    ProjectionResultStat(label: "Real return / yr", value: "\(Formatters.plain(realResult))%", isGrowth: true)
                }
                ProjectionDisclaimer(text: "Illustrative only. Real rate is growth after inflation. Not financial advice.")
            }
        }
    }

    private func calculate() {
        let nominal = Double(nominalText) ?? 0
        let inflation = Double(inflationText) ?? 0
        realResult = FinanceMath.realRate(nominalPct: nominal, inflationPct: inflation)
        showResult = true

        historyStore.add(
            type: "proj",
            title: "Real rate",
            value: "\(Formatters.plain(realResult))%",
            extra: ["nominalPct": nominalText, "inflationPct": inflationText]
        )
        soundStore.play("success")
    }
}
