import SwiftUI
import SummitCore

/// Her notebook, at rest. The notes she's kept sit up top; the ones she's
/// archived tuck below in their own section. Tapping any note reopens it on the
/// Notes page (via the shared `mode` binding); every note can be shared as plain
/// text, and any note can become a checklist.
struct NotesArchiveView: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(NotesArchiveStore.self) private var archive
    @Environment(ListsStore.self) private var lists
    @Environment(SoundStore.self) private var sound

    /// The Lists tab's mode ("list" / "notes" / "archive"), owned by ListsView.
    @Binding var mode: String

    var body: some View {
        VStack(spacing: 18) {
            section(title: "Your notes", notes: archive.active, archived: false)
            section(title: "Archive", notes: archive.archivedNotes, archived: true)
            if archive.active.isEmpty && archive.archivedNotes.isEmpty {
                emptyState
            }
        }
    }

    @ViewBuilder
    private func section(title: String, notes: [ArchivedNote], archived: Bool) -> some View {
        if !notes.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(summitBody(13, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(theme.color("muted"))
                VStack(spacing: 10) {
                    ForEach(notes) { note in
                        row(note, archived: archived)
                    }
                }
            }
        }
    }

    private func row(_ note: ArchivedNote, archived: Bool) -> some View {
        HStack(spacing: 12) {
            Button {
                open(note)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.displayTitle)
                        .font(summitNumber(16, weight: .semibold))
                        .foregroundStyle(theme.color("deep"))
                        .lineLimit(1)
                    if !preview(note).isEmpty {
                        Text(preview(note))
                            .font(summitBody(13))
                            .foregroundStyle(theme.color("muted"))
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ShareLink(item: note.shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.color("primaryStrong"))
                    .frame(width: 40, height: 44)
                    .contentShape(Rectangle())
            }

            Menu {
                Button {
                    open(note)
                } label: { Label("Open", systemImage: "square.and.pencil") }

                Button {
                    makeList(from: note)
                } label: { Label("Make a list", systemImage: "checklist") }

                if archived {
                    Button {
                        archive.setArchived(note.id, false)
                        sound.play("tap1")
                    } label: { Label("Move to notes", systemImage: "tray.and.arrow.up") }
                } else {
                    Button {
                        archive.setArchived(note.id, true)
                        sound.play("tap1")
                    } label: { Label("Archive", systemImage: "archivebox") }
                }

                Button(role: .destructive) {
                    if archive.draft.id == note.id { archive.draft = NoteDraft() }
                    archive.delete(note.id)
                    sound.play("clear")
                } label: { Label("Delete", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.color("muted"))
                    .frame(width: 40, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
    }

    private func preview(_ note: ArchivedNote) -> String {
        note.plain
            .split(whereSeparator: \.isNewline)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map(String.init) ?? ""
    }

    private func open(_ note: ArchivedNote) {
        archive.draft = NoteDraft(id: note.id, title: note.title, body: note.plain, rtf: note.rtf)
        mode = "notes"
        sound.play("tap1")
    }

    /// Turn a note's lines into a checklist (bullets and plain lines both count).
    private func makeList(from note: ArchivedNote) {
        let items = ListsStore.listItems(from: note.plain)
        guard !items.isEmpty else {
            ToastCenter.shared.show(title: "Nothing to list", message: "This note has no lines to turn into items.")
            return
        }
        let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = lists.createList(title: title.isEmpty ? "Notes list" : title)
        for item in items {
            lists.addRow(to: id, name: item, qty: 1, unitPrice: 0)
        }
        mode = "list"
        sound.play("success")
        ToastCenter.shared.show(title: "Made a list", message: "\(items.count) item\(items.count == 1 ? "" : "s") added.")
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.closed")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(theme.color("flowerCenter"))
            Text("Your notebook is empty")
                .font(summitNumber(18))
                .foregroundStyle(theme.color("deep"))
            Text("Write a note, then swipe up to keep it here.")
                .font(summitBody(13))
                .foregroundStyle(theme.color("muted"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
