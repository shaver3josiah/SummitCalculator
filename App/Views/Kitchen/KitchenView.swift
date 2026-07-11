import SwiftUI

struct KitchenView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var store
    @Environment(SoundStore.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Namespace private var pillSpace

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                kitchenTabs

                activePanel
                    .id(store.activeTab)
                    .transition(panelTransition)
            }
            .padding(16)
        }
        .background {
            ZStack {
                theme.color("bg")
                KitchenBackdrop()
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var activePanel: some View {
        switch store.activeTab {
        case .convert:
            ConvertPanel()
        case .recipe:
            RecipePanel()
        case .visualize:
            VisualizePanel()
        }
    }

    private var panelTransition: AnyTransition {
        guard theme.motionEnabled, !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    private var kitchenTabs: some View {
        HStack(spacing: 8) {
            tabButton("Convert", tab: .convert)
            tabButton("Recipe", tab: .recipe)
            tabButton("Visualize", tab: .visualize)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surfaceSoft"))
        )
    }

    private func tabButton(_ title: String, tab: KitchenTab) -> some View {
        let isActive = store.activeTab == tab
        return Button {
            guard store.activeTab != tab else { return }
            sound.play("modeswitch")
            if theme.motionEnabled && !reduceMotion {
                withAnimation(SummitMotion.glide) { store.activeTab = tab }
            } else {
                store.activeTab = tab
            }
        } label: {
            Text(title)
                .font(summitBody(14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background {
                    if isActive {
                        // Sliding pill; the hairline traces around it on each switch.
                        RoundedRectangle(cornerRadius: theme.radius - 4)
                            .fill(theme.color("surface"))
                            .overlay {
                                if theme.shimmerOn {
                                    EncircleOutline(
                                        trigger: store.activeTab,
                                        cornerRadius: theme.radius - 4,
                                        lineWidth: 1,
                                        settleOpacity: 0.7
                                    )
                                }
                            }
                            .matchedGeometryEffect(id: "kitchenPill", in: pillSpace)
                    }
                }
                .foregroundStyle(isActive ? theme.color("deep") : theme.color("muted"))
        }
        .buttonStyle(.plain)
    }
}

/// Faint line-art kitchen icons scattered behind the panels — decor, not content.
/// Deterministic layout (seeded) so it never shifts between visits.
private struct KitchenBackdrop: View {
    @Environment(ThemeStore.self) private var theme

    private static let symbols = [
        "fork.knife", "cup.and.saucer", "birthday.cake", "carrot",
        "fork.knife", "cup.and.saucer", "stove", "birthday.cake"
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(Self.symbols.enumerated()), id: \.offset) { index, name in
                let spot = Self.placement(index: index)
                Image(systemName: name)
                    .font(.system(size: spot.size, weight: .light))
                    .foregroundStyle(theme.color("deep").opacity(0.05))
                    .rotationEffect(.degrees(spot.tilt))
                    .position(
                        x: spot.x * geo.size.width,
                        y: spot.y * geo.size.height
                    )
            }
        }
        .allowsHitTesting(false)
    }

    private static func placement(index: Int) -> (x: Double, y: Double, size: Double, tilt: Double) {
        var rng = SeededGenerator(seed: index &* 911 &+ 47)
        // Two loose columns down the margins so icons stay clear of the center content.
        let leftColumn = index % 2 == 0
        return (
            x: leftColumn ? Double.random(in: 0.06...0.18, using: &rng) : Double.random(in: 0.82...0.94, using: &rng),
            y: 0.08 + Double(index) / Double(symbols.count) * 0.86 + Double.random(in: -0.03...0.03, using: &rng),
            size: Double.random(in: 22...34, using: &rng),
            tilt: Double.random(in: -22...22, using: &rng)
        )
    }
}
