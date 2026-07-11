import SwiftUI
import SummitCore

struct ListsView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(ListsStore.self) private var store
    @Environment(HistoryStore.self) private var history
    @Environment(SoundStore.self) private var sound

    @State private var newItemName = ""
    @State private var newItemQty = "1"
    @State private var newItemPrice = ""
    @State private var showNewListPrompt = false
    @State private var newListTitle = ""
    @State private var editingRow: ShopListRow?
    @State private var editingListId: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                listPicker
                if let list = store.activeList {
                    listCard(list)
                } else {
                    emptyState
                }
            }
            .padding(16)
        }
        .background(theme.color("bg"))
        .scrollDismissesKeyboard(.interactively)
        .sheet(item: $editingRow) { row in
            EditListItemSheet(row: row) { updated in
                if let listId = editingListId {
                    store.updateRow(listId: listId, row: updated)
                }
            } onDelete: {
                if let listId = editingListId {
                    store.deleteRow(listId: listId, rowId: row.id)
                }
            }
        }
        .alert("Name this list", isPresented: $showNewListPrompt) {
            TextField("Groceries, a trip, the month", text: $newListTitle, prompt: Text("Groceries, a trip, the month").foregroundColor(theme.color("muted")))
            Button("Create") {
                _ = store.createList(title: newListTitle)
                newListTitle = ""
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var listPicker: some View {
        HStack {
            Menu {
                ForEach(store.lists) { list in
                    Button(list.title) { store.activeListId = list.id }
                }
            } label: {
                HStack {
                    Text(store.activeList?.title ?? "No lists yet")
                        .font(summitNumber(19, weight: .semibold))
                        .foregroundStyle(theme.color("deep"))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13))
                        .foregroundStyle(theme.color("muted"))
                }
            }
            Spacer()
            Button {
                showNewListPrompt = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(theme.color("primaryStrong"))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("Start a list")
                .font(summitNumber(20))
                .foregroundStyle(theme.color("deep"))
            Text("Groceries, a trip, or the month. Tap + to begin.")
                .font(summitBody(14))
                .foregroundStyle(theme.color("muted"))
        }
        .padding(.top, 60)
    }

    private func listCard(_ list: ShopList) -> some View {
        VStack(spacing: 12) {
            ForEach(list.rows) { row in
                rowView(listId: list.id, row: row)
            }
            if !list.rows.isEmpty {
                Text("Tap a row to edit it.")
                    .font(summitBody(11))
                    .foregroundStyle(theme.color("muted"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            addRow(listId: list.id)
            totalsBar(list)
            HStack {
                Button("Delete list") {
                    store.deleteList(list.id)
                }
                .font(summitBody(13))
                .foregroundStyle(theme.color("muted"))
                Spacer()
                Button("Log total to history") {
                    store.logTotalToHistory(listId: list.id, history: history)
                    sound.play("success")
                }
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(theme.color("primaryStrong"))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surface"))
        )
    }

    private func rowView(listId: UUID, row: ShopListRow) -> some View {
        HStack(spacing: 10) {
            Button {
                store.toggleChecked(listId: listId, rowId: row.id)
            } label: {
                Image(systemName: row.checked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(row.checked ? theme.color("good") : theme.color("muted"))
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())

            Button {
                editingListId = listId
                editingRow = row
            } label: {
                HStack(spacing: 10) {
                    Text(row.name)
                        .font(summitBody(15))
                        .foregroundStyle(row.checked ? theme.color("muted") : theme.color("text"))
                        .strikethrough(row.checked)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(Formatters.plain(row.qty))
                        .font(summitBody(13))
                        .foregroundStyle(theme.color("muted"))
                        .frame(width: 36)

                    Text(Formatters.money(row.lineTotal))
                        .font(summitNumber(14))
                        .foregroundStyle(theme.color("deep"))
                        .frame(width: 70, alignment: .trailing)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                store.deleteRow(listId: listId, rowId: row.id)
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(theme.color("muted"))
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
    }

    private func addRow(listId: UUID) -> some View {
        HStack(spacing: 8) {
            TextField("Item", text: $newItemName, prompt: Text("Item").foregroundColor(theme.color("muted")))
                .font(summitBody(14))
            TextField("Qty", text: $newItemQty, prompt: Text("Qty").foregroundColor(theme.color("muted")))
                .keyboardType(.decimalPad)
                .font(summitBody(14))
                .frame(width: 44)
            TextField("Price", text: $newItemPrice, prompt: Text("Price").foregroundColor(theme.color("muted")))
                .keyboardType(.decimalPad)
                .font(summitBody(14))
                .frame(width: 60)
            Button {
                addItem(listId: listId)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(theme.color("primaryStrong"))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.color("surfaceSoft"))
        )
    }

    private func addItem(listId: UUID) {
        guard !newItemName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let qty = Double(newItemQty) ?? 1
        let price = Double(newItemPrice) ?? 0
        store.addRow(to: listId, name: newItemName, qty: qty, unitPrice: price)
        newItemName = ""
        newItemQty = "1"
        newItemPrice = ""
        sound.play("tap1")
    }

    private func totalsBar(_ list: ShopList) -> some View {
        HStack {
            Text("TOTAL")
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(theme.color("muted"))
            Spacer()
            Text(Formatters.money(list.total))
                .font(summitNumber(22, weight: .semibold))
                .foregroundStyle(theme.color("deep"))
        }
        .padding(.top, 4)
    }
}
