import SwiftUI
import SummitCore

struct ToolsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TipSplitCard()
                PercentageCard()
                LoanPaymentCard()
                SavingsGoalCard()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
}

private struct ToolHeader: View {
    @Environment(ThemeStore.self) private var themeStore
    var title: String

    var body: some View {
        Text(title)
            .font(summitNumber(17, weight: .semibold))
            .foregroundStyle(themeStore.color("deep"))
    }
}

private struct TipSplitCard: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @State private var pressEpoch = 0
    @State private var billText = "80"
    @State private var tipPctText = "20"
    @State private var peopleText = "4"
    @State private var showResult = false
    @State private var tipResult: Double = 0
    @State private var totalResult: Double = 0
    @State private var perPersonResult: Double = 0

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeader(title: "Tip and split")
                ProjectionFieldRow(leftLabel: "Bill amount", leftText: $billText, rightLabel: "Tip %", rightText: $tipPctText)
                ProjectionFormField(label: "Split between", text: $peopleText)
                ProjectionCalcButton(label: "Work it out") {
                    calculate()
                    pressEpoch += 1
                }
                .encircleOnPress(pressEpoch, cornerRadius: themeStore.radius * 0.6)
                if showResult {
                    HStack(spacing: 16) {
                        ProjectionResultStat(label: "Tip", value: Formatters.money(tipResult))
                        ProjectionResultStat(label: "Total", value: Formatters.money(totalResult))
                        ProjectionResultStat(label: "Each pays", value: Formatters.money(perPersonResult), isGrowth: true)
                    }
                }
                ProjectionDisclaimer(text: "Illustrative only.")
            }
        }
    }

    private func calculate() {
        let bill = Double(billText) ?? 0
        let tipPct = Double(tipPctText) ?? 0
        let people = Int(peopleText) ?? 1
        let result = FinanceMath.tip(bill: bill, tipPct: tipPct, people: max(people, 1))
        tipResult = result.tip
        totalResult = result.total
        perPersonResult = result.perPerson
        showResult = true

        historyStore.add(
            type: "tool",
            title: "Tip and split",
            value: Formatters.money(perPersonResult),
            extra: ["bill": billText, "tipPct": tipPctText, "people": peopleText]
        )
        soundStore.play("success")
    }
}

private struct PercentageCard: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @State private var pressEpoch = 0
    @State private var mode = "of"
    @State private var aText = "15"
    @State private var bText = "80"
    @State private var showResult = false
    @State private var resultValue: Double = 0

    private let modes = [
        ("of", "What is X percent of Y", "Percent X", "Of Y"),
        ("change", "Percent change from A to B", "From A", "To B"),
        ("discount", "Price after X percent off", "Percent off", "Of price"),
        ("markup", "Cost plus X percent markup", "Percent markup", "Of cost")
    ]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeader(title: "Percentage")
                modePicker
                ProjectionFieldRow(leftLabel: currentLabels.0, leftText: $aText, rightLabel: currentLabels.1, rightText: $bText)
                ProjectionCalcButton(label: "Calculate") {
                    calculate()
                    pressEpoch += 1
                }
                .encircleOnPress(pressEpoch, cornerRadius: themeStore.radius * 0.6)
                if showResult {
                    ProjectionResultStat(label: resultLabel, value: formattedResult, isGrowth: true)
                }
                ProjectionDisclaimer(text: "Illustrative only.")
            }
        }
    }

    private var modePicker: some View {
        Menu {
            ForEach(modes, id: \.0) { entry in
                Button(entry.1) { mode = entry.0 }
            }
        } label: {
            HStack {
                Text(modes.first { $0.0 == mode }?.1 ?? "")
                    .font(summitBody(14))
                    .foregroundStyle(themeStore.color("text"))
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(themeStore.color("muted"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(themeStore.color("surfaceSoft"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var currentLabels: (String, String) {
        let entry = modes.first { $0.0 == mode }
        return (entry?.2 ?? "X", entry?.3 ?? "Y")
    }

    private var resultLabel: String {
        mode == "change" ? "Change" : "Result"
    }

    private var formattedResult: String {
        mode == "change" ? "\(Formatters.plain(resultValue))%" : Formatters.money(resultValue)
    }

    private func calculate() {
        let a = Double(aText) ?? 0
        let b = Double(bText) ?? 0
        switch mode {
        case "of":
            resultValue = FinanceMath.percentOf(a, of: b)
        case "change":
            resultValue = FinanceMath.percentChange(from: a, to: b)
        case "discount":
            resultValue = b - FinanceMath.percentOf(a, of: b)
        default:
            resultValue = b + FinanceMath.percentOf(a, of: b)
        }
        showResult = true

        historyStore.add(
            type: "tool",
            title: "Percentage",
            value: formattedResult,
            extra: ["mode": mode, "a": aText, "b": bText]
        )
        soundStore.play("success")
    }
}

private struct LoanPaymentCard: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @State private var pressEpoch = 0
    @State private var amountText = "20000"
    @State private var rateText = "6"
    @State private var yearsText = "5"
    @State private var showResult = false
    @State private var monthlyResult: Double = 0
    @State private var totalInterestResult: Double = 0

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeader(title: "Loan payment")
                ProjectionFieldRow(leftLabel: "Amount", leftText: $amountText, rightLabel: "Rate % / yr", rightText: $rateText)
                ProjectionFormField(label: "Years", text: $yearsText)
                ProjectionCalcButton(label: "Find the payment") {
                    calculate()
                    pressEpoch += 1
                }
                .encircleOnPress(pressEpoch, cornerRadius: themeStore.radius * 0.6)
                if showResult {
                    HStack(spacing: 20) {
                        ProjectionResultStat(label: "Monthly", value: Formatters.money(monthlyResult), isGrowth: true)
                        ProjectionResultStat(label: "Total interest", value: Formatters.money(totalInterestResult))
                    }
                }
                ProjectionDisclaimer(text: "Illustrative only. Not a loan offer, and not financial advice.")
            }
        }
    }

    private func calculate() {
        let amount = Double(amountText) ?? 0
        let rate = Double(rateText) ?? 0
        let years = Double(yearsText) ?? 0
        monthlyResult = FinanceMath.loanPayment(principal: amount, annualRatePct: rate, years: years)
        totalInterestResult = max(monthlyResult * years * 12 - amount, 0)
        showResult = true

        historyStore.add(
            type: "tool",
            title: "Loan payment",
            value: Formatters.money(monthlyResult),
            extra: ["amount": amountText, "ratePct": rateText, "years": yearsText]
        )
        soundStore.play("success")
    }
}

private struct SavingsGoalCard: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore

    @State private var pressEpoch = 0
    @State private var targetText = "15000"
    @State private var yearsText = "5"
    @State private var rateText = "4"
    @State private var startText = "0"
    @State private var showResult = false
    @State private var monthlyResult: Double = 0

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                ToolHeader(title: "Savings goal")
                ProjectionFieldRow(leftLabel: "Target", leftText: $targetText, rightLabel: "Years", rightText: $yearsText)
                ProjectionFieldRow(leftLabel: "Rate % / yr", leftText: $rateText, rightLabel: "Starting", rightText: $startText)
                ProjectionCalcButton(label: "How much per month") {
                    calculate()
                    pressEpoch += 1
                }
                .encircleOnPress(pressEpoch, cornerRadius: themeStore.radius * 0.6)
                if showResult {
                    HStack(spacing: 20) {
                        ProjectionResultStat(label: "Save monthly", value: Formatters.money(monthlyResult), isGrowth: true)
                        ProjectionResultStat(label: "Note", value: monthlyResult > 0 ? "on track" : "goal met")
                    }
                }
                ProjectionDisclaimer(text: "Illustrative only. Not financial advice.")
            }
        }
    }

    private func calculate() {
        let target = Double(targetText) ?? 0
        let years = Double(yearsText) ?? 0
        let rate = Double(rateText) ?? 0
        let start = Double(startText) ?? 0
        monthlyResult = FinanceMath.savingsGoalPayment(target: target, principal: start, annualRatePct: rate, years: years)
        showResult = true

        historyStore.add(
            type: "tool",
            title: "Savings goal",
            value: Formatters.money(monthlyResult),
            extra: ["target": targetText, "years": yearsText, "ratePct": rateText, "start": startText]
        )
        soundStore.play("success")
    }
}

/// Brief press-feedback ring: on each `epoch` bump, trace the shared
/// `EncircleOutline` around the control, then unmount it after ~1s so it fades
/// away instead of leaving a permanent glow. (EncircleOutline settles at its
/// `settleOpacity` forever, so a lingering mount would stay lit — hence the
/// timed unmount.) Gated behind `theme.shimmerOn`. Shared by ToolsView and
/// MusicView via `.encircleOnPress`.
/// ponytail: plain timed unmount; a stale timer is guarded by `generation`
/// so a rapid re-press never clears a newer ring early.
private struct PressEncircleModifier: ViewModifier {
    @Environment(ThemeStore.self) private var theme
    let epoch: Int
    var cornerRadius: CGFloat = 12
    var lineWidth: CGFloat = 1.5

    @State private var showing = false
    @State private var generation = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if theme.shimmerOn && showing {
                    EncircleOutline(trigger: epoch, cornerRadius: cornerRadius, lineWidth: lineWidth)
                        .transition(.opacity)
                }
            }
            .onChange(of: epoch) { _, newValue in
                guard newValue > 0 else { return }
                showing = true
                generation += 1
                let expected = generation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if generation == expected {
                        withAnimation(.easeOut(duration: 0.35)) { showing = false }
                    }
                }
            }
    }
}

extension View {
    /// Trace the encircle hairline around this control for ~1s whenever `epoch`
    /// bumps. See `PressEncircleModifier`.
    func encircleOnPress(_ epoch: Int, cornerRadius: CGFloat = 12, lineWidth: CGFloat = 1.5) -> some View {
        modifier(PressEncircleModifier(epoch: epoch, cornerRadius: cornerRadius, lineWidth: lineWidth))
    }
}
