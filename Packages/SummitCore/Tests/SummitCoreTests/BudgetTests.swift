import XCTest
@testable import SummitCore

final class BudgetTests: XCTestCase {
    struct BudgetVectorFile: Decodable {
        let budgetNetOf: [NetOfVector]
        let budgetTakeHome: [TakeHomeVector]
        let budgetCatTotals: [CatTotalsVector]
        let budgetPlanned: [PlannedVector]
        let budgetImportRow: [ImportRowVector]
        let budgetPerDay: [PerDayVector]
        let budgetChartYMax: [ChartYMaxVector]
        let budgetMonthDays: [MonthDaysVector]
        let budgetYmKey: [YmKeyVector]
        let budgetParseYM: [ParseYMVector]
        let budgetMonthLabel: [MonthLabelVector]
        let budgetMonthSwitch: [MonthSwitchVector]
        let budgetYearAggregate: [YearAggregateVector]
        let budgetShare: [ShareVector]
    }

    struct NetOfVector: Decodable {
        let income: BudgetIncome
        let expect: Double
    }

    struct TakeHomeVector: Decodable {
        let month: BudgetMonth
        let expect: Double
    }

    struct CatTotalsVector: Decodable {
        let cat: BudgetCategory
        let total: Double
        let sel: Double
    }

    struct PlannedVector: Decodable {
        let month: BudgetMonth
        let expect: Double
    }

    struct ImportRowVector: Decodable {
        let name: String
        let qty: Double?
        let amount: Double
        let expect: BudgetRow
    }

    struct PerDayVector: Decodable {
        let fn: String
        let sel: Double
        let days: Int
        let today: Int?
        let expect: Double
    }

    struct ChartYMaxVector: Decodable {
        let sels: [Double]
        let goals: [Double?]
        let expect: Double
    }

    struct MonthDaysVector: Decodable {
        let key: String
        let expect: Int
    }

    struct YmKeyVector: Decodable {
        let year: Int
        let month: Int
        let expect: String
    }

    struct ParseYMResult: Decodable, Equatable {
        let year: Int
        let month: Int
    }

    struct ParseYMVector: Decodable {
        let key: String
        let expect: ParseYMResult?
    }

    struct MonthLabelVector: Decodable {
        let key: String
        let expect: String
    }

    struct MonthSwitchVector: Decodable {
        let scenario: String
        let db: BudgetDB
        let target: String
        let resultMonth: BudgetMonth
        let copiedFrom: String?
    }

    struct YearAggregateVector: Decodable {
        let db: BudgetDB
        let year: Int
        let expect: [YearEntryDecoded]
    }

    struct YearEntryDecoded: Decodable, Equatable {
        let key: String
        let has: Bool
        let planned: Double
        let takeHome: Double
    }

    struct ShareVector: Decodable {
        let cur: String
        let month: BudgetMonth
        let fixtureText: String
        let decoded: DecodedPayload
        let expectDb: BudgetDB
    }

    struct DecodedPayload: Decodable {
        let k: String
        let m: BudgetMonth
    }

    static let vectors: BudgetVectorFile = loadVectors()

    static func loadVectors() -> BudgetVectorFile {
        guard let url = Bundle.module.url(forResource: "vectors", withExtension: "json") else {
            XCTFail("vectors.json not found in test bundle")
            return emptyVectorFile()
        }
        guard let data = try? Data(contentsOf: url) else {
            XCTFail("could not read vectors.json")
            return emptyVectorFile()
        }
        guard let decoded = try? JSONDecoder().decode(BudgetVectorFile.self, from: data) else {
            XCTFail("could not decode budget vectors from vectors.json")
            return emptyVectorFile()
        }
        return decoded
    }

    static func emptyVectorFile() -> BudgetVectorFile {
        return BudgetVectorFile(budgetNetOf: [], budgetTakeHome: [], budgetCatTotals: [], budgetPlanned: [],
            budgetImportRow: [], budgetPerDay: [], budgetChartYMax: [], budgetMonthDays: [], budgetYmKey: [],
            budgetParseYM: [], budgetMonthLabel: [], budgetMonthSwitch: [], budgetYearAggregate: [], budgetShare: [])
    }

    func testBudgetVectorCounts() {
        XCTAssertGreaterThanOrEqual(
            BudgetTests.vectors.budgetNetOf.count + BudgetTests.vectors.budgetTakeHome.count
                + BudgetTests.vectors.budgetCatTotals.count + BudgetTests.vectors.budgetPlanned.count
                + BudgetTests.vectors.budgetImportRow.count + BudgetTests.vectors.budgetPerDay.count
                + BudgetTests.vectors.budgetChartYMax.count + BudgetTests.vectors.budgetMonthDays.count
                + BudgetTests.vectors.budgetYmKey.count + BudgetTests.vectors.budgetParseYM.count
                + BudgetTests.vectors.budgetMonthLabel.count + BudgetTests.vectors.budgetMonthSwitch.count
                + BudgetTests.vectors.budgetYearAggregate.count + BudgetTests.vectors.budgetShare.count,
            40
        )
    }

    func testNetOf() {
        for v in BudgetTests.vectors.budgetNetOf {
            assertRelativelyClose(BudgetMath.netOf(v.income), v.expect, label: "netOf")
        }
    }

    func testTakeHome() {
        for v in BudgetTests.vectors.budgetTakeHome {
            assertRelativelyClose(BudgetMath.takeHome(of: v.month), v.expect, label: "takeHome")
        }
    }

    func testCatTotalsAndSel() {
        for v in BudgetTests.vectors.budgetCatTotals {
            assertRelativelyClose(BudgetMath.catTotal(v.cat), v.total, label: "catTotal")
            assertRelativelyClose(BudgetMath.catSel(v.cat), v.sel, label: "catSel")
        }
    }

    func testPlanned() {
        for v in BudgetTests.vectors.budgetPlanned {
            assertRelativelyClose(BudgetMath.planned(of: v.month), v.expect, label: "planned")
        }
    }

    func testImportRow() {
        for v in BudgetTests.vectors.budgetImportRow {
            let got = BudgetMath.importRow(name: v.name, qty: v.qty, amount: v.amount)
            XCTAssertEqual(got.n, v.expect.n, "importRow name \(v.name)")
            assertRelativelyClose(got.a, v.expect.a, label: "importRow amount \(v.name)")
            XCTAssertEqual(got.sel, v.expect.sel, "importRow sel \(v.name)")
        }
    }

    func testPerDayAndByToday() {
        for v in BudgetTests.vectors.budgetPerDay {
            if v.fn == "perDay" {
                assertRelativelyClose(BudgetMath.perDay(sel: v.sel, days: v.days), v.expect, label: "perDay")
            } else {
                assertRelativelyClose(BudgetMath.byToday(sel: v.sel, today: v.today ?? 0, days: v.days), v.expect, label: "byToday")
            }
        }
    }

    func testChartYMax() {
        for v in BudgetTests.vectors.budgetChartYMax {
            assertRelativelyClose(BudgetMath.chartYMax(sels: v.sels, goals: v.goals), v.expect, label: "chartYMax")
        }
    }

    func testMonthDays() {
        for v in BudgetTests.vectors.budgetMonthDays {
            XCTAssertEqual(BudgetMath.monthDays(v.key), v.expect, "monthDays \(v.key)")
        }
    }

    func testYmKey() {
        for v in BudgetTests.vectors.budgetYmKey {
            XCTAssertEqual(BudgetMath.ymKey(year: v.year, month: v.month), v.expect)
        }
    }

    func testParseYM() {
        for v in BudgetTests.vectors.budgetParseYM {
            let got = BudgetMath.parseYM(v.key)
            if let expect = v.expect {
                XCTAssertEqual(got?.year, expect.year, "parseYM \(v.key)")
                XCTAssertEqual(got?.month, expect.month, "parseYM \(v.key)")
            } else {
                XCTAssertNil(got, "parseYM \(v.key)")
            }
        }
    }

    func testMonthLabel() {
        for v in BudgetTests.vectors.budgetMonthLabel {
            XCTAssertEqual(BudgetMath.monthLabel(v.key), v.expect)
        }
    }

    func testMonthForSwitch() {
        for v in BudgetTests.vectors.budgetMonthSwitch {
            let result = BudgetMath.monthForSwitch(db: v.db, to: v.target)
            XCTAssertEqual(result.month, v.resultMonth, "monthForSwitch \(v.scenario)")
            XCTAssertEqual(result.copiedFrom, v.copiedFrom, "monthForSwitch copiedFrom \(v.scenario)")
        }
    }

    func testYearAggregate() {
        for v in BudgetTests.vectors.budgetYearAggregate {
            let got = BudgetMath.yearAggregate(db: v.db, year: v.year)
            XCTAssertEqual(got.count, v.expect.count, "yearAggregate count")
            for (g, e) in zip(got, v.expect) {
                XCTAssertEqual(g.key, e.key, "yearAggregate key")
                XCTAssertEqual(g.has, e.has, "yearAggregate has \(g.key)")
                assertRelativelyClose(g.planned, e.planned, label: "yearAggregate planned \(g.key)")
                assertRelativelyClose(g.takeHome, e.takeHome, label: "yearAggregate takeHome \(g.key)")
            }
        }
    }

    func testBudgetShareRoundTrip() {
        for v in BudgetTests.vectors.budgetShare {
            let parsed = BudgetShare.parse(v.fixtureText)
            XCTAssertNotNil(parsed, "BudgetShare.parse fixture \(v.cur)")
            XCTAssertEqual(parsed, v.expectDb, "BudgetShare.parse decoded db \(v.cur)")

            let dbForExport = BudgetDB(v: 2, cur: v.cur, months: [v.cur: v.month])
            let exported = BudgetShare.export(db: dbForExport)
            let reparsed = BudgetShare.parse(exported)
            XCTAssertNotNil(reparsed, "Swift export round trip \(v.cur)")
            XCTAssertEqual(reparsed?.cur, v.cur, "Swift export round trip cur \(v.cur)")
            XCTAssertEqual(reparsed?.months[v.cur], v.month, "Swift export round trip month \(v.cur)")
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
