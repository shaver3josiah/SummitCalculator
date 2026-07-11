import SwiftUI
import UIKit
import SummitCore

struct ThemeEditorView: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    presetSection
                    displaySection
                    motionSection
                    editableTokensSection
                }
                .padding(20)
            }
            .background(themeStore.color("bg"))
            .navigationTitle("Theme and colors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(summitBody(15, weight: .semibold))
                }
            }
        }
    }

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Display")
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(themeStore.color("muted"))
                .textCase(.uppercase)
            Toggle(isOn: Binding(get: { themeStore.showTabLabels }, set: { themeStore.showTabLabels = $0 })) {
                Text("Show tab labels")
                    .font(summitBody(14))
                    .foregroundStyle(themeStore.color("text"))
            }
            .tint(themeStore.color("primaryStrong"))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(themeStore.color("surface"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var motionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Motion")
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(themeStore.color("muted"))
                .textCase(.uppercase)
            VStack(spacing: 0) {
                motionToggle("Animations", isOn: Binding(
                    get: { themeStore.motionEnabled }, set: { themeStore.motionEnabled = $0 }))
                Divider().overlay(themeStore.color("line"))
                motionToggle("Leaf effects", isOn: Binding(
                    get: { themeStore.leavesEnabled }, set: { themeStore.leavesEnabled = $0 }))
                    .disabled(!themeStore.motionEnabled)
                Divider().overlay(themeStore.color("line"))
                motionToggle("Shimmer & outline", isOn: Binding(
                    get: { themeStore.shimmerEnabled }, set: { themeStore.shimmerEnabled = $0 }))
                    .disabled(!themeStore.motionEnabled)
            }
            .padding(.horizontal, 14)
            .background(themeStore.color("surface"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func motionToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(summitBody(14))
                .foregroundStyle(themeStore.color("text"))
        }
        .tint(themeStore.color("primaryStrong"))
        .padding(.vertical, 10)
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Presets")
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(themeStore.color("muted"))
                .textCase(.uppercase)
            HStack(spacing: 12) {
                ForEach(themeStore.presetNames, id: \.self) { name in
                    presetSwatch(name)
                }
            }
        }
    }

    private func presetSwatch(_ name: String) -> some View {
        let isActive = themeStore.spec.name == name
        return Button {
            themeStore.setPreset(name)
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(ThemeEditorView.previewColor(for: name))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().stroke(isActive ? themeStore.color("primaryStrong") : .clear, lineWidth: 3)
                    )
                Text(name.capitalized)
                    .font(summitBody(11, weight: .medium))
                    .foregroundStyle(themeStore.color("text"))
            }
        }
        .buttonStyle(.plain)
    }

    private var editableTokensSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Custom colors")
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(themeStore.color("muted"))
                .textCase(.uppercase)
            VStack(spacing: 0) {
                ForEach(ThemeStore.editableTokenOrder, id: \.self) { token in
                    tokenRow(token)
                    if token != ThemeStore.editableTokenOrder.last {
                        Divider().overlay(themeStore.color("line"))
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(themeStore.color("surface"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func tokenRow(_ token: String) -> some View {
        ColorPicker(selection: colorBinding(for: token), supportsOpacity: false) {
            Text(ThemeStore.editableTokenLabel(token))
                .font(summitBody(14))
                .foregroundStyle(themeStore.color("text"))
        }
        .padding(.vertical, 10)
    }

    private func colorBinding(for token: String) -> Binding<Color> {
        Binding(
            get: { themeStore.color(token) },
            set: { newColor in
                if let hex = newColor.toHex() {
                    themeStore.setCustomToken(token, hex: hex)
                    if themeStore.spec.name != "custom" {
                        themeStore.setPreset("custom")
                        themeStore.setCustomToken(token, hex: hex)
                    }
                }
            }
        )
    }

    private static func previewColor(for name: String) -> Color {
        switch name {
        case "pine": return Color(hex: "#7FA985") ?? .green
        case "cedar": return Color(hex: "#C58757") ?? .brown
        case "granite": return Color(hex: "#8AA5B5") ?? .gray
        case "river": return Color(hex: "#6FBCAC") ?? .teal
        default: return Color(hex: "#6FA3C7") ?? .blue // lake
        }
    }
}

extension Color {
    func toHex() -> String? {
        let uiColor = UIColor(self)
        guard let components = uiColor.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Int(round(components[0] * 255))
        let g = Int(round(components[1] * 255))
        let b = Int(round(components[2] * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
