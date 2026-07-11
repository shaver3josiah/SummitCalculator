import SwiftUI
import SummitCore

struct ImportBudgetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @State private var text = ""
    @State private var failed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Paste a shared budget. It ends with a #summit-budget-v1 code.")
                        .font(summitBody(14))
                        .foregroundStyle(theme.color("muted"))
                    TextEditor(text: $text)
                        .font(summitBody(13))
                        .frame(minHeight: 160)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(RoundedRectangle(cornerRadius: 12).fill(theme.color("surface")))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(theme.color("line")))
                    if failed {
                        Text("That text doesn\u{2019}t contain a shared budget.")
                            .font(summitBody(13, weight: .medium))
                            .foregroundStyle(theme.color("deep"))
                    }
                    Button {
                        if store.importShared(text) {
                            dismiss()
                        } else {
                            failed = true
                        }
                    } label: {
                        Text("Import")
                            .font(summitBody(15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(theme.color("primaryStrong")))
                    }
                    .buttonStyle(.plain)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(20)
            }
            .background(theme.color("bg"))
            .navigationTitle("Import a budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
