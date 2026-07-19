import SwiftUI
import Charts
import SummitCore

/// Historical-growth tool for a home or a piece of land. No "calculate" button:
/// the chart and the numbers are LIVE — they redraw the instant she changes a
/// value, which is the whole point of putting it in Tools. The rate is seeded
/// from a long-run historical average per kind and is fully editable.
struct RealEstateCard: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Long-run US averages, editable. Homes track roughly 4–5%/yr nominal over
    // decades; raw land is appreciation-only and historically a touch slower.
    private static let homeRate = 4.5
    private static let landRate = 3.9

    @State private var currentValueText: String = "300000"
    @State private var rateText: String = "4.5"
    @State private var yearsText: String = "20"
    @State private var netYieldText: String = "0"
    @State private var kind: String = "home"

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                header
                kindPicker
                ProjectionFieldRow(
                    leftLabel: "Value today",
                    leftText: $currentValueText,
                    rightLabel: "Growth %/yr",
                    rightText: $rateText
                )
                yearsSlider
                ProjectionFormField(label: "Net rental yield %/yr (optional)", text: $netYieldText)
                Text(isLand
                     ? "Land usually earns no rent and carries taxes — leave yield at 0, or make it negative for carrying costs."
                     : "Rent received minus upkeep, as a % of value. Leave at 0 for appreciation only.")
                    .font(summitBody(11))
                    .foregroundStyle(themeStore.color("muted"))

                liveResult
                chart
                logButton
                ProjectionDisclaimer(text: "Uses a fixed historical-average growth rate — a look at the past, not a forecast. Property is illiquid and carries taxes, upkeep and risk. Not financial advice.")
            }
        }
    }

    // MARK: derived (all live)

    private var isLand: Bool { kind == "land" }
    private var currentValue: Double { Double(currentValueText) ?? 0 }
    private var rate: Double { Double(rateText) ?? Self.homeRate }
    private var netYield: Double { Double(netYieldText) ?? 0 }
    private var years: Int { max(1, Int(Double(yearsText) ?? 20)) }

    private var futureValue: Double {
        FinanceMath.appreciatedValue(currentValue: currentValue, annualRatePct: rate, years: Double(years), netYieldPct: netYield)
    }
    private var points: [RealEstatePoint] {
        FinanceMath.appreciationSeries(currentValue: currentValue, annualRatePct: rate, years: years, netYieldPct: netYield)
            .enumerated().map { RealEstatePoint(year: $0.offset, value: $0.element) }
    }

    // MARK: sub-views

    private var header: some View {
        Text("Real estate growth")
            .font(summitNumber(17, weight: .semibold))
            .foregroundStyle(themeStore.color("deep"))
    }

    private var kindPicker: some View {
        HStack(spacing: 10) {
            kindChoice("home", label: "Home", rate: Self.homeRate)
            kindChoice("land", label: "Land", rate: Self.landRate)
        }
    }

    private func kindChoice(_ id: String, label: String, rate: Double) -> some View {
        let selected = kind == id
        return Button {
            withAnimation(SummitMotion.springSoft) {
                kind = id
                rateText = Formatters.plain(rate)
            }
        } label: {
            Text(label)
                .font(summitBody(13, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? .white : themeStore.color("text"))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(selected ? themeStore.color("primaryStrong") : themeStore.color("surfaceSoft"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var yearsSlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Over \(years) years")
                .font(summitBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
            Slider(
                value: Binding(
                    get: { Double(years) },
                    set: { yearsText = String(Int($0)) }
                ),
                in: 1...40, step: 1
            )
            .tint(themeStore.color("primaryStrong"))
        }
    }

    private var liveResult: some View {
        HStack(spacing: 20) {
            ProjectionResultStat(label: "Value then", value: Formatters.money(futureValue), isGrowth: true)
            ProjectionResultStat(label: "Total gain", value: Formatters.money(max(futureValue - currentValue, 0)))
        }
    }

    private var chart: some View {
        Chart(points) { point in
            AreaMark(x: .value("Year", point.year), y: .value("Value", point.value))
                .foregroundStyle(themeStore.color("primary").opacity(0.25))
            LineMark(x: .value("Year", point.year), y: .value("Value", point.value))
                .foregroundStyle(themeStore.color("primaryStrong"))
        }
        .frame(height: 150)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .accessibilityLabel("Property value over time")
        .accessibilityValue("From \(Formatters.money(currentValue)) to \(Formatters.money(futureValue)) over \(years) years")
        // LIVE: redraw whenever any input changes.
        .animation(reduceMotion ? nil : .easeOut(duration: 0.4), value: futureValue)
    }

    private var logButton: some View {
        Button {
            historyStore.add(
                type: "tool",
                title: "Real estate: \(isLand ? "land" : "home")",
                value: Formatters.money(futureValue),
                extra: [
                    "value": currentValueText,
                    "ratePct": rateText,
                    "years": String(years)
                ]
            )
            soundStore.play("success")
            ToastCenter.shared.show(title: "Saved", message: "This projection is in your history.")
        } label: {
            Text("Log to history")
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(themeStore.color("primaryStrong"))
                .frame(minHeight: 44)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct RealEstatePoint: Identifiable {
    let year: Int
    let value: Double
    var id: Int { year }
}
