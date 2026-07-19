import SwiftUI
import SummitCore

// Her notebook. `draft` is the live page she's typing (persisted on a debounce so
// a tab switch or a phone lock never costs a word — Summit has no DraftStore, so
// the live note lives here). `notes` holds the ones she's chosen to keep — some
// active, some tucked into the archive. Rich text is stored as RTF Data so bold,
// italics, headings and fonts all survive; `plain` is the plain-text mirror kept
// for search, sharing, and turning a note into a list.

/// The live page. Ties to a saved/archived note by `id` when she reopens one, so
/// re-saving updates instead of duplicating.
struct NoteDraft: Codable, Equatable {
    var id: UUID? = nil
    var title = ""
    var body = ""
    var rtf: Data? = nil
}

struct ArchivedNote: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var plain: String
    var rtf: Data?
    var savedAt: Date = Date()
    var archived: Bool = false

    var displayTitle: String {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { return t }
        // Fall back to the first non-empty line of the body.
        let firstLine = plain.split(whereSeparator: \.isNewline)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return firstLine.map(String.init) ?? "Untitled note"
    }

    /// Plain text she can drop into a message: title, a blank line, then the words.
    var shareText: String {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let head = t.isEmpty ? "" : t + "\n\n"
        return head + plain.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@Observable
final class NotesArchiveStore {
    private(set) var notes: [ArchivedNote] = []

    /// The live page she's writing. Persisted on a debounce (see below).
    var draft = NoteDraft() { didSet { scheduleDraftPersist() } }

    /// Active notes (not archived), newest first.
    var active: [ArchivedNote] { notes.filter { !$0.archived }.sorted { $0.savedAt > $1.savedAt } }
    /// The archive, newest first.
    var archivedNotes: [ArchivedNote] { notes.filter { $0.archived }.sorted { $0.savedAt > $1.savedAt } }

    private var draftHydrated = false
    private var draftSaveTask: Task<Void, Never>?

    init() {
        notes = JSONStore.shared.get(.notesArchive, as: [ArchivedNote].self) ?? []
        draft = JSONStore.shared.get(.notesDraft, as: NoteDraft.self) ?? NoteDraft()
        draftHydrated = true
    }

    /// Insert or update by id, stamping the save time so it sorts to the top.
    /// An empty note (no title, no words) is never stored — swiping up on a blank
    /// page shouldn't litter her notebook.
    @discardableResult
    func save(_ note: ArchivedNote) -> ArchivedNote? {
        var n = note
        n.savedAt = Date()
        let hasContent = !n.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !n.plain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard hasContent else {
            // If this was an existing saved note she cleared to nothing, drop it.
            if let idx = notes.firstIndex(where: { $0.id == n.id }) {
                notes.remove(at: idx); persist()
            }
            return nil
        }
        if let idx = notes.firstIndex(where: { $0.id == n.id }) {
            notes[idx] = n
        } else {
            notes.append(n)
        }
        persist()
        return n
    }

    func setArchived(_ id: UUID, _ archived: Bool) {
        guard let idx = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[idx].archived = archived
        persist()
    }

    /// Copy a note as a brand-new active note, returned so the editor can open it.
    func duplicate(_ note: ArchivedNote) -> ArchivedNote {
        var copy = note
        copy.id = UUID()
        copy.title = note.title.isEmpty ? "" : note.title + " copy"
        copy.archived = false
        copy.savedAt = Date()
        notes.append(copy)
        persist()
        return copy
    }

    func delete(_ id: UUID) {
        notes.removeAll { $0.id == id }
        persist()
    }

    func note(id: UUID?) -> ArchivedNote? {
        guard let id else { return nil }
        return notes.first { $0.id == id }
    }

    private func persist() {
        JSONStore.shared.set(.notesArchive, notes)
    }

    /// Debounced draft save — she types fast, and rewriting the file per keystroke
    /// is the exact anti-pattern to avoid. 0.8s after she stops.
    private func scheduleDraftPersist() {
        guard draftHydrated else { return }
        draftSaveTask?.cancel()
        draftSaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            JSONStore.shared.set(.notesDraft, draft)
        }
    }

    /// Last-chance write when the app leaves the foreground (the debounce may be pending).
    func flushDraft() {
        draftSaveTask?.cancel()
        JSONStore.shared.set(.notesDraft, draft)
    }
}
