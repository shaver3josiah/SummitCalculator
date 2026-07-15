import SwiftUI

@Observable
final class ToastCenter {
    static let shared = ToastCenter()

    var isShowing = false
    var title = ""
    var message = ""
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(title: String, message: String) {
        self.title = title
        self.message = message
        withAnimation(SummitMotion.springSoft) {
            isShowing = true
        }
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation { isShowing = false }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation { isShowing = false }
    }
}

struct ToastHost: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var center = ToastCenter.shared

    var body: some View {
        VStack {
            if center.isShowing {
                toastCard
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .onTapGesture { center.dismiss() }
            }
            Spacer()
        }
        .padding(.top, 8)
        .allowsHitTesting(center.isShowing)
        .animation(reduceMotion ? .default : SummitMotion.springSoft, value: center.isShowing)
    }

    private var toastCard: some View {
        HStack(spacing: 12) {
            SummitLogo(size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(center.title)
                    .font(summitBody(14, weight: .semibold))
                    .foregroundStyle(theme.color("deep"))
                Text(center.message)
                    .font(summitBody(13))
                    .foregroundStyle(theme.color("muted"))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surface"))
                .shadow(color: theme.color("shadow"), radius: 10, y: 4)
        )
        .padding(.horizontal, 16)
    }
}
