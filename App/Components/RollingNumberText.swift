import SwiftUI

struct RollingNumberText: View {
    var text: String
    var font: Font
    var color: Color

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: text)
    }
}
