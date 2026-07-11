import SwiftUI

struct ProjectionFormField: View {
    @Environment(ThemeStore.self) private var themeStore

    var label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(summitBody(12, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
            TextField("", text: $text)
                .keyboardType(.decimalPad)
                .font(summitBody(15))
                .foregroundStyle(themeStore.color("text"))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(themeStore.color("surfaceSoft"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct ProjectionFieldRow: View {
    var leftLabel: String
    @Binding var leftText: String
    var rightLabel: String
    @Binding var rightText: String

    var body: some View {
        HStack(spacing: 12) {
            ProjectionFormField(label: leftLabel, text: $leftText)
            ProjectionFormField(label: rightLabel, text: $rightText)
        }
    }
}

struct ProjectionResultStat: View {
    @Environment(ThemeStore.self) private var themeStore
    var label: String
    var value: String
    var isGrowth: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(summitBody(11, weight: .medium))
                .foregroundStyle(themeStore.color("muted"))
            RollingNumberText(
                text: value,
                font: summitNumber(19, weight: .medium),
                color: isGrowth ? themeStore.color("good") : themeStore.color("text")
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProjectionCalcButton: View {
    @Environment(ThemeStore.self) private var themeStore
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(summitBody(15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(themeStore.color("primaryStrong"))
                .clipShape(RoundedRectangle(cornerRadius: themeStore.radius * 0.6))
        }
        .buttonStyle(.plain)
    }
}

struct ProjectionDisclaimer: View {
    @Environment(ThemeStore.self) private var themeStore
    var text: String

    var body: some View {
        Text(text)
            .font(summitBody(11))
            .foregroundStyle(themeStore.color("muted"))
            .fixedSize(horizontal: false, vertical: true)
    }
}
