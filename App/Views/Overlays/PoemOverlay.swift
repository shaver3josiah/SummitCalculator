import SwiftUI
import SummitCore

struct PoemOverlay: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(CalcStore.self) private var calc
    @Environment(SoundStore.self) private var sound
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isShowing = false
    @State private var showMore = false
    @State private var dismissTask: Task<Void, Never>?
    @State private var lastEpoch = -1

    var body: some View {
        Group {
            if isShowing, let egg = calc.lastEgg, egg.kind == "poem" {
                poemCard(egg)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }
        }
        .onChange(of: calc.eggEpoch) { _, newEpoch in
            handleEpochChange(newEpoch)
        }
        .onAppear {
            lastEpoch = calc.eggEpoch
        }
    }

    private func handleEpochChange(_ newEpoch: Int) {
        guard newEpoch != lastEpoch else { return }
        lastEpoch = newEpoch
        guard let egg = calc.lastEgg else { return }
        if egg.kind == "poem" {
            present(egg)
        } else if egg.kind == "toast" {
            ToastCenter.shared.show(title: egg.title, message: egg.lines.first ?? "")
        }
    }

    private func present(_ egg: Egg) {
        showMore = false
        withAnimation(SummitMotion.springSoft) {
            isShowing = true
        }
        sound.play("easteregg")
        scheduleDismiss()
    }

    private func scheduleDismiss() {
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 22_000_000_000)
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    private func dismiss() {
        dismissTask?.cancel()
        withAnimation { isShowing = false }
    }

    private func poemCard(_ egg: Egg) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            if !reduceMotion {
                sparkleField
            }

            VStack(spacing: 14) {
                Text(egg.dateLabel)
                    .font(summitBody(12))
                    .foregroundStyle(theme.color("muted"))

                Text(egg.title)
                    .font(summitScript(34))
                    .foregroundStyle(theme.color("deep"))
                    .multilineTextAlignment(.center)

                poemLines(egg)

                if let more = egg.more, !more.isEmpty {
                    if showMore {
                        moreBlock(more)
                    } else {
                        Button("more") {
                            withAnimation { showMore = true }
                            sound.play("easteregg")
                        }
                        .font(summitBody(13, weight: .semibold))
                        .foregroundStyle(theme.color("primaryStrong"))
                    }
                }

                Text("tap anywhere to close")
                    .font(summitBody(11))
                    .foregroundStyle(theme.color("muted"))
                    .padding(.top, 6)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: theme.radius)
                    .fill(theme.color("surface"))
                    .shadow(color: theme.color("shadow"), radius: 24, y: 10)
            )
            .padding(.horizontal, 30)
            .onTapGesture { dismiss() }
        }
    }

    private func poemLines(_ egg: Egg) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(egg.lines.enumerated()), id: \.offset) { idx, line in
                Text(line)
                    .font(summitBody(15))
                    .foregroundStyle(theme.color("text"))
                    .multilineTextAlignment(.center)
                    .opacity(isShowing ? 1 : 0)
                    .offset(y: isShowing ? 0 : 10)
                    .animation(
                        reduceMotion ? nil : .easeOut(duration: 0.5).delay(0.35 + Double(idx) * 0.35),
                        value: isShowing
                    )
            }
        }
    }

    private func moreBlock(_ more: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(more.enumerated()), id: \.offset) { _, entry in
                moreLine(entry)
            }
        }
        .transition(.opacity)
    }

    private func moreLine(_ raw: String) -> some View {
        let (tag, text) = splitTag(raw)
        return Group {
            switch tag {
            case "head":
                Text(text)
                    .font(summitBody(14, weight: .bold))
                    .foregroundStyle(theme.color("deep"))
            case "v":
                Text(text)
                    .font(summitBody(12))
                    .foregroundStyle(theme.color("muted"))
            case "note":
                Text(text)
                    .font(summitBody(13))
                    .italic()
                    .foregroundStyle(theme.color("text"))
            case "ask":
                Text(text)
                    .font(summitBody(13, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
            default:
                Text(text)
                    .font(summitBody(13))
                    .foregroundStyle(theme.color("text"))
            }
        }
    }

    private func splitTag(_ raw: String) -> (String, String) {
        guard let range = raw.range(of: ": ") else { return ("line", raw) }
        let tag = String(raw[raw.startIndex..<range.lowerBound])
        let text = String(raw[range.upperBound...])
        let validTags = ["note", "head", "v", "ask", "line"]
        guard validTags.contains(tag) else { return ("line", raw) }
        return (tag, text)
    }

    private var sparkleField: some View {
        Group {
            if theme.leavesOn {
                SparkleFieldView(colorTokens: ["flowerCenter", "primary"])
                    .allowsHitTesting(false)
            }
        }
    }
}
