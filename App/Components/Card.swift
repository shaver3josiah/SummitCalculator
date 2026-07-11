import SwiftUI

struct Card<Content: View>: View {
    @Environment(ThemeStore.self) private var themeStore
    var padding: CGFloat = 18
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(themeStore.color("surface"))
            .clipShape(RoundedRectangle(cornerRadius: themeStore.radius))
            .shadow(color: themeStore.color("shadow"), radius: 14, x: 0, y: 8)
    }
}
