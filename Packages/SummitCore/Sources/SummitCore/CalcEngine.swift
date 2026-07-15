import Foundation

public struct CalcEngine: Sendable {
    public private(set) var current: String
    public private(set) var overwrite: Bool

    private var stored: Double?
    private var op: CalcOp?
    private var parts: [String]

    public init() {
        current = "0"
        overwrite = true
        stored = nil
        op = nil
        parts = []
    }

    public mutating func digit(_ d: Character) {
        if overwrite {
            current = String(d)
            overwrite = false
        } else {
            current = current == "0" ? String(d) : current + String(d)
        }
    }

    public mutating func dot() {
        if overwrite {
            current = "0."
            overwrite = false
        } else if !current.contains(".") {
            current += "."
        }
    }

    public mutating func setOp(_ newOp: CalcOp) {
        let sym = CalcEngine.symbol(for: newOp)
        if overwrite && op != nil {
            op = newOp
            if !parts.isEmpty {
                parts[parts.count - 1] = sym
            }
            return
        }
        parts.append(current)
        parts.append(sym)
        if let activeOp = op, !overwrite {
            let a = stored ?? 0
            let b = Double(current) ?? 0
            let res = CalcEngine.compute(a, b, activeOp)
            stored = res
            current = Formatters.plain(res)
        } else {
            stored = Double(current) ?? 0
        }
        op = newOp
        overwrite = true
    }

    public mutating func equals() -> CalcResult? {
        guard let activeOp = op else {
            return nil
        }
        let a = stored ?? 0
        let b = Double(current) ?? 0
        let res = CalcEngine.compute(a, b, activeOp)
        parts.append(current)
        let seq = parts.joined()
        let exprText = parts.joined(separator: " ")
        let finite = res.isFinite
        let display = finite ? Formatters.fmt(res) : "Error"
        current = finite ? Formatters.plain(res) : "0"
        stored = nil
        op = nil
        overwrite = true
        parts = []
        return CalcResult(display: display, expression: exprText, sequence: seq)
    }

    public mutating func clearAll() {
        current = "0"
        stored = nil
        op = nil
        overwrite = true
        parts = []
    }

    public mutating func toggleSign() {
        if current != "0" {
            current = current.hasPrefix("-") ? String(current.dropFirst()) : "-" + current
        }
    }

    public mutating func percent() {
        let v = (Double(current) ?? 0) / 100.0
        current = Formatters.plain(v)
        overwrite = true
    }

    public mutating func setValue(_ v: Double) {
        current = Formatters.plain(v)
        overwrite = true
    }

    public mutating func backspace() {
        if overwrite {
            return
        }
        if current.count <= 1 || (current.count == 2 && current.hasPrefix("-")) {
            current = "0"
            overwrite = true
            return
        }
        current.removeLast()
        if current == "-" {
            current = "0"
            overwrite = true
        }
    }

    public var displayText: String {
        return current
    }

    public var expressionText: String {
        return parts.isEmpty ? "" : parts.joined(separator: " ")
    }

    // Pending = operator pressed, waiting for the next operand (overwrite still true).
    // Typing a digit sets overwrite=false, so this returns nil and the highlight clears.
    public var pendingOp: CalcOp? { overwrite ? op : nil }

    private static func compute(_ a: Double, _ b: Double, _ op: CalcOp) -> Double {
        switch op {
        case .add:
            return a + b
        case .subtract:
            return a - b
        case .multiply:
            return a * b
        case .divide:
            return b == 0 ? Double.nan : a / b
        }
    }

    private static func symbol(for op: CalcOp) -> String {
        switch op {
        case .add:
            return "+"
        case .subtract:
            return "\u{2212}"
        case .multiply:
            return "\u{00d7}"
        case .divide:
            return "\u{00f7}"
        }
    }
}
