import SwiftUI
import SummitCore

struct RetirePanel: View {
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @State private var ageText = "30"
    @State private var retireAgeText = "65"
    @State private var monthlyText = "600"
    @State private var employerText = "200"
    @State private var rateText = "7"
    @State private var inflationText = "2.5"
    @State private var startText = "25000"
    @State private var showResult = false
    @State private var futureResult: Double = 0
    @State private var todayResult: Double = 0

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ProjectionFieldRow(leftLabel: "Current age", leftText: $ageText, rightLabel: "Retire at", rightText: $retireAgeText)
                ProjectionFieldRow(leftLabel: "You add monthly", leftText: $monthlyText, rightLabel: "Employer monthly", rightText: $employerText)
                ProjectionFieldRow(leftLabel: "Return % / yr", leftText: $rateText, rightLabel: "Inflation % / yr", rightText: $inflationText)
                ProjectionFormField(label: "Starting balance", text: $startText)
                ProjectionCalcButton(label: "See the nest egg", action: calculate)
                if showResult {
                    HStack(spacing: 20) {
                        ProjectionResultStat(label: "At retirement", value: Formatters.money(futureResult))
                        ProjectionResultStat(label: "In today's dollars", value: Formatters.money(todayResult), isGrowth: true)
                    }
                }
                ProjectionDisclaimer(text: "Illustrative only. You enter every assumption. Not financial advice, and no live trading.")
            }
        }
    }

    private func calculate() {
        let age = Double(ageText) ?? 0
        let retireAge = Double(retireAgeText) ?? 0
        let monthly = Double(monthlyText) ?? 0
        let employer = Double(employerText) ?? 0
        let rate = Double(rateText) ?? 0
        let inflation = Double(inflationText) ?? 0
        let start = Double(startText) ?? 0
        let years = max(retireAge - age, 0)

        let totalMonthly = monthly + employer
        futureResult = FinanceMath.futureValue(principal: start, monthly: totalMonthly, annualRatePct: rate, years: years)
        let real = FinanceMath.realRate(nominalPct: rate, inflationPct: inflation)
        todayResult = FinanceMath.futureValue(principal: start, monthly: totalMonthly, annualRatePct: real, years: years)
        showResult = true

        historyStore.add(
            type: "proj",
            title: "Retire",
            value: Formatters.money(futureResult),
            extra: [
                "age": ageText,
                "retireAge": retireAgeText,
                "monthly": monthlyText,
                "employer": employerText,
                "ratePct": rateText,
                "inflationPct": inflationText,
                "start": startText
            ]
        )
        soundStore.play("success")
    }
}
