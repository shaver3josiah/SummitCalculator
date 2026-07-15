import SwiftUI
import Charts
import SummitCore

/// Illustrative "who beats the market" bar chart. All figures are approximate,
/// compiled from public reporting — labelled as curiosity, not advice.
/// ponytail: static data + no animation, so it's reduce-motion-safe by construction.
struct ReturnsChart: View {
    @Environment(ThemeStore.self) private var themeStore

    // Edit here to tweak the story. Stored in any order; the view sorts descending
    // so the eye-popping bars read as the headline.
    private let entries: [ReturnEntry] = [
        ReturnEntry(name: "S&P 500 index", subtitle: "the long-run market benchmark", pct: 10, tone: .benchmark),
        ReturnEntry(name: "Top growth fund", subtitle: "a strong large-cap / tech fund", pct: 15, tone: .summit),
        ReturnEntry(name: "Warren Buffett", subtitle: "Berkshire Hathaway, 1965–2024 annualized", pct: 20, tone: .deep),
        ReturnEntry(name: "Nancy Pelosi", subtitle: "per public trade trackers, recent years", pct: 65, tone: .gold)
    ]

    private var sorted: [ReturnEntry] { entries.sorted { $0.pct > $1.pct } }
    // Headroom past the tallest bar so its trailing "%" label never clips.
    private var maxDomain: Double { (entries.map(\.pct).max() ?? 1) * 1.18 }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                header
                chart
                caption
                ProjectionDisclaimer(text: "Illustrative figures compiled from public reports for curiosity, not investment advice. Actual returns vary widely by source and period — the Pelosi and Buffett numbers especially — and past performance doesn't predict the future.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Who beats the market?")
                .font(summitNumber(19, weight: .semibold))
                .foregroundStyle(themeStore.color("deep"))
            Text("Average annual return, illustrative — through ~2026")
                .font(summitBody(12))
                .foregroundStyle(themeStore.color("muted"))
        }
    }

    private var chart: some View {
        // Horizontal bars: one full row per name, so even the ~10% bar is a clear
        // row (not a sliver) and every bar carries its exact % at its tip.
        Chart(sorted) { entry in
            BarMark(
                x: .value("Return", entry.pct),
                y: .value("Name", entry.name),
                height: .ratio(0.62)
            )
            .cornerRadius(6)
            .foregroundStyle(color(for: entry.tone))
            .annotation(position: .trailing, alignment: .leading, spacing: 6) {
                Text("\(Formatters.plain(entry.pct))%")
                    .font(summitNumber(15, weight: .semibold))
                    .foregroundStyle(themeStore.color("deep"))
            }
        }
        .chartXScale(domain: 0...maxDomain)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let name = value.as(String.self) {
                        Text(name)
                            .font(summitBody(12, weight: .semibold))
                            .foregroundStyle(themeStore.color("text"))
                    }
                }
            }
        }
        .frame(height: CGFloat(sorted.count) * 46)
    }

    // Compact legend/caption: a colour dot ties each subtitle back to its bar,
    // plus one honest-axis note so the dwarfed bars are explained, not hidden.
    private var caption: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(sorted) { entry in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Circle()
                        .fill(color(for: entry.tone))
                        .frame(width: 8, height: 8)
                    Text("\(entry.name) — \(entry.subtitle)")
                        .font(summitBody(11))
                        .foregroundStyle(themeStore.color("muted"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Text("One honest scale: Pelosi's ~65% dwarfs the rest, so each bar is labelled with its exact figure.")
                .font(summitBody(11, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }

    private func color(for tone: ReturnTone) -> Color {
        switch tone {
        case .benchmark: return themeStore.color("muted")        // neutral market benchmark
        case .summit: return themeStore.color("primary")          // primary accent
        case .deep: return themeStore.color("primaryStrong")     // strong primary accent
        case .gold: return themeStore.color("flowerCenter")      // gold — the headline
        }
    }
}

enum ReturnTone {
    case benchmark, summit, deep, gold
}

struct ReturnEntry: Identifiable {
    let name: String
    let subtitle: String
    let pct: Double
    let tone: ReturnTone
    var id: String { name }
}
