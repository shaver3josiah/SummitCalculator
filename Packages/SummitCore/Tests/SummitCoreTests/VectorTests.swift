import XCTest
@testable import SummitCore

final class VectorTests: XCTestCase {
    struct VectorFile: Decodable {
        let formatters: [FormatterVector]
        let finance: [FinanceVector]
        let calc: [CalcVector]
        let eggs: [EggVector]
        let recipe: [RecipeVector]
        let convert: [ConvertVector]
    }

    struct FormatterVector: Decodable {
        let fn: String
        let arg: Double
        let expect: String
    }

    struct FinanceVector: Decodable {
        let fn: String
        let args: [String: Double]
        let raw: Double
        let expect: String
    }

    struct CalcVector: Decodable {
        let keys: [String]
        let display: String
        let sequence: String
    }

    struct EggVector: Decodable {
        let sequence: String
        let match: String?
    }

    struct RecipeVector: Decodable {
        let line: String
        let qty: Double?
        let unit: String?
        let name: String?
    }

    struct ConvertVector: Decodable {
        let value: Double
        let from: String
        let to: String
        let expect: Double
    }

    static let vectors: VectorFile = loadVectors()

    static func loadVectors() -> VectorFile {
        guard let url = Bundle.module.url(forResource: "vectors", withExtension: "json") else {
            XCTFail("vectors.json not found in test bundle")
            return VectorFile(formatters: [], finance: [], calc: [], eggs: [], recipe: [], convert: [])
        }
        guard let data = try? Data(contentsOf: url) else {
            XCTFail("could not read vectors.json")
            return VectorFile(formatters: [], finance: [], calc: [], eggs: [], recipe: [], convert: [])
        }
        guard let decoded = try? JSONDecoder().decode(VectorFile.self, from: data) else {
            XCTFail("could not decode vectors.json")
            return VectorFile(formatters: [], finance: [], calc: [], eggs: [], recipe: [], convert: [])
        }
        return decoded
    }

    func testFormatterCount() {
        XCTAssertEqual(VectorTests.vectors.formatters.count, 168)
    }

    func testFormatters() {
        for v in VectorTests.vectors.formatters {
            let got: String
            switch v.fn {
            case "fmt":
                got = Formatters.fmt(v.arg)
            case "plain":
                got = Formatters.plain(v.arg)
            case "money":
                got = Formatters.money(v.arg)
            case "usd":
                got = Formatters.usd(v.arg)
            default:
                XCTFail("unknown formatter fn \(v.fn)")
                continue
            }
            XCTAssertEqual(got, v.expect, "\(v.fn)(\(v.arg))")
        }
    }

    func testFinanceCount() {
        XCTAssertEqual(VectorTests.vectors.finance.count, 35)
    }

    func testFinance() {
        for v in VectorTests.vectors.finance {
            let a = v.args
            let raw: Double
            switch v.fn {
            case "futureValue":
                raw = FinanceMath.futureValue(principal: a["principal"] ?? 0, monthly: a["monthly"] ?? 0, annualRatePct: a["annualRatePct"] ?? 0, years: a["years"] ?? 0)
            case "contributions":
                raw = FinanceMath.contributions(principal: a["principal"] ?? 0, monthly: a["monthly"] ?? 0, years: a["years"] ?? 0)
            case "loanPayment":
                raw = FinanceMath.loanPayment(principal: a["principal"] ?? 0, annualRatePct: a["annualRatePct"] ?? 0, years: a["years"] ?? 0)
            case "savingsGoalPayment":
                raw = FinanceMath.savingsGoalPayment(target: a["target"] ?? 0, principal: a["principal"] ?? 0, annualRatePct: a["annualRatePct"] ?? 0, years: a["years"] ?? 0)
            case "realRate":
                raw = FinanceMath.realRate(nominalPct: a["nominalPct"] ?? 0, inflationPct: a["inflationPct"] ?? 0)
            case "employerMatch":
                raw = FinanceMath.employerMatch(salary: a["salary"] ?? 0, contribPct: a["contribPct"] ?? 0, matchPct: a["matchPct"] ?? 0, matchLimitPct: a["matchLimitPct"] ?? 0)
            case "ruleOf72":
                raw = FinanceMath.ruleOf72(ratePct: a["ratePct"] ?? 0)
            case "tip":
                raw = FinanceMath.tip(bill: a["bill"] ?? 0, tipPct: a["tipPct"] ?? 0, people: Int(a["people"] ?? 1)).total
            case "percentOf":
                raw = FinanceMath.percentOf(a["pct"] ?? 0, of: a["value"] ?? 0)
            case "percentChange":
                raw = FinanceMath.percentChange(from: a["a"] ?? 0, to: a["b"] ?? 0)
            default:
                XCTFail("unknown finance fn \(v.fn)")
                continue
            }
            assertRelativelyClose(raw, v.raw, label: v.fn)
            let display: String
            switch v.fn {
            case "futureValue", "contributions":
                display = Formatters.usd(raw)
            case "loanPayment", "savingsGoalPayment", "tip":
                display = Formatters.money(raw)
            case "employerMatch":
                display = Formatters.money(raw)
            default:
                display = Formatters.fmt(raw)
            }
            XCTAssertEqual(display, v.expect, "\(v.fn) display")
        }
    }

    func testCalcCount() {
        XCTAssertEqual(VectorTests.vectors.calc.count, 28)
    }

    func testCalc() {
        for v in VectorTests.vectors.calc {
            var engine = CalcEngine()
            var lastResult: CalcResult? = nil
            for key in v.keys {
                if key.count == 1, let ch = key.first, ch.isNumber {
                    engine.digit(ch)
                    continue
                }
                switch key {
                case ".":
                    engine.dot()
                case "+":
                    engine.setOp(.add)
                case "-", "\u{2212}":
                    engine.setOp(.subtract)
                case "*", "\u{00d7}":
                    engine.setOp(.multiply)
                case "/", "\u{00f7}":
                    engine.setOp(.divide)
                case "=":
                    lastResult = engine.equals()
                case "C", "AC":
                    engine.clearAll()
                case "+/-", "\u{00b1}":
                    engine.toggleSign()
                case "%":
                    engine.percent()
                default:
                    XCTFail("unknown key \(key)")
                }
            }
            let display = lastResult?.display ?? engine.displayText
            let sequence = lastResult?.sequence ?? engine.expressionText.replacingOccurrences(of: " ", with: "")
            XCTAssertEqual(display, v.display, "keys \(v.keys)")
            XCTAssertEqual(sequence, v.sequence, "keys \(v.keys)")
        }
    }

    func testPendingOp() {
        var engine = CalcEngine()
        XCTAssertNil(engine.pendingOp)          // nothing queued at rest
        engine.digit("5")
        XCTAssertNil(engine.pendingOp)          // typing an operand: still nothing queued
        engine.setOp(.add)
        XCTAssertEqual(engine.pendingOp, .add)  // operator pressed, awaiting operand
        engine.digit("3")
        XCTAssertNil(engine.pendingOp)          // next digit clears the highlight
        _ = engine.equals()
        XCTAssertNil(engine.pendingOp)          // equals resets
    }

    func testEggCount() {
        XCTAssertEqual(VectorTests.vectors.eggs.count, 18)
    }

    func testEggs() {
        for v in VectorTests.vectors.eggs {
            let got = EasterEggs.match(sequence: v.sequence)?.id
            XCTAssertEqual(got, v.match, "sequence \(v.sequence)")
        }
    }

    func testRecipeCount() {
        XCTAssertEqual(VectorTests.vectors.recipe.count, 22)
    }

    func testRecipe() {
        for v in VectorTests.vectors.recipe {
            let parsed = RecipeParse.parseLine(v.line)
            if v.qty == nil {
                XCTAssertNil(parsed?.qty, v.line)
            } else {
                XCTAssertNotNil(parsed?.qty, v.line)
                if let got = parsed?.qty, let expect = v.qty {
                    assertRelativelyClose(got, expect, label: v.line)
                }
            }
            XCTAssertEqual(parsed?.unit, v.unit, v.line)
            XCTAssertEqual(parsed?.name, v.name, v.line)
        }
    }

    func testConvertCount() {
        XCTAssertEqual(VectorTests.vectors.convert.count, 12)
    }

    func testConvert() {
        for v in VectorTests.vectors.convert {
            let got = UnitConvert.convert(v.value, from: v.from, to: v.to)
            XCTAssertNotNil(got, "\(v.from) to \(v.to)")
            if let got = got {
                assertRelativelyClose(Formatters.round8(got), v.expect, label: "\(v.from) to \(v.to)")
            }
        }
    }

    func assertRelativelyClose(_ got: Double, _ expect: Double, label: String, file: StaticString = #filePath, line: UInt = #line) {
        if expect == 0 {
            XCTAssertTrue(abs(got) < 1e-9, "\(label): expected ~0, got \(got)", file: file, line: line)
            return
        }
        let rel = abs((got - expect) / expect)
        XCTAssertTrue(rel < 1e-9, "\(label): expected \(expect), got \(got), rel \(rel)", file: file, line: line)
    }
}
