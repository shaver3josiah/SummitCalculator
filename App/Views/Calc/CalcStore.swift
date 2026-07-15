import Foundation
import SummitCore

enum CalcMathMode: String, CaseIterable {
    case memory
    case complex
    case trig

    var title: String {
        switch self {
        case .memory: return "MEMORY"
        case .complex: return "COMPLEX"
        case .trig: return "TRIG"
        }
    }

    var next: CalcMathMode {
        switch self {
        case .memory: return .complex
        case .complex: return .trig
        case .trig: return .memory
        }
    }
}

@Observable
final class CalcStore {
    var display: String = "0"
    var expression: String = " "
    var memoryValue: Double = 0 {
        didSet { JSONStore.shared.set(.memory, memoryValue) }
    }
    var lastEgg: Egg?
    var eggEpoch: Int = 0
    var resultEpoch: Int = 0
    var mathMode: CalcMathMode = .complex
    var angleMode: AngleMode = .radians

    private var engine = CalcEngine()

    /// Key string of the queued operator (matches press()'s keys) so a keypad button
    /// can compare against its own key; nil once a digit is typed.
    var pendingOpKey: String? {
        switch engine.pendingOp {
        case .add: "+"
        case .subtract: "-"
        case .multiply: "*"
        case .divide: "/"
        case nil: nil
        }
    }
    private var sequence: [String] = []
    private var muted = false   // silences key sounds during programmatic replay
    private weak var history: HistoryStore?
    private weak var sounds: SoundStore?

    /// Single sound gate — no-op while `muted` (e.g. replaying a history entry).
    private func emit(_ event: String) {
        guard !muted else { return }
        sounds?.play(event)
    }

    init(history: HistoryStore?, sounds: SoundStore?) {
        self.history = history
        self.sounds = sounds
        memoryValue = JSONStore.shared.get(.memory, as: Double.self) ?? 0
    }

    init() {
        self.history = nil
        self.sounds = nil
        memoryValue = JSONStore.shared.get(.memory, as: Double.self) ?? 0
    }

    func press(_ key: String) {
        switch key {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            guard let d = key.first else { return }
            engine.digit(d)
            sequence.append(key)
            refreshDisplay()
            emit("d\(d)")
        case ".":
            engine.dot()
            sequence.append(".")
            refreshDisplay()
            emit("dot")
        case "+":
            engine.setOp(.add)
            sequence.append("+")
            refreshDisplay()
            emit("op+")
        case "-":
            engine.setOp(.subtract)
            sequence.append("−")
            refreshDisplay()
            emit("op-")
        case "*":
            engine.setOp(.multiply)
            sequence.append("×")
            refreshDisplay()
            emit("op*")
        case "/":
            engine.setOp(.divide)
            sequence.append("÷")
            refreshDisplay()
            emit("op/")
        case "=":
            handleEquals()
        case "C":
            engine.clearAll()
            sequence.removeAll()
            refreshDisplay()
            emit("clear")
        case "±":
            engine.toggleSign()
            refreshDisplay()
            emit("sign")
        case "%":
            engine.percent()
            refreshDisplay()
            emit("percent")
        case "⌫":
            engine.backspace()
            if !sequence.isEmpty {
                sequence.removeLast()
            }
            refreshDisplay()
            emit("clear")
        case "MC":
            memoryValue = 0
            emit("memory")
        case "MR":
            recallMemory()
            emit("memory")
        case "M+":
            if let value = Double(display) {
                memoryValue += value
            }
            emit("memory")
        case "M-":
            if let value = Double(display) {
                memoryValue -= value
            }
            emit("memory")
        default:
            break
        }
    }

    /// Rebuild a plain display value (e.g. a negative result) silently, treating a
    /// leading "-" as a sign toggle rather than the subtract operator.
    func replayValue(_ value: String) {
        muted = true
        defer { muted = false }
        press("C")
        for ch in value {
            switch ch {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                press(String(ch))
            case ".":
                press(".")
            case "-":
                press("±")
            default:
                continue
            }
        }
    }

    func replayTokens(_ tokens: String) {
        muted = true
        defer { muted = false }
        press("C")
        for character in tokens {
            switch character {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                press(String(character))
            case ".":
                press(".")
            case "+":
                press("+")
            case "\u{2212}", "-":
                press("-")
            case "\u{00D7}", "*":
                press("*")
            case "\u{00F7}", "/":
                press("/")
            default:
                break
            }
        }
    }

    func cycleMathMode() {
        mathMode = mathMode.next
        emit("modeswitch")
    }

    func toggleAngleMode() {
        angleMode = angleMode == .radians ? .degrees : .radians
        emit("memory")
    }

    func applyTrig(_ fn: TrigFunction) {
        let value = Double(engine.current) ?? 0
        let result = MathModes.trig(fn, value, mode: angleMode)
        guard result.isFinite else {
            display = "Error"
            emit("error")
            return
        }
        engine.setValue(result)
        refreshDisplay()
        history?.add(type: "calc", title: "\(fn.rawValue) (\(angleMode.shortLabel))", value: display, extra: [:])
        emit("memory")
    }

    func sendValue(_ value: Double) {
        guard value.isFinite else { return }
        engine.setValue(value)
        refreshDisplay()
        emit("memory")
    }

    private func handleEquals() {
        guard let result = engine.equals() else {
            refreshDisplay()
            return
        }
        display = result.display
        expression = result.expression

        let tokenSequence = result.sequence
        if display == "Error" {
            emit("error")
        } else {
            history?.add(
                type: "calc",
                title: "Calculation",
                value: display,
                extra: ["tokens": tokenSequence]
            )
            resultEpoch += 1   // result summit on every successful "="
            if let egg = EasterEggs.match(sequence: tokenSequence) {
                lastEgg = egg
                eggEpoch += 1
                emit("easteregg")
            } else {
                emit("equals")
            }
        }
        sequence.removeAll()
    }

    private func refreshDisplay() {
        display = engine.displayText
        expression = engine.expressionText
    }

    private func recallMemory() {
        engine.clearAll()
        sequence.removeAll()
        let magnitude = SummitCore.Formatters.plain(abs(memoryValue))
        for character in magnitude {
            if character == "." {
                engine.dot()
            } else {
                engine.digit(character)
            }
        }
        if memoryValue < 0 {
            engine.toggleSign()
        }
        refreshDisplay()
    }
}
