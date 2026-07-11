import SwiftUI
import SummitCore

struct ImportListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @Environment(ListsStore.self) private var lists
    var categoryIndex: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Items come in with their qty \u{D7} amount as the budgeted number.")
                        .font(summitBody(14))
                        .foregroundStyle(theme.color("muted"))

                    if listSources.isEmpty {
                        Text("No saved lists yet. Make one on the Lists tab first.")
                            .font(summitBody(13))
                            .foregroundStyle(theme.color("muted"))
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(listSources.indices, id: \.self) { index in
                                    chip(index)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(theme.color("bg"))
            .navigationTitle("Import a list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var listSources: [(title: String, rows: [(name: String, qty: Double, amount: Double)])] {
        BudgetListSources.sources(lists: lists)
    }

    private func chip(_ index: Int) -> some View {
        let source = listSources[index]
        return Button {
            store.importList(category: categoryIndex, title: source.title, rows: source.rows)
            dismiss()
        } label: {
            Text("\(source.title) \u{B7} \(source.rows.count) items")
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(theme.color("text"))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(theme.color("surfaceSoft")))
        }
        .buttonStyle(.plain)
    }
}
