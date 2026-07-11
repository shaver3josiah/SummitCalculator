import SwiftUI
import SummitCore

struct MatchPanel: View {
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @State private var salaryText = "80000"
    @State private var yourPctText = "4"
    @State private var matchRateText = "50"
    @State private var matchCapText = "6"
    @State private var showResult = false
    @State private var capturedResult: Double = 0
    @State private var leftOnTableResult: Double = 0

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ProjectionFormField(label: "Annual salary", text: $salaryText)
                ProjectionFieldRow(leftLabel: "You contribute %", leftText: $yourPctText, rightLabel: "Match rate %", rightText: $matchRateText)
                ProjectionFormField(label: "Match up to % of salary", text: $matchCapText)
                ProjectionCalcButton(label: "Check the match", action: calculate)
                if showResult {
                    HStack(spacing: 20) {
                        ProjectionResultStat(label: "Match captured / yr", value: Formatters.money(capturedResult), isGrowth: true)
                        ProjectionResultStat(label: "Left on the table / yr", value: Formatters.money(leftOnTableResult))
                    }
                }
                ProjectionDisclaimer(text: "Illustrative only. Left on the table is the match you are not yet capturing. Not financial advice.")
            }
        }
    }

    private func calculate() {
        let salary = Double(salaryText) ?? 0
        let yourPct = Double(yourPctText) ?? 0
        let matchRate = Double(matchRateText) ?? 0
        let matchCap = Double(matchCapText) ?? 0

        capturedResult = FinanceMath.employerMatch(salary: salary, contribPct: yourPct, matchPct: matchRate, matchLimitPct: matchCap)
        let maxCaptured = FinanceMath.employerMatch(salary: salary, contribPct: matchCap, matchPct: matchRate, matchLimitPct: matchCap)
        leftOnTableResult = max(maxCaptured - capturedResult, 0)
        showResult = true

        historyStore.add(
            type: "proj",
            title: "Match",
            value: Formatters.money(capturedResult),
            extra: [
                "salary": salaryText,
                "yourPct": yourPctText,
                "matchRatePct": matchRateText,
                "matchCapPct": matchCapText
            ]
        )
        soundStore.play("success")
    }
}
