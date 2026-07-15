import SwiftUI

/// Landscape navigation: the portrait bottom tab bar becomes a vertical rail on the
/// RIGHT edge of the screen, freeing the full height for real content. All text is
/// upright — a normal VStack of icon+label buttons, no rotation — so it reads
/// correctly in landscape. Mirrors SummitTabBar's colors + active-tab language.
struct VerticalTabRail: View {
    @Environment(ThemeStore.self) private var theme
    @Binding var selection: SummitTab
    var onSelect: (SummitTab) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(SummitTab.allCases) { tab in
                railButton(tab)
            }
        }
        .padding(.vertical, 6)
        .frame(width: 68)
        .frame(maxHeight: .infinity)
        .background(theme.color("surface"))
        .overlay(alignment: .leading) {
            // Divider sits on the rail's LEADING edge, between content and rail.
            Rectangle().fill(theme.color("line")).frame(width: 1)
        }
    }

    private func railButton(_ tab: SummitTab) -> some View {
        let active = tab == selection
        // Each button flexes to an equal share of the rail height (7 over the full
        // landscape height ≈ 50pt each — enough for icon + a shrink-to-fit label).
        return Button {
            if selection != tab { onSelect(tab) }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 18, weight: active ? .semibold : .regular))
                if theme.showTabLabels {
                    Text(tab.label)
                        .font(summitBody(8, weight: active ? .semibold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)   // "Monthly Budget" shrinks, never wraps
                }
            }
            .foregroundStyle(active ? theme.color("primaryStrong") : theme.color("muted"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if active {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(theme.color("surfaceSoft"))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
    }
}
