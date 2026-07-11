import SwiftUI

struct KTabBar: View {
    @Environment(ThemeStore.self) private var themeStore
    var items: [String]
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    tabButton(item)
                }
            }
            .padding(4)
        }
        .background(themeStore.color("surfaceSoft"))
        .clipShape(RoundedRectangle(cornerRadius: 999))
    }

    private func tabButton(_ item: String) -> some View {
        let isActive = item == selection
        return Button {
            selection = item
        } label: {
            Text(item)
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(isActive ? .white : themeStore.color("muted"))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(isActive ? themeStore.color("primaryStrong") : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isActive)
    }
}
