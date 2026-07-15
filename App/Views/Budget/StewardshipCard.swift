import SwiftUI
import SummitCore

// The structured "give first" home. NOTE: the old default "Giving" budget category
// (Church/charity, Gifts) is intentionally left untouched — no migration or deletion,
// so existing saved months keep their data. This card is the new giving surface.

/// Global give-first preferences. Every field is optional-with-default on decode, so
/// old saves (no file, or a save from before a field existed) load with defaults.
/// The two sub-splits are stored as weights and normalized to 100% when computing
/// dollars, so the group always splits its parent amount exactly.
struct StewardshipSettings: Codable, Equatable {
    var tithePct: Double = 10
    var feastPct: Double = 10
    var poorPct: Double = 10
    var innovationFlat: Double = 100
    // Feasting & Hospitality sub-split
    var vacationPct: Double = 40
    var familyPct: Double = 30
    var friendsPct: Double = 30
    // The Poor & Discipleship sub-split
    var directPct: Double = 60
    var ministryPct: Double = 40

    init() {}

    enum CodingKeys: String, CodingKey {
        case tithePct, feastPct, poorPct, innovationFlat
        case vacationPct, familyPct, friendsPct, directPct, ministryPct
    }

    init(from decoder: Decoder) throws {
        self.init() // start from defaults; only overwrite keys that are present
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func take(_ key: CodingKeys) -> Double? {
            (try? c.decodeIfPresent(Double.self, forKey: key)).flatMap { $0 }
        }
        if let v = take(.tithePct) { tithePct = v }
        if let v = take(.feastPct) { feastPct = v }
        if let v = take(.poorPct) { poorPct = v }
        if let v = take(.innovationFlat) { innovationFlat = v }
        if let v = take(.vacationPct) { vacationPct = v }
        if let v = take(.familyPct) { familyPct = v }
        if let v = take(.friendsPct) { friendsPct = v }
        if let v = take(.directPct) { directPct = v }
        if let v = take(.ministryPct) { ministryPct = v }
    }

    /// Normalize a group of raw weights to fractions summing to 1 (equal split if all zero).
    private static func shares(_ raw: [Double]) -> [Double] {
        let clean = raw.map { max(0, $0) }
        let sum = clean.reduce(0, +)
        guard sum > 0 else { return raw.map { _ in 1.0 / Double(raw.count) } }
        return clean.map { $0 / sum }
    }

    var feastShares: [Double] { Self.shares([vacationPct, familyPct, friendsPct]) }
    var poorShares: [Double] { Self.shares([directPct, ministryPct]) }
}

struct StewardshipCard: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var expandFeast = false
    @State private var expandPoor = false

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                header
                mainRow(
                    title: "Tithe",
                    subtitle: "Off the top, first",
                    pct: bump(\.tithePct),
                    amount: store.titheAmount
                )
                feastRow
                poorRow
                innovationRow
                Rectangle().fill(theme.color("line")).frame(height: 1)
                summary
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Give first")
                .font(summitNumber(17, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
            Text("Set aside before anything else — figured from your gross income of \(Formatters.money(store.grossIncome)) a month.")
                .font(summitBody(12))
                .foregroundStyle(theme.color("muted"))
        }
    }

    // MARK: Feasting (expandable)

    private var feastRow: some View {
        VStack(spacing: 10) {
            mainRow(
                title: "Feasting & Hospitality",
                subtitle: "Vacation, family & friends",
                pct: bump(\.feastPct),
                amount: store.feastAmount,
                expanded: $expandFeast
            )
            if expandFeast {
                VStack(spacing: 8) {
                    subRow("Vacation", weight: bump(\.vacationPct), share: store.stewardship.feastShares[0], group: store.feastAmount)
                    subRow("Family hosting", weight: bump(\.familyPct), share: store.stewardship.feastShares[1], group: store.feastAmount)
                    subRow("Friend hosting", weight: bump(\.friendsPct), share: store.stewardship.feastShares[2], group: store.feastAmount)
                }
                .transition(subTransition)
            }
        }
    }

    // MARK: Poor & Discipleship (expandable)

    private var poorRow: some View {
        VStack(spacing: 10) {
            mainRow(
                title: "The Poor & Discipleship",
                subtitle: "For the poor & ministry",
                pct: bump(\.poorPct),
                amount: store.poorAmount,
                expanded: $expandPoor
            )
            if expandPoor {
                VStack(spacing: 8) {
                    subRow("Direct to the poor", weight: bump(\.directPct), share: store.stewardship.poorShares[0], group: store.poorAmount)
                    subRow("Ministry / discipleship", weight: bump(\.ministryPct), share: store.stewardship.poorShares[1], group: store.poorAmount)
                }
                .transition(subTransition)
            }
        }
    }

    // MARK: Innovation & Tools (flat)

    private var innovationRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Innovation & Tools")
                    .font(summitBody(14, weight: .semibold))
                    .foregroundStyle(theme.color("text"))
                Text("Flat, every month")
                    .font(summitBody(11))
                    .foregroundStyle(theme.color("muted"))
            }
            Spacer(minLength: 8)
            HStack(spacing: 2) {
                Text("$")
                    .font(summitBody(13))
                    .foregroundStyle(theme.color("muted"))
                TextField("0", text: innovationBinding, prompt: Text("0").foregroundStyle(theme.color("muted")))
                    .keyboardType(.decimalPad)
                    .font(summitNumber(14, weight: .semibold))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 64)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(theme.color("surfaceSoft"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: Summary

    private var summary: some View {
        let gross = store.grossIncome
        let given = store.givenFirstTotal
        let pct = gross > 0 ? given / gross * 100 : 0
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Given first")
                    .font(summitBody(14, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                Spacer()
                Text("\(Formatters.money(given))  ·  \(pctLabel(pct)) of gross")
                    .font(summitNumber(14, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
            }
            HStack {
                Text("Left after giving")
                    .font(summitBody(12))
                    .foregroundStyle(theme.color("muted"))
                Spacer()
                Text(Formatters.money(max(0, gross - given)))
                    .font(summitNumber(13, weight: .semibold))
                    .foregroundStyle(theme.color("good"))
            }
            Text("Take-home this month is \(Formatters.money(store.takeHome)) after taxes & retirement.")
                .font(summitBody(11))
                .foregroundStyle(theme.color("muted"))
        }
    }

    // MARK: Row builders

    private func mainRow(title: String, subtitle: String, pct: Binding<Double>, amount: Double, expanded: Binding<Bool>? = nil) -> some View {
        HStack(spacing: 10) {
            if let expanded {
                Button {
                    toggle(expanded)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.color("muted"))
                        .rotationEffect(.degrees(expanded.wrappedValue ? 90 : 0))
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 44)
                .contentShape(Rectangle())
                .accessibilityLabel(expanded.wrappedValue ? "Collapse \(title)" : "Expand \(title)")
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(summitBody(14, weight: .semibold))
                    .foregroundStyle(theme.color("text"))
                Text(subtitle)
                    .font(summitBody(11))
                    .foregroundStyle(theme.color("muted"))
            }
            Spacer(minLength: 6)
            stepPill(display: pctLabel(pct.wrappedValue), value: pct, step: 1)
            Text(Formatters.money(amount))
                .font(summitNumber(14, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
                .frame(minWidth: 62, alignment: .trailing)
        }
    }

    private func subRow(_ title: String, weight: Binding<Double>, share: Double, group: Double) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(summitBody(13))
                .foregroundStyle(theme.color("text"))
            Spacer(minLength: 6)
            // Pill shows the LIVE normalized share; +/- nudge the raw weight, so the
            // three always split to 100% of the parent amount no matter the taps.
            stepPill(display: pctLabel(share * 100), value: weight, step: 5)
            Text(Formatters.money(group * share))
                .font(summitNumber(13, weight: .semibold))
                .foregroundStyle(theme.color("good"))
                .frame(minWidth: 62, alignment: .trailing)
        }
        .padding(.leading, 34)
    }

    /// −  value  +  control. Mutates `value` (clamped 0...100); `display` is what shows,
    /// which for sub-splits is the normalized share rather than the raw weight.
    private func stepPill(display: String, value: Binding<Double>, step: Double) -> some View {
        HStack(spacing: 6) {
            stepButton("minus") { value.wrappedValue = max(0, value.wrappedValue - step) }
            Text(display)
                .font(summitNumber(13, weight: .semibold))
                .foregroundStyle(theme.color("text"))
                .frame(minWidth: 38)
            stepButton("plus") { value.wrappedValue = min(100, value.wrappedValue + step) }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surfaceSoft")))
    }

    private func stepButton(_ systemName: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(theme.color("primaryStrong"))
        }
        .buttonStyle(.plain)
        .frame(width: 30, height: 34)
        .contentShape(Rectangle())
    }

    // MARK: Bindings & helpers

    /// A binding to one Double on the settings struct. Writing it mutates the store's
    /// `stewardship`, whose didSet persists — so every tap saves.
    private func bump(_ keyPath: WritableKeyPath<StewardshipSettings, Double>) -> Binding<Double> {
        Binding(
            get: { store.stewardship[keyPath: keyPath] },
            set: { store.stewardship[keyPath: keyPath] = $0 }
        )
    }

    private var innovationBinding: Binding<String> {
        Binding(
            get: { Formatters.plain(store.stewardship.innovationFlat) },
            set: { store.stewardship.innovationFlat = max(0, Double($0) ?? 0) }
        )
    }

    private func pctLabel(_ v: Double) -> String {
        "\(Int(v.rounded()))%"
    }

    /// Calm expand toggle, gated behind the app's motion prefs + Reduce Motion.
    private func toggle(_ flag: Binding<Bool>) {
        if theme.motionEnabled && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.22)) { flag.wrappedValue.toggle() }
        } else {
            flag.wrappedValue.toggle()
        }
    }

    private var subTransition: AnyTransition {
        (theme.motionEnabled && !reduceMotion)
            ? .opacity.combined(with: .move(edge: .top))
            : .identity
    }
}
