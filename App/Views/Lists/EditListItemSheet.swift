import SwiftUI
import SummitCore

struct EditListItemSheet: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.dismiss) private var dismiss

    let row: ShopListRow
    var onSave: (ShopListRow) -> Void
    var onDelete: () -> Void

    @State private var name: String
    @State private var qty: String
    @State private var price: String

    init(row: ShopListRow, onSave: @escaping (ShopListRow) -> Void, onDelete: @escaping () -> Void) {
        self.row = row
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: row.name)
        _qty = State(initialValue: Formatters.plain(row.qty))
        _price = State(initialValue: row.unitPrice == 0 ? "" : Formatters.plain(row.unitPrice))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    field(label: "Item", text: $name, keyboard: .default)
                    HStack(spacing: 12) {
                        field(label: "Qty", text: $qty, keyboard: .decimalPad)
                        field(label: "Price each", text: $price, keyboard: .decimalPad)
                    }
                    Button {
                        onDelete()
                        dismiss()
                    } label: {
                        Text("Delete item")
                            .font(summitBody(14, weight: .semibold))
                            .foregroundStyle(theme.color("primaryStrong"))
                    }
                    .padding(.top, 4)
                }
                .padding(18)
            }
            .background(theme.color("bg"))
            .navigationTitle("Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(summitBody(15, weight: .semibold))
                }
            }
            .keyboardDoneBar()
        }
    }

    private func field(label: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(summitBody(12, weight: .medium))
                .foregroundStyle(theme.color("muted"))
            TextField("", text: text)
                .keyboardType(keyboard)
                .font(summitBody(16))
                .foregroundStyle(theme.color("text"))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(theme.color("surfaceSoft"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func save() {
        var updated = row
        updated.name = name.trimmingCharacters(in: .whitespaces).isEmpty ? row.name : name
        updated.qty = Double(qty) ?? row.qty
        updated.unitPrice = Double(price) ?? 0
        onSave(updated)
        dismiss()
    }
}
