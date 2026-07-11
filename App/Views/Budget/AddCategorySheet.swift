import SwiftUI
import SummitCore

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStore.self) private var theme
    @Environment(BudgetStore.self) private var store
    @Environment(ListsStore.self) private var lists

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Pick one to drop it into this month with its starter items.")
                        .font(summitBody(14))
                        .foregroundStyle(theme.color("muted"))

                    chipWrap(BudgetDefaults.presets.map { $0.n }) { index in
                        store.addCategory(preset: BudgetDefaults.presets[index])
                        dismiss()
                    }

                    if !listChipTitles.isEmpty {
                        Text("Or turn a saved list into a category")
                            .font(summitBody(12, weight: .medium))
                            .foregroundStyle(theme.color("muted"))
                        chipWrap(listChipTitles) { index in
                            let source = listSources[index]
                            store.addCategory(fromList: source.title, rows: source.rows)
                            dismiss()
                        }
                    }
                }
                .padding(20)
            }
            .background(theme.color("bg"))
            .navigationTitle("Add a category")
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

    private var listChipTitles: [String] {
        listSources.map { $0.title }
    }

    private func chipWrap(_ items: [String], onTap: @escaping (Int) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items.indices, id: \.self) { index in
                    Button {
                        onTap(index)
                    } label: {
                        Text(items[index])
                            .font(summitBody(13, weight: .semibold))
                            .foregroundStyle(theme.color("text"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(theme.color("surfaceSoft")))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

enum BudgetListSources {
    static func sources(lists: ListsStore) -> [(title: String, rows: [(name: String, qty: Double, amount: Double)])] {
        var out: [(title: String, rows: [(name: String, qty: Double, amount: Double)])] = []
        if let active = lists.activeList, active.rows.contains(where: { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }) {
            let rows = active.rows.map { (name: $0.name, qty: $0.qty, amount: $0.unitPrice) }
            out.append((title: "\(active.title) (open now)", rows: rows))
        }
        for list in lists.lists {
            if list.id == lists.activeList?.id { continue }
            guard !list.rows.isEmpty else { continue }
            let rows = list.rows.map { (name: $0.name, qty: $0.qty, amount: $0.unitPrice) }
            out.append((title: list.title, rows: rows))
        }
        return out
    }
}
