import SwiftUI
import SummitCore

struct ShopListRow: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var qty: Double
    var unitPrice: Double
    var checked: Bool = false

    var lineTotal: Double { qty * unitPrice }
}

struct ShopList: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var rows: [ShopListRow]
    var createdAt: Date = Date()

    var total: Double { rows.reduce(0) { $0 + $1.lineTotal } }
}

@Observable
final class ListsStore {
    var lists: [ShopList] {
        didSet { JSONStore.shared.set(.shopLists, lists) }
    }
    var activeListId: UUID?

    init() {
        let loaded = JSONStore.shared.get(.shopLists, as: [ShopList].self) ?? []
        lists = loaded
        activeListId = loaded.first?.id
    }

    var activeList: ShopList? {
        get {
            guard let id = activeListId else { return lists.first }
            return lists.first { $0.id == id }
        }
    }

    func createList(title: String) -> UUID {
        let newList = ShopList(title: title.isEmpty ? "New list" : title, rows: [])
        lists.insert(newList, at: 0)
        activeListId = newList.id
        return newList.id
    }

    func deleteList(_ id: UUID) {
        lists.removeAll { $0.id == id }
        if activeListId == id {
            activeListId = lists.first?.id
        }
    }

    func addRow(to listId: UUID, name: String, qty: Double, unitPrice: Double) {
        guard let idx = lists.firstIndex(where: { $0.id == listId }) else { return }
        lists[idx].rows.append(ShopListRow(name: name, qty: qty, unitPrice: unitPrice))
    }

    func updateRow(listId: UUID, row: ShopListRow) {
        guard let listIdx = lists.firstIndex(where: { $0.id == listId }) else { return }
        guard let rowIdx = lists[listIdx].rows.firstIndex(where: { $0.id == row.id }) else { return }
        lists[listIdx].rows[rowIdx] = row
    }

    func deleteRow(listId: UUID, rowId: UUID) {
        guard let listIdx = lists.firstIndex(where: { $0.id == listId }) else { return }
        lists[listIdx].rows.removeAll { $0.id == rowId }
    }

    func toggleChecked(listId: UUID, rowId: UUID) {
        guard let listIdx = lists.firstIndex(where: { $0.id == listId }) else { return }
        guard let rowIdx = lists[listIdx].rows.firstIndex(where: { $0.id == rowId }) else { return }
        lists[listIdx].rows[rowIdx].checked.toggle()
    }

    func addIngredient(name: String) {
        guard let id = activeListId ?? lists.first?.id else {
            let newId = createList(title: "Groceries")
            addRow(to: newId, name: name, qty: 1, unitPrice: 0)
            return
        }
        addRow(to: id, name: name, qty: 1, unitPrice: 0)
    }

    func addIngredient(name: String, qty: Double) {
        guard let id = activeListId ?? lists.first?.id else {
            let newId = createList(title: "Groceries")
            addRow(to: newId, name: name, qty: qty, unitPrice: 0)
            return
        }
        addRow(to: id, name: name, qty: qty, unitPrice: 0)
    }

    func logTotalToHistory(listId: UUID, history: HistoryStore) {
        guard let list = lists.first(where: { $0.id == listId }) else { return }
        history.add(
            type: "list",
            title: list.title,
            value: Formatters.money(list.total),
            extra: ["listId": list.id.uuidString]
        )
    }

    // MARK: - Notes → list

    /// Bullet/number lines -> items. The real logic (and its tests) live in
    /// SummitCore.ListParse; this stays as the call site the view already uses.
    static func listItems(from text: String) -> [String] {
        ListParse.listItems(from: text)
    }

    func reopen(from entry: HistoryEntry) {
        guard let idString = entry.extra["listId"], let id = UUID(uuidString: idString) else { return }
        if lists.contains(where: { $0.id == id }) {
            activeListId = id
        }
    }
}
