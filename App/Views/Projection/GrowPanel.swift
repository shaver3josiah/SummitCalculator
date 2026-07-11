import SwiftUI
import Charts
import SummitCore

struct GrowPanel: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(ProjectionStore.self) private var projectionStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @State private var principalText = "10000"
    @State private var monthlyText = "500"
    @State private var years: Double = 20
    @State private var selectedFundID: UUID?
    @State private var showResult = false
    @State private var yearlyBalances: [YearBalance] = []
    @State private var futureValueResult: Double = 0
    @State private var contributionsResult: Double = 0

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ProjectionFieldRow(
                    leftLabel: "Starting amount",
                    leftText: $principalText,
                    rightLabel: "Monthly added",
                    rightText: $monthlyText
                )
                yearsSlider
                fundPicker
                ProjectionCalcButton(label: "Project the summit", action: calculate)
                if showResult {
                    resultSection
                }
                ProjectionDisclaimer(text: "Illustrative projection using a fixed annual rate, compounded monthly. Not financial advice, and no live trading.")
            }
        }
        .onAppear {
            if selectedFundID == nil {
                selectedFundID = projectionStore.funds.first?.id
            }
        }
    }

    private var yearsSlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Years to grow: \(Int(years))")
                .font(summitBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
            Slider(value: $years, in: 1...40, step: 1)
                .tint(themeStore.color("primaryStrong"))
        }
    }

    private var fundPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose a fund profile")
                .font(summitBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(projectionStore.funds) { fund in
                        fundChip(fund)
                    }
                }
            }
        }
    }

    private func fundChip(_ fund: Fund) -> some View {
        let isSelected = fund.id == selectedFundID
        return Button {
            selectedFundID = fund.id
        } label: {
            VStack(spacing: 2) {
                Text(fund.name)
                    .font(summitBody(12, weight: .semibold))
                Text("\(Formatters.plain(fund.ratePct))%")
                    .font(summitBody(10))
            }
            .foregroundStyle(isSelected ? .white : themeStore.color("text"))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? themeStore.color("primaryStrong") : themeStore.color("surfaceSoft"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SummitLogo(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("PROJECTED VALUE")
                        .font(summitBody(10, weight: .semibold))
                        .foregroundStyle(themeStore.color("muted"))
                    RollingNumberText(
                        text: Formatters.money(futureValueResult),
                        font: summitNumber(28, weight: .semibold),
                        color: themeStore.color("deep")
                    )
                }
            }
            HStack(spacing: 20) {
                ProjectionResultStat(label: "You put in", value: Formatters.money(contributionsResult))
                ProjectionResultStat(label: "Growth", value: Formatters.money(futureValueResult - contributionsResult), isGrowth: true)
            }
            if !yearlyBalances.isEmpty {
                growthChart
            }
        }
    }

    private var growthChart: some View {
        Chart(yearlyBalances) { point in
            AreaMark(
                x: .value("Year", point.year),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(themeStore.color("primary").opacity(0.25))
            LineMark(
                x: .value("Year", point.year),
                y: .value("Balance", point.balance)
            )
            .foregroundStyle(themeStore.color("primaryStrong"))
        }
        .frame(height: 150)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .animation(.easeOut(duration: 0.6), value: yearlyBalances.count)
    }

    private func calculate() {
        let principal = Double(principalText) ?? 0
        let monthly = Double(monthlyText) ?? 0
        let rate = projectionStore.funds.first { $0.id == selectedFundID }?.ratePct ?? 6

        futureValueResult = FinanceMath.futureValue(principal: principal, monthly: monthly, annualRatePct: rate, years: years)
        contributionsResult = FinanceMath.contributions(principal: principal, monthly: monthly, years: years)

        var points: [YearBalance] = []
        let totalYears = max(Int(years), 1)
        for year in 0...totalYears {
            let balance = FinanceMath.futureValue(principal: principal, monthly: monthly, annualRatePct: rate, years: Double(year))
            points.append(YearBalance(year: year, balance: balance))
        }
        yearlyBalances = points
        showResult = true

        historyStore.add(
            type: "proj",
            title: "Grow",
            value: Formatters.money(futureValueResult),
            extra: [
                "principal": principalText,
                "monthly": monthlyText,
                "years": String(Int(years)),
                "ratePct": Formatters.plain(rate)
            ]
        )
        soundStore.play("success")
    }
}

private struct YearBalance: Identifiable {
    let year: Int
    let balance: Double
    var id: Int { year }
}
