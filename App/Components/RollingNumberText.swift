import SwiftUI

struct RollingNumberText: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var text: String
    var font: Font
    var color: Color

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .contentTransition(reduceMotion ? .identity : .numericText())
            .animation(reduceMotion ? nil : SummitMotion.springSoft, value: text)
    }
}
