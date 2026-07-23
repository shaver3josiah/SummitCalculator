import SwiftUI
import SummitCore

struct RecipePanel: View {
    @Environment(ThemeStore.self) private var theme
    @State private var mode: RecipeMode = .write

    enum RecipeMode { case write, share }

    var body: some View {
        VStack(spacing: 14) {
            Picker("Mode", selection: $mode) {
                Text("Write a recipe").tag(RecipeMode.write)
                Text("Share a link").tag(RecipeMode.share)
            }
            .pickerStyle(.segmented)
            .tint(theme.color("primaryStrong"))

            if mode == .write {
                RecipeWritePanel()
            } else {
                RecipeSharePanel()
            }
        }
    }
}

struct RecipeWritePanel: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(KitchenStore.self) private var kitchen
    @Environment(ListsStore.self) private var lists
    @Environment(SoundStore.self) private var sound

    @State private var name = ""
    @State private var serves = ""
    @State private var time = ""
    @State private var ingredients: [String] = [""]
    @State private var steps: [String] = [""]
    @State private var notes = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Recipe name", text: $name, prompt: Text("Recipe name").foregroundStyle(theme.color("muted")))
                .font(summitBody(15))
                .foregroundStyle(theme.color("text"))
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))

            HStack {
                TextField("Serves 4", text: $serves, prompt: Text("Serves 4").foregroundStyle(theme.color("muted")))
                TextField("45 min", text: $time, prompt: Text("45 min").foregroundStyle(theme.color("muted")))
            }
            .font(summitBody(14))
            .foregroundStyle(theme.color("text"))
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))

            sectionHeader("Ingredients")
            ForEach(ingredients.indices, id: \.self) { idx in
                editableRow(text: bindingFor(\.self, in: $ingredients, idx: idx), placeholder: "1 cup flour") {
                    removeRow(from: &ingredients, at: idx)
                }
            }
            Button("+ ingredient") { ingredients.append("") }
                .font(summitBody(13, weight: .medium))
                .foregroundStyle(theme.color("primaryStrong"))

            sectionHeader("Steps")
            ForEach(steps.indices, id: \.self) { idx in
                editableRow(text: bindingFor(\.self, in: $steps, idx: idx), placeholder: "what to do") {
                    removeRow(from: &steps, at: idx)
                }
            }
            Button("+ step") { steps.append("") }
                .font(summitBody(13, weight: .medium))
                .foregroundStyle(theme.color("primaryStrong"))

            TextField("Notes (storage, swaps, a little love note...)", text: $notes, prompt: Text("Notes (storage, swaps, a little love note...)").foregroundStyle(theme.color("muted")), axis: .vertical)
                .font(summitBody(14))
                .foregroundStyle(theme.color("text"))
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))
                .lineLimit(3...6)

            previewCard

            HStack {
                Button("Add to shopping list") {
                    addToList()
                }
                .font(summitBody(13, weight: .semibold))
                .foregroundStyle(theme.color("primaryStrong"))
                Spacer()
                Button {
                    saveRecipe()
                } label: {
                    Text("Save")
                        .font(summitBody(14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("primaryStrong")))
                        .foregroundStyle(.white)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            shareRow
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
    }

    /// The two share options next to Save: a self-contained "pretty page" (parchment
    /// + gold summit marks HTML that opens in Safari from a text) and a clean numbered
    /// plain-text version for SMS. Both read the live edited draft.
    private var shareRow: some View {
        HStack(spacing: 16) {
            if let url = prettyPageURL() {
                ShareLink(item: url) {
                    Label("Pretty page", systemImage: "sparkles")
                        .font(summitBody(13, weight: .semibold))
                        .foregroundStyle(theme.color("primaryStrong"))
                }
            }
            ShareLink(item: recipeTextForShare) {
                Label("Text version", systemImage: "text.alignleft")
                    .font(summitBody(13, weight: .medium))
                    .foregroundStyle(theme.color("primaryStrong"))
            }
            Spacer()
        }
    }

    private var recipeTextForShare: String {
        RecipeShare.text(name: name, serves: serves, time: time,
                         ingredients: ingredients, steps: steps,
                         notes: notes, sourceUrl: "")
    }

    /// Renders the parchment "pretty page" to a temp .html and returns its URL, so
    /// ShareLink hands the recipient an openable document (a raw HTML *string*
    /// would share as plain text).
    private func prettyPageURL() -> URL? {
        let html = RecipeShare.html(name: name, serves: serves, time: time,
                                    ingredients: ingredients, steps: steps,
                                    notes: notes, sourceUrl: "")
        guard let data = html.data(using: .utf8) else { return nil }
        let base = name.isEmpty ? "Recipe" : String(name.prefix(40))
        let safe = String(base.map { $0.isLetter || $0.isNumber ? $0 : "-" })
        let fileName = safe.trimmingCharacters(in: CharacterSet(charactersIn: "-")).isEmpty ? "Recipe" : safe
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).html")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private var previewText: String {
        var lines: [String] = []
        if !name.isEmpty { lines.append(name) }
        let meta = [serves, time].filter { !$0.isEmpty }.joined(separator: " • ")
        if !meta.isEmpty { lines.append(meta) }
        let ing = ingredients.filter { !$0.isEmpty }
        if !ing.isEmpty {
            lines.append("")
            lines.append("Ingredients:")
            lines.append(contentsOf: ing.map { "- \($0)" })
        }
        let st = steps.filter { !$0.isEmpty }
        if !st.isEmpty {
            lines.append("")
            lines.append("Steps:")
            for (i, s) in st.enumerated() { lines.append("\(i + 1). \(s)") }
        }
        if !notes.isEmpty {
            lines.append("")
            lines.append(notes)
        }
        return lines.joined(separator: "\n")
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Text preview")
                    .font(summitBody(11, weight: .semibold))
                    .foregroundStyle(theme.color("muted"))
                Spacer()
                Text("\(previewText.count) chars")
                    .font(summitBody(11))
                    .foregroundStyle(previewText.count > 1600 ? theme.color("deep") : theme.color("muted"))
            }
            Text(previewText.isEmpty ? "Your recipe preview appears here." : previewText)
                .font(summitBody(13))
                .foregroundStyle(theme.color("text"))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(theme.color("surfaceSoft")))
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(summitBody(13, weight: .semibold))
            .foregroundStyle(theme.color("deep"))
    }

    private func editableRow(text: Binding<String>, placeholder: String, onDelete: @escaping () -> Void) -> some View {
        HStack {
            TextField(placeholder, text: text, prompt: Text(placeholder).foregroundStyle(theme.color("muted")))
                .font(summitBody(14))
                .foregroundStyle(theme.color("text"))
            Button(action: onDelete) {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(theme.color("muted"))
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(theme.color("surface")))
    }

    private func bindingFor(_ keyPath: WritableKeyPath<String, String>, in array: Binding<[String]>, idx: Int) -> Binding<String> {
        Binding(
            get: { idx < array.wrappedValue.count ? array.wrappedValue[idx] : "" },
            set: { newValue in
                guard idx < array.wrappedValue.count else { return }
                array.wrappedValue[idx] = newValue
            }
        )
    }

    private func removeRow(from array: inout [String], at idx: Int) {
        guard array.indices.contains(idx) else { return }
        array.remove(at: idx)
        if array.isEmpty { array.append("") }
    }

    private func addToList() {
        let names = ingredients.filter { !$0.isEmpty }
        for ing in names {
            if let parsed = RecipeParse.parseLine(ing) {
                lists.addIngredient(name: parsed.name)
            } else {
                lists.addIngredient(name: ing)
            }
        }
        sound.play("success")
    }

    private func saveRecipe() {
        let recipe = SavedRecipe(
            name: name.isEmpty ? "Untitled" : name,
            serves: serves,
            time: time,
            ingredients: ingredients.filter { !$0.isEmpty },
            steps: steps.filter { !$0.isEmpty },
            notes: notes
        )
        kitchen.saveRecipe(recipe)
        sound.play("success")
    }
}
