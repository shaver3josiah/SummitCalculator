import SwiftUI
import SummitCore

struct RecycleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeStore.self) private var theme
    @Environment(CalcStore.self) private var calc
    @Environment(HistoryStore.self) private var history
    @Environment(SoundStore.self) private var sound

    let entry: HistoryEntry

    @State private var tokens: [String] = []
    @State private var operators: [String] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Change any number, then reuse the result.")
                        .font(summitBody(14))
                        .foregroundStyle(theme.color("muted"))

                    exprPreview

                    VStack(spacing: 10) {
                        ForEach(tokens.indices, id: \.self) { idx in
                            tokenRow(idx)
                        }
                    }
                }
                .padding(20)
            }
            .background(theme.color("bg"))
            .navigationTitle("Recycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyRecycle()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .keyboardDoneBar()
        }
        .onAppear(perform: seedTokens)
    }

    private var exprPreview: some View {
        Text(reconstructedExpression)
            .font(summitNumber(20))
            .foregroundStyle(theme.color("deep"))
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: theme.radius)
                    .fill(theme.color("surfaceSoft"))
            )
    }

    private func tokenRow(_ idx: Int) -> some View {
        HStack {
            Text("Number \(idx + 1)")
                .font(summitBody(14))
                .foregroundStyle(theme.color("muted"))
                .frame(width: 90, alignment: .leading)
            TextField("0", text: binding(for: idx), prompt: Text("0").foregroundColor(theme.color("muted")))
                .keyboardType(.decimalPad)
                .font(summitNumber(18))
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.color("surface"))
                )
        }
    }

    private func binding(for idx: Int) -> Binding<String> {
        Binding(
            get: { idx < tokens.count ? tokens[idx] : "" },
            set: { newValue in
                guard idx < tokens.count else { return }
                tokens[idx] = newValue
            }
        )
    }

    private var reconstructedExpression: String {
        var pieces: [String] = []
        for (i, token) in tokens.enumerated() {
            pieces.append(token)
            if i < operators.count {
                pieces.append(operators[i])
            }
        }
        return pieces.joined(separator: " ")
    }

    private func seedTokens() {
        let sequence = entry.extra["tokens"] ?? entry.extra["sequence"] ?? entry.value
        var nums: [String] = []
        var ops: [String] = []
        var current = ""
        for ch in sequence {
            if "0123456789.".contains(ch) {
                current.append(ch)
            } else if "+\u{2212}\u{00D7}\u{00F7}".contains(ch) || ch == "-" || ch == "*" || ch == "/" {
                if !current.isEmpty {
                    nums.append(current)
                    current = ""
                }
                ops.append(String(ch))
            }
        }
        if !current.isEmpty {
            nums.append(current)
        }
        if nums.isEmpty {
            nums = [entry.value]
        }
        tokens = nums
        operators = ops
    }

    private func applyRecycle() {
        calc.recycle(tokens: tokens)
        sound.play("success")
        dismiss()
    }
}
