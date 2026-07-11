import SwiftUI

@Observable
final class SplashController {
    static let shared = SplashController()

    var isShowing = false
    var name = "Summit"
    var subtitle = "Steady climbs, honest math"

    private init() {}

    static func trigger(name: String = "Summit", subtitle: String = "Steady climbs, honest math") {
        shared.name = name
        shared.subtitle = subtitle
        withAnimation(.easeOut(duration: 0.6)) {
            shared.isShowing = true
        }
    }

    static func dismiss() {
        withAnimation(.easeIn(duration: 0.4)) {
            shared.isShowing = false
        }
    }
}

struct SplashOverlay: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var controller = SplashController.shared

    var body: some View {
        if controller.isShowing {
            ZStack {
                backdrop
                if !reduceMotion && theme.leavesOn {
                    LeafRainView()
                        .allowsHitTesting(false)
                }
                content
            }
            .ignoresSafeArea()
            .onTapGesture { SplashController.dismiss() }
            .transition(.opacity)
        }
    }

    private var backdrop: some View {
        RadialGradient(
            colors: [theme.color("surfaceSoft"), theme.color("bg")],
            center: .top,
            startRadius: 40,
            endRadius: 520
        )
        .ignoresSafeArea()
    }

    private var content: some View {
        VStack(spacing: 18) {
            SummitLogo(size: 120)
            Text(controller.name)
                .font(summitScript(56))
                .foregroundStyle(theme.color("deep"))
            Text(controller.subtitle)
                .font(summitBody(16))
                .foregroundStyle(theme.color("muted"))
            Spacer().frame(height: 40)
            Text("tap anywhere to close")
                .font(summitBody(12))
                .foregroundStyle(theme.color("muted"))
        }
    }
}
