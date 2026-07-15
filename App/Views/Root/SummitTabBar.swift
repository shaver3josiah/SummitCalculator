import SwiftUI

struct SummitTabBar: View {
    @Environment(ThemeStore.self) private var themeStore
    @Binding var selection: SummitTab
    var onSelect: (SummitTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SummitTab.allCases) { tab in
                SummitTabButton(
                    tab: tab,
                    isActive: tab == selection,
                    showLabel: themeStore.showTabLabels
                ) {
                    if selection != tab { onSelect(tab) }
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .padding(.horizontal, 6)
        .background(themeStore.color("surface"))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(themeStore.color("line"))
                .frame(height: 1)
        }
    }
}

private struct SummitTabButton: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let tab: SummitTab
    let isActive: Bool
    let showLabel: Bool
    let onTap: () -> Void

    // On activation a ridge→amber hairline traces once; the active tab then keeps a
    // slow, low-contrast breathing shimmer. Only the active tab's outline is visible.
    @State private var drawEnd: CGFloat = 0
    @State private var breathe = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 18, weight: isActive ? .semibold : .regular))
                if showLabel {
                    Text(tab.label)
                        .font(summitBody(9.5, weight: isActive ? .semibold : .regular))
                }
            }
            .frame(height: 38)
            .foregroundStyle(isActive ? theme.color("primaryStrong") : theme.color("muted"))
            .frame(maxWidth: .infinity)
            .overlay { outline }
        }
        .buttonStyle(.plain)
        .onChange(of: isActive) { _, nowActive in
            if nowActive {
                if outlineVisible { redraw() } else { drawEnd = 1 }
                startBreathing()
            } else {
                var tx = Transaction()
                tx.disablesAnimations = true
                withTransaction(tx) { breathe = false }
            }
        }
        .onAppear {
            if isActive {
                drawEnd = 1
                startBreathing()
            }
        }
    }

    // Encircle only makes sense as the active-tab cue when labels are hidden.
    private var outlineVisible: Bool { isActive && !showLabel && theme.shimmerOn }

    private var outline: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .trim(from: 0, to: reduceMotion ? (outlineVisible ? 1 : 0) : drawEnd)
            .stroke(
                LinearGradient(
                    colors: [theme.color("primary"), theme.color("flowerCenter")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 1, lineCap: .round)
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .opacity(outlineVisible ? (reduceMotion ? 0.4 : (breathe ? 0.55 : 0.28)) : 0)
            .allowsHitTesting(false)
    }

    private func redraw() {
        guard !reduceMotion else { return }
        drawEnd = 0
        withAnimation(SummitMotion.draw) { drawEnd = 1 }
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: SummitMotion.shimmerHalf).repeatForever(autoreverses: true)) {
            breathe = true
        }
    }
}
