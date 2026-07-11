import SwiftUI
import SummitCore

enum MathSolver: String, Identifiable, CaseIterable {
    case xy
    case quadratic
    case pythagorean
    case fraction

    var id: String { rawValue }

    var title: String {
        switch self {
        case .xy: return "XY equations"
        case .quadratic: return "Quadratic"
        case .pythagorean: return "Pythagorean"
        case .fraction: return "Fractions"
        }
    }
}

struct MathSolverSheet: View {
    let solver: MathSolver
    var onSend: (Double) -> Void

    var body: some View {
        switch solver {
        case .xy:
            XYSolver(onSend: onSend)
        case .quadratic:
            QuadraticSolver(onSend: onSend)
        case .pythagorean:
            PythagoreanSolver(onSend: onSend)
        case .fraction:
            FractionSolver(onSend: onSend)
        }
    }
}

private struct SolverScaffold<Content: View>: View {
    @Environment(ThemeStore.self) private var theme
    @Environment(\.dismiss) private var dismiss
    let title: String
    let caption: String
    @ViewBuilder var content: Content

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(caption)
                        .font(summitBody(12))
                        .foregroundStyle(theme.color("muted"))
                    content
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(theme.color("bg"))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(summitBody(15, weight: .semibold))
                }
            }
            .keyboardDoneBar()
        }
    }
}

private struct SolverField: View {
    @Environment(ThemeStore.self) private var theme
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(summitBody(11, weight: .medium))
                .foregroundStyle(theme.color("muted"))
            TextField("", text: $text, prompt: Text("0").foregroundColor(theme.color("muted")))
                .keyboardType(.numbersAndPunctuation)
                .font(summitNumber(17))
                .foregroundStyle(theme.color("text"))
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surfaceSoft")))
        }
    }
}

private struct SendPill: View {
    @Environment(ThemeStore.self) private var theme
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(summitBody(14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 999).fill(theme.color("primaryStrong")))
        }
        .buttonStyle(.plain)
    }
}

private struct ResultText: View {
    @Environment(ThemeStore.self) private var theme
    let text: String
    var body: some View {
        Text(text)
            .font(summitNumber(18, weight: .semibold))
            .foregroundStyle(theme.color("deep"))
    }
}

private struct HintText: View {
    @Environment(ThemeStore.self) private var theme
    let text: String
    var body: some View {
        Text(text)
            .font(summitBody(13))
            .foregroundStyle(theme.color("muted"))
    }
}

private func fmtComplex(_ z: ComplexValue) -> String {
    if z.isReal { return Formatters.fmt(z.re) }
    let sign = z.im >= 0 ? "+" : "−"
    return "\(Formatters.fmt(z.re)) \(sign) \(Formatters.fmt(abs(z.im)))i"
}

private struct XYSolver: View {
    var onSend: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var a1 = ""
    @State private var b1 = ""
    @State private var c1 = ""
    @State private var a2 = ""
    @State private var b2 = ""
    @State private var c2 = ""

    private func num(_ s: String) -> Double { Double(s) ?? 0 }
    private var result: (x: Double, y: Double)? {
        MathModes.linearSystem(a1: num(a1), b1: num(b1), c1: num(c1), a2: num(a2), b2: num(b2), c2: num(c2))
    }

    var body: some View {
        SolverScaffold(title: "XY equations", caption: "a₁x + b₁y = c₁  and  a₂x + b₂y = c₂") {
            HStack(spacing: 8) {
                SolverField(label: "a₁", text: $a1)
                SolverField(label: "b₁", text: $b1)
                SolverField(label: "c₁", text: $c1)
            }
            HStack(spacing: 8) {
                SolverField(label: "a₂", text: $a2)
                SolverField(label: "b₂", text: $b2)
                SolverField(label: "c₂", text: $c2)
            }
            if let s = result {
                ResultText(text: "x = \(Formatters.fmt(s.x))     y = \(Formatters.fmt(s.y))")
                SendPill(label: "Send x = \(Formatters.fmt(s.x))") { onSend(s.x); dismiss() }
                SendPill(label: "Send y = \(Formatters.fmt(s.y))") { onSend(s.y); dismiss() }
            } else {
                HintText(text: "No unique solution. The two lines are parallel or the same line.")
            }
        }
    }
}

private struct QuadraticSolver: View {
    var onSend: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var a = ""
    @State private var b = ""
    @State private var c = ""

    private func num(_ s: String) -> Double { Double(s) ?? 0 }
    private var result: (discriminant: Double, roots: [ComplexValue])? {
        MathModes.quadratic(a: num(a), b: num(b), c: num(c))
    }

    var body: some View {
        SolverScaffold(title: "Quadratic", caption: "a x² + b x + c = 0") {
            HStack(spacing: 8) {
                SolverField(label: "a", text: $a)
                SolverField(label: "b", text: $b)
                SolverField(label: "c", text: $c)
            }
            if let r = result {
                if r.discriminant.isFinite {
                    HintText(text: "Discriminant = \(Formatters.fmt(r.discriminant))")
                }
                ForEach(r.roots.indices, id: \.self) { idx in
                    let z = r.roots[idx]
                    if z.isReal {
                        SendPill(label: "x\(idx + 1) = \(Formatters.fmt(z.re))  ·  send") { onSend(z.re); dismiss() }
                    } else {
                        ResultText(text: "x\(idx + 1) = \(fmtComplex(z))")
                    }
                }
            } else {
                HintText(text: "Enter a, b and c (a and b can't both be zero).")
            }
        }
    }
}

private struct PythagoreanSolver: View {
    var onSend: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var a = ""
    @State private var b = ""
    @State private var c = ""

    private func opt(_ s: String) -> Double? { s.isEmpty ? nil : Double(s) }
    private var result: (side: PythSide, value: Double)? {
        MathModes.pythagorean(a: opt(a), b: opt(b), c: opt(c))
    }

    var body: some View {
        SolverScaffold(title: "Pythagorean", caption: "a² + b² = c². Fill any two, leave the unknown blank.") {
            HStack(spacing: 8) {
                SolverField(label: "a (leg)", text: $a)
                SolverField(label: "b (leg)", text: $b)
                SolverField(label: "c (hyp)", text: $c)
            }
            if let r = result {
                ResultText(text: "\(sideLabel(r.side)) = \(Formatters.fmt(r.value))")
                SendPill(label: "Send \(Formatters.fmt(r.value))") { onSend(r.value); dismiss() }
            } else {
                HintText(text: "Fill exactly two sides. A leg must be shorter than the hypotenuse.")
            }
        }
    }

    private func sideLabel(_ side: PythSide) -> String {
        switch side {
        case .hypotenuse: return "c"
        case .legA: return "a"
        case .legB: return "b"
        }
    }
}

private struct FractionSolver: View {
    var onSend: (Double) -> Void
    @Environment(ThemeStore.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var n1 = ""
    @State private var d1 = ""
    @State private var n2 = ""
    @State private var d2 = ""
    @State private var op: FractionOp = .add

    private func int(_ s: String) -> Int? { Int(s) }
    private var result: FractionValue? {
        guard let a = int(n1), let b = int(d1), let c = int(n2), let e = int(d2) else { return nil }
        return MathModes.fraction(a, b, op, c, e)
    }

    var body: some View {
        SolverScaffold(title: "Fractions", caption: "Simplify the result of two fractions.") {
            HStack(spacing: 8) {
                fractionColumn(num: $n1, den: $d1)
                opColumn
                fractionColumn(num: $n2, den: $d2)
            }
            if let f = result {
                ResultText(text: "= \(f.num)/\(f.den)   (\(Formatters.fmt(f.decimal)))")
                SendPill(label: "Send \(Formatters.fmt(f.decimal))") { onSend(f.decimal); dismiss() }
            } else {
                HintText(text: "Enter whole numbers. Denominators can't be zero.")
            }
        }
    }

    private func fractionColumn(num: Binding<String>, den: Binding<String>) -> some View {
        VStack(spacing: 6) {
            SolverField(label: "numerator", text: num)
            SolverField(label: "denominator", text: den)
        }
    }

    private var opColumn: some View {
        VStack(spacing: 6) {
            ForEach(FractionOp.allCases, id: \.self) { candidate in
                Button {
                    op = candidate
                } label: {
                    Text(candidate.rawValue)
                        .font(summitNumber(16, weight: .semibold))
                        .foregroundStyle(op == candidate ? .white : theme.color("primaryStrong"))
                        .frame(width: 34, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(op == candidate ? theme.color("primaryStrong") : theme.color("surfaceSoft"))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
