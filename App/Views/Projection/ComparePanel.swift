import SwiftUI
import Charts
import SummitCore

struct ComparePanel: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(ProjectionStore.self) private var projectionStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @State private var monthlyText = "500"
    @State private var yearsText = "20"
    @State private var startText = "10000"
    @State private var showResult = false
    @State private var series: [FundSeries] = []

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ProjectionFieldRow(leftLabel: "Monthly added", leftText: $monthlyText, rightLabel: "Years", rightText: $yearsText)
                ProjectionFormField(label: "Starting balance", text: $startText)
                ProjectionCalcButton(label: "Compare the fund profiles", action: calculate)
                if showResult {
                    compareChart
                    fundLegend
                }
                ProjectionDisclaimer(text: "Illustrative only. Same contributions across your saved fund profiles. Not financial advice.")
            }
        }
    }

    private var compareChart: some View {
        Chart {
            ForEach(series) { fundSeries in
                ForEach(fundSeries.points) { point in
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Balance", point.balance)
                    )
                    .foregroundStyle(by: .value("Fund", fundSeries.name))
                }
            }
        }
        .chartForegroundStyleScale(range: chartColors)
        .frame(height: 170)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .animation(.easeOut(duration: 0.6), value: series.count)
    }

    private var chartColors: [Color] {
        [themeStore.color("primary"), themeStore.color("primaryStrong"), themeStore.color("deep"), themeStore.color("good")]
    }

    private var fundLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(series) { fundSeries in
                HStack {
                    Text(fundSeries.name)
                        .font(summitBody(13, weight: .medium))
                        .foregroundStyle(themeStore.color("text"))
                    Spacer()
                    Text(Formatters.money(fundSeries.finalBalance))
                        .font(summitBody(13, weight: .semibold))
                        .foregroundStyle(themeStore.color("good"))
                }
            }
        }
    }

    private func calculate() {
        let monthly = Double(monthlyText) ?? 0
        let years = Double(yearsText) ?? 0
        let start = Double(startText) ?? 0
        let totalYears = max(Int(years), 1)

        series = projectionStore.funds.map { fund in
            var points: [FundPoint] = []
            for year in 0...totalYears {
                let balance = FinanceMath.futureValue(principal: start, monthly: monthly, annualRatePct: fund.ratePct, years: Double(year))
                points.append(FundPoint(year: year, balance: balance))
            }
            let final = points.last?.balance ?? 0
            return FundSeries(id: fund.id, name: fund.name, points: points, finalBalance: final)
        }
        showResult = true

        var extra = ["monthly": monthlyText, "years": yearsText, "start": startText]
        for fundSeries in series {
            extra[fundSeries.name] = Formatters.money(fundSeries.finalBalance)
        }
        historyStore.add(type: "proj", title: "Compare", value: "\(series.count) funds", extra: extra)
        soundStore.play("success")
    }
}

private struct FundPoint: Identifiable {
    let year: Int
    let balance: Double
    var id: Int { year }
}

private struct FundSeries: Identifiable {
    let id: UUID
    let name: String
    let points: [FundPoint]
    let finalBalance: Double
}
