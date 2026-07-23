import XCTest
@testable import SummitCore

final class ListParseTests: XCTestCase {
    func testPlainLinesEachBecomeAnItem() {
        // No markers anywhere -> every non-empty line is an item.
        let items = ListParse.listItems(from: "milk\neggs\nflour")
        XCTAssertEqual(items, ["milk", "eggs", "flour"])
    }

    func testDashAndBulletMarkersStripped() {
        let items = ListParse.listItems(from: "- milk\n• eggs\n* flour")
        XCTAssertEqual(items, ["milk", "eggs", "flour"])
    }

    func testMarkedLinesWinOverUnmarkedProse() {
        // A heading/aside above the bullets must not arrive as a grocery item.
        let text = "Shopping for Sunday\n- milk\n- eggs"
        XCTAssertEqual(ListParse.listItems(from: text), ["milk", "eggs"])
    }

    func testNumberMarkersStripped() {
        XCTAssertEqual(ListParse.listItems(from: "1. milk\n2) eggs"), ["milk", "eggs"])
    }

    func testDecimalMeasurementIsNotANumberMarker() {
        // "1.5 cups flour" is a measurement, not a numbered bullet — and because
        // it must NOT count as marked, the whole plain list survives.
        let text = "1.5 cups flour\n2 eggs\n0.5 tsp salt"
        XCTAssertEqual(ListParse.listItems(from: text),
                       ["1.5 cups flour", "2 eggs", "0.5 tsp salt"])
    }

    func testBareMarkerLineDropped() {
        // A line that is only "-" must not become an empty row, and must not
        // wipe the real lines around it.
        let items = ListParse.listItems(from: "- milk\n-\n- eggs")
        XCTAssertEqual(items, ["milk", "eggs"])
    }

    func testBareMarkerAmongPlainLinesDoesNotEraseThem() {
        let items = ListParse.listItems(from: "milk\n-\neggs")
        XCTAssertEqual(items, ["milk", "eggs"])
    }

    func testCRLFLineEndings() {
        let items = ListParse.listItems(from: "milk\r\neggs\r\nflour")
        XCTAssertEqual(items, ["milk", "eggs", "flour"])
    }

    func testBlankLinesDropped() {
        let items = ListParse.listItems(from: "milk\n\n\neggs")
        XCTAssertEqual(items, ["milk", "eggs"])
    }

    func testCapAt200() {
        let text = (1...500).map { "item \($0)" }.joined(separator: "\n")
        XCTAssertEqual(ListParse.listItems(from: text).count, 200)
    }

    func testEmptyInputIsEmpty() {
        XCTAssertTrue(ListParse.listItems(from: "").isEmpty)
        XCTAssertTrue(ListParse.listItems(from: "   \n  \n").isEmpty)
    }

    func testStripMarkerReturnsNilForNoMarker() {
        XCTAssertNil(ListParse.stripMarker("just some words"))
        XCTAssertNil(ListParse.stripMarker("1.5 cups"))
    }

    func testStripMarkerReturnsEmptyForBareMarker() {
        XCTAssertEqual(ListParse.stripMarker("-"), "")
    }
}
