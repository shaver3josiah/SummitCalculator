import SwiftUI
import SummitCore

@Observable
final class HistoryStore {
    var isPresented: Bool = false
    var entries: [HistoryEntry] {
        didSet { JSONStore.shared.set(.history, entries) }
    }
    var favoriteIds: Set<String> {
        didSet { JSONStore.shared.set(.favorites, Array(favoriteIds)) }
    }
    var searchText: String = ""
    var selectedForRecycle: HistoryEntry?

    static let cap = 200

    init() {
        entries = JSONStore.shared.get(.history, as: [HistoryEntry].self) ?? []
        let favArray = JSONStore.shared.get(.favorites, as: [String].self) ?? []
        favoriteIds = Set(favArray)
    }

    func add(type: String, title: String, value: String, extra: [String: String]) {
        let entry = HistoryEntry(
            id: UUID().uuidString,
            ts: Date(),
            type: type,
            title: title,
            value: value,
            extra: extra
        )
        entries.insert(entry, at: 0)
        evictIfNeeded()
    }

    private func evictIfNeeded() {
        guard entries.count > Self.cap else { return }
        var kept: [HistoryEntry] = []
        var overflow: [HistoryEntry] = []
        for entry in entries {
            if favoriteIds.contains(entry.id) {
                kept.append(entry)
            } else {
                overflow.append(entry)
            }
        }
        let room = max(0, Self.cap - kept.count)
        kept.append(contentsOf: overflow.prefix(room))
        entries = kept.sorted { $0.ts > $1.ts }
    }

    func isFavorite(_ entry: HistoryEntry) -> Bool {
        favoriteIds.contains(entry.id)
    }

    func toggleFavorite(_ entry: HistoryEntry) {
        if favoriteIds.contains(entry.id) {
            favoriteIds.remove(entry.id)
        } else {
            favoriteIds.insert(entry.id)
        }
    }

    func clearNonFavorites() {
        entries.removeAll { !favoriteIds.contains($0.id) }
    }

    var filteredEntries: [HistoryEntry] {
        guard !searchText.isEmpty else { return entries }
        let q = searchText.lowercased()
        return entries.filter {
            $0.title.lowercased().contains(q) || $0.value.lowercased().contains(q)
        }
    }

    func groupedEntries() -> [(label: String, entries: [HistoryEntry])] {
        let visible = filteredEntries
        let pinned = visible.filter { favoriteIds.contains($0.id) }
        let rest = visible.filter { !favoriteIds.contains($0.id) }

        var groups: [(String, [HistoryEntry])] = []
        if !pinned.isEmpty {
            groups.append(("Pinned", pinned))
        }

        let calendar = Calendar.current
        var today: [HistoryEntry] = []
        var yesterday: [HistoryEntry] = []
        var older: [String: [HistoryEntry]] = [:]
        var olderOrder: [String] = []

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        for entry in rest {
            if calendar.isDateInToday(entry.ts) {
                today.append(entry)
            } else if calendar.isDateInYesterday(entry.ts) {
                yesterday.append(entry)
            } else {
                let label = formatter.string(from: entry.ts)
                if older[label] == nil {
                    older[label] = []
                    olderOrder.append(label)
                }
                older[label]?.append(entry)
            }
        }

        if !today.isEmpty { groups.append(("Today", today)) }
        if !yesterday.isEmpty { groups.append(("Yesterday", yesterday)) }
        for label in olderOrder {
            if let items = older[label] {
                groups.append((label, items))
            }
        }
        return groups
    }

    func shareText() -> String {
        var lines: [String] = ["Summit Calculator History"]
        for entry in filteredEntries {
            lines.append("\(entry.title): \(entry.value)")
        }
        return lines.joined(separator: "\n")
    }
}
