import SwiftUI
import SummitCore

struct HistoryOverlay: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ThemeStore.self) private var theme
    @Environment(CalcStore.self) private var calc
    @Environment(HistoryStore.self) private var history
    @Environment(SoundStore.self) private var sound
    @Environment(ListsStore.self) private var lists

    @State private var showClearConfirm = false
    @State private var celebrateTrigger = 0
    @State private var recycleTarget: HistoryEntry?
    @State private var isSelecting = false
    @State private var selectedIds: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                displaySection
                if history.groupedEntries().isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .background(theme.color("bg"))
            .navigationTitle(isSelecting ? selectionTitle : "History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isSelecting {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", action: cancelSelection)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: formatShareText(selectedEntries))
                            .disabled(selectedIds.isEmpty)
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Select") { isSelecting = true }
                            .disabled(history.groupedEntries().isEmpty)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") { showClearConfirm = true }
                    }
                }
            }
            .confirmationDialog(
                "Clear history?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear non-favorites", role: .destructive) {
                    history.clearNonFavorites()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Pinned entries stay. This cannot be undone.")
            }
        }
        .overlay {
            if theme.leavesOn {
                LeafBurstView(trigger: celebrateTrigger, originX: 0.5, originY: 0.45)
                    .allowsHitTesting(false)
            }
        }
        .sheet(item: $recycleTarget) { entry in
            RecycleSheet(entry: entry)
        }
    }

    private var selectionTitle: String {
        selectedIds.isEmpty ? "Select Items" : "\(selectedIds.count) Selected"
    }

    private func cancelSelection() {
        isSelecting = false
        selectedIds.removeAll()
    }

    private func toggleSelection(_ entry: HistoryEntry) {
        if selectedIds.contains(entry.id) {
            selectedIds.remove(entry.id)
        } else {
            selectedIds.insert(entry.id)
        }
    }

    private var selectedEntries: [HistoryEntry] {
        history.groupedEntries().flatMap { $0.entries }.filter { selectedIds.contains($0.id) }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.color("muted"))
            TextField("Search your history", text: Binding(
                get: { history.searchText },
                set: { history.searchText = $0 }
            ), prompt: Text("Search your history").foregroundStyle(theme.color("muted")))
            .font(summitBody(15))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surfaceSoft"))
        )
        .padding(16)
    }

    // Display preferences for the calc card's left column. Styled like SoundStudio's
    // togglesSection: toggle rows on a surface card, primaryStrong tint.
    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Display")
                .font(summitBody(11, weight: .semibold))
                .foregroundStyle(theme.color("muted"))
            Toggle(isOn: Binding(
                get: { theme.showCalcLog },
                set: { theme.showCalcLog = $0 }
            )) {
                Text("Show calc log")
                    .font(summitBody(15, weight: .medium))
                    .foregroundStyle(theme.color("text"))
            }
            Toggle(isOn: Binding(
                get: { theme.showChordWheel },
                set: { theme.showChordWheel = $0 }
            )) {
                Text("Show chord scroller")
                    .font(summitBody(15, weight: .medium))
                    .foregroundStyle(theme.color("text"))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: theme.radius)
                .fill(theme.color("surface"))
        )
        .tint(theme.color("primaryStrong"))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("No history yet")
                .font(summitNumber(20))
                .foregroundStyle(theme.color("deep"))
            Text("Your calculations, projections, and lists will show up here.")
                .font(summitBody(14))
                .foregroundStyle(theme.color("muted"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var entryList: some View {
        List {
            ForEach(history.groupedEntries(), id: \.label) { group in
                Section {
                    ForEach(group.entries) { entry in
                        HistoryRow(
                            entry: entry,
                            isFavorite: history.isFavorite(entry),
                            isSelecting: isSelecting,
                            isSelected: selectedIds.contains(entry.id),
                            onTap: { insertEntry(entry) },
                            onFavorite: { history.toggleFavorite(entry) },
                            onRecycle: { recycleTarget = entry },
                            onReopen: { reopenEntry(entry) },
                            onToggleSelect: { toggleSelection(entry) }
                        )
                        .listRowBackground(theme.color("bg"))
                    }
                } header: {
                    Text(group.label)
                        .foregroundStyle(theme.color("muted"))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func insertEntry(_ entry: HistoryEntry) {
        guard entry.type == "calc" else { return }
        if let tokens = entry.extra["tokens"], !tokens.isEmpty {
            calc.replayTokens(tokens)
        } else {
            calc.replayValue(entry.value)
        }
        // One pleasant chime + a leaf burst, instead of machine-gunning every key sound.
        sound.play("success")
        if theme.leavesOn && !reduceMotion {
            celebrateTrigger += 1
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(550))
                dismiss()
            }
        } else {
            dismiss()
        }
    }

    private func reopenEntry(_ entry: HistoryEntry) {
        switch entry.type {
        case "list":
            lists.reopen(from: entry)
            dismiss()
        default:
            break
        }
    }
}

private struct HistoryRow: View {
    @Environment(ThemeStore.self) private var theme
    let entry: HistoryEntry
    let isFavorite: Bool
    let isSelecting: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onRecycle: () -> Void
    let onReopen: () -> Void
    let onToggleSelect: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            leadingAccessory
            Button(action: isSelecting ? onToggleSelect : onTap) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(summitBody(15, weight: .medium))
                            .foregroundStyle(theme.color("text"))
                        Text(kindLabel)
                            .font(summitBody(12))
                            .foregroundStyle(theme.color("muted"))
                    }
                    Spacer()
                    Text(entry.value)
                        .font(summitNumber(16))
                        .foregroundStyle(theme.color("deep"))
                }
            }
            .buttonStyle(.plain)
        }
        .swipeActions(edge: .trailing) {
            if !isSelecting {
                if entry.type == "calc" {
                    Button("Recycle", action: onRecycle)
                        .tint(.orange)
                } else if entry.type == "list" {
                    Button("Reopen", action: onReopen)
                        .tint(.blue)
                }
            }
        }
        .swipeActions(edge: .leading) {
            if !isSelecting {
                Button(isFavorite ? "Unpin" : "Pin", action: onFavorite)
                    .tint(.orange)
            }
        }
    }

    @ViewBuilder
    private var leadingAccessory: some View {
        if isSelecting {
            Button(action: onToggleSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? theme.color("primaryStrong") : theme.color("muted"))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSelected ? "Deselect" : "Select")
        } else {
            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 18))
                    .foregroundStyle(isFavorite ? theme.color("primaryStrong") : theme.color("muted"))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Unpin" : "Pin")
        }
    }

    private var kindLabel: String {
        switch entry.type {
        case "proj": return "Projection"
        case "list": return "List"
        default: return "Calculation"
        }
    }
}

private func entryShareLines(_ entry: HistoryEntry) -> [String] {
    if entry.type == "calc" {
        return calcShareLines(entry)
    }
    return nonCalcShareLines(entry)
}

private func calcShareLines(_ entry: HistoryEntry) -> [String] {
    let rawTokens = entry.extra["tokens"]
    let expression = prettifyExpression(rawTokens) ?? entry.title
    var lines = [expression]
    if let rawTokens {
        let parts = splitCalcTokens(rawTokens)
        let operatorCount = parts.count >= 3 ? (parts.count - 1) / 2 : 0
        if operatorCount > 1 {
            lines += calcReplaySteps(parts)
        }
    }
    lines.append("= \(entry.value)")
    return lines
}

private func splitCalcTokens(_ raw: String) -> [String] {
    let operatorGlyphs: Set<Character> = ["+", "\u{2212}", "\u{00D7}", "\u{00F7}", "*", "/"]
    var parts: [String] = []
    var current = ""
    for ch in raw {
        if operatorGlyphs.contains(ch) {
            if !current.isEmpty {
                parts.append(current)
                current = ""
            }
            parts.append(String(ch))
        } else {
            current.append(ch)
        }
    }
    if !current.isEmpty {
        parts.append(current)
    }
    return parts
}

private func calcReplaySteps(_ parts: [String]) -> [String] {
    guard parts.count >= 3, var accumulator = Double(parts[0]) else { return [] }
    var steps: [String] = []
    var index = 1
    while index + 1 < parts.count {
        let opToken = parts[index]
        guard let operand = Double(parts[index + 1]) else { break }
        let result = calcApplyOp(opToken, accumulator, operand)
        if result.isNaN || result.isInfinite {
            steps.append("= Error")
            return steps
        }
        steps.append("\(Formatters.fmt(accumulator)) \(opToken) \(Formatters.fmt(operand)) = \(Formatters.fmt(result))")
        accumulator = result
        index += 2
    }
    return steps
}

private func calcApplyOp(_ opToken: String, _ a: Double, _ b: Double) -> Double {
    switch opToken {
    case "+":
        return a + b
    case "\u{2212}", "-":
        return a - b
    case "\u{00D7}", "*":
        return a * b
    case "\u{00F7}", "/":
        return b == 0 ? Double.nan : a / b
    default:
        return Double.nan
    }
}

private func prettifyExpression(_ raw: String?) -> String? {
    guard let raw, !raw.isEmpty else { return nil }
    let operators: Set<Character> = ["+", "\u{2212}", "\u{00D7}", "\u{00F7}"]
    var spaced = ""
    for ch in raw {
        if operators.contains(ch) {
            spaced += " \(ch) "
        } else {
            spaced.append(ch)
        }
    }
    return spaced.trimmingCharacters(in: .whitespaces)
}

private func nonCalcShareLines(_ entry: HistoryEntry) -> [String] {
    var lines = [entry.title, entry.value]
    for pair in entry.extra.sorted(by: { $0.key < $1.key }) {
        guard pair.key != "tokens", !pair.value.isEmpty else { continue }
        lines.append("\(pair.key): \(pair.value)")
    }
    return lines
}

private func formatShareText(_ entries: [HistoryEntry]) -> String {
    guard entries.count > 1 else {
        return entries.first.map { entryShareLines($0).joined(separator: "\n") } ?? ""
    }
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .none
    let blocks = entries.map { entry -> String in
        (entryShareLines(entry) + [dateFormatter.string(from: entry.ts)]).joined(separator: "\n")
    }
    return (["Summit Calculator"] + blocks).joined(separator: "\n\n")
}
