import SwiftUI

/// The celebration that presents when the second income is turned OFF —
/// running the whole climb on one income. A full-screen cover (a ZStack overlay
/// would be clipped by the Budget ScrollView), so it stands on its own bg scrim.
/// Auto-dismisses after ~3.2s; a tap anywhere closes it early.
struct BasecampSplash: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(SoundStore.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    @State private var appeared = false
    @State private var leafEpoch = 0            // one-shot: bumped in onAppear to fire the burst
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            theme.color("bg").ignoresSafeArea()

            if theme.leavesOn {
                LeafBurstView(trigger: leafEpoch, originX: 0.5, originY: 0.42)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }

            VStack(spacing: 20) {
                SummitLogo(size: 72)
                messageCard
                Text("Steady on")
                    .font(summitBody(13, weight: .medium))
                    .foregroundStyle(theme.color("muted"))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)
            .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.92))
            .opacity(reduceMotion ? 1 : (appeared ? 1 : 0))
        }
        .contentShape(Rectangle())
        .onTapGesture { close() }
        .onAppear(perform: start)
        .onDisappear { dismissTask?.cancel() }
    }

    private var messageCard: some View {
        VStack(spacing: 12) {
            Text("Base camp!")
                .font(summitScript(44))
                .foregroundStyle(theme.color("deep"))
                .multilineTextAlignment(.center)
            Text("One income holds the whole camp")
                .font(summitBody(17, weight: .medium))
                .foregroundStyle(theme.color("text"))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                .fill(theme.color("surface"))
                .shadow(color: theme.color("shadow"), radius: 24, y: 10)
        )
        .overlay {
            if theme.shimmerOn {
                EncircleOutline(trigger: 0, cornerRadius: theme.radius)
            }
        }
    }

    private func start() {
        if reduceMotion {
            appeared = true
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        leafEpoch = 1                 // 0 → 1 drives LeafBurstView.onChange once
        sound.play("easteregg")        // play() already guards on sound.enabled
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            guard !Task.isCancelled else { return }
            close()
        }
    }

    private func close() {
        dismissTask?.cancel()
        dismiss()
    }
}
