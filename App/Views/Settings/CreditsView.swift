import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStore.self) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SummitLogo(size: 56)
                        .frame(maxWidth: .infinity, alignment: .center)

                    creditBlock(
                        title: "OpenMoji",
                        license: "Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0)",
                        lines: [
                            "Emoji and icon graphics by OpenMoji (openmoji.org), CC BY-SA 4.0.",
                            "If you modify an icon, share the modified icon under the same license."
                        ]
                    )

                    creditBlock(
                        title: "game-icons.net",
                        license: "Creative Commons Attribution 3.0 (CC BY 3.0)",
                        lines: [
                            "Cooking and nature line icons by Lorc and Delapouite (game-icons.net), CC BY 3.0.",
                            "Recoloring is permitted; keep the credit."
                        ]
                    )

                    creditBlock(
                        title: "Kenney UI Pack",
                        license: "Creative Commons Zero (CC0 1.0). No attribution required.",
                        lines: [
                            "Source: kenney.nl/assets/ui-pack"
                        ]
                    )

                    creditBlock(
                        title: "Google Fonts",
                        license: "SIL Open Font License 1.1",
                        lines: [
                            "Bitter, Archivo, and Rye, SIL OFL."
                        ]
                    )

                    creditBlock(
                        title: "Sounds and art",
                        license: nil,
                        lines: [
                            "Custom sounds and art by Josiah."
                        ]
                    )
                }
                .padding(20)
            }
            .background(theme.color("bg"))
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func creditBlock(title: String, license: String?, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(summitNumber(17, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
            if let license {
                Text(license)
                    .font(summitBody(12, weight: .medium))
                    .foregroundStyle(theme.color("primaryStrong"))
            }
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(summitBody(13))
                    .foregroundStyle(theme.color("text"))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surface"))
        )
    }
}
