import XCTest
@testable import SummitCore

final class XLSXTests: XCTestCase {

    // MARK: - Little-endian byte readers (test-side ZIP inspection)

    private func u16(_ b: [UInt8], _ i: Int) -> Int {
        Int(b[i]) | (Int(b[i + 1]) << 8)
    }

    private func u32(_ b: [UInt8], _ i: Int) -> Int {
        Int(b[i]) | (Int(b[i + 1]) << 8) | (Int(b[i + 2]) << 16) | (Int(b[i + 3]) << 24)
    }

    /// Walk STORED local file headers, returning (name, raw payload) per entry.
    private func readEntries(_ b: [UInt8]) -> [(name: String, payload: [UInt8])] {
        var out: [(name: String, payload: [UInt8])] = []
        var pos = 0
        while pos + 30 <= b.count, b[pos] == 0x50, b[pos + 1] == 0x4B, b[pos + 2] == 0x03, b[pos + 3] == 0x04 {
            let comp = u32(b, pos + 18)
            let nameLen = u16(b, pos + 26)
            let extraLen = u16(b, pos + 28)
            let nameStart = pos + 30
            let name = String(bytes: b[nameStart..<nameStart + nameLen], encoding: .utf8) ?? ""
            let dataStart = nameStart + nameLen + extraLen
            let payload = Array(b[dataStart..<dataStart + comp])
            out.append((name, payload))
            pos = dataStart + comp
        }
        return out
    }

    // MARK: - CRC-32 known-answer

    func testCRC32KnownAnswer() {
        XCTAssertEqual(XLSXZip.crc32(Data("123456789".utf8)), 0xCBF4_3926)
        XCTAssertEqual(XLSXZip.crc32(Data([])), 0)
    }

    // MARK: - ZIP structure (hand-walked 2-entry example)

    // entries ("a","A"), ("bb","BB"):
    //   local a  : header 31 + data 1 = 32 bytes at offset 0
    //   local bb : header 32 + data 2 = 34 bytes at offset 32   (total local = 66)
    //   central a 47 + central bb 48  = 95                       (cdOffset = 66)
    //   EOCD 22                        → total 183, EOCD at 161
    func testZipStructureHandExample() {
        let data = XLSXZip.zipArchive(entries: [
            (name: "a", data: Data("A".utf8)),
            (name: "bb", data: Data("BB".utf8))
        ])
        let b = [UInt8](data)

        XCTAssertEqual(b.count, 183, "total archive size")

        // Local file header magic (PK\03\04) at 0 and at 32
        XCTAssertEqual(Array(b[0..<4]), [0x50, 0x4B, 0x03, 0x04])
        XCTAssertEqual(Array(b[32..<36]), [0x50, 0x4B, 0x03, 0x04])

        // First entry stored sizes: compressed (offset 18) and uncompressed (22) both == 1
        XCTAssertEqual(u32(b, 18), 1)
        XCTAssertEqual(u32(b, 22), 1)

        // Central directory (PK\01\02) begins at 66
        XCTAssertEqual(Array(b[66..<70]), [0x50, 0x4B, 0x01, 0x02])

        // EOCD (PK\05\06) at tail (161)
        XCTAssertEqual(Array(b[161..<165]), [0x50, 0x4B, 0x05, 0x06])
        XCTAssertEqual(u16(b, 161 + 10), 2, "EOCD total records")
        XCTAssertEqual(u32(b, 161 + 12), 95, "EOCD central directory size")
        XCTAssertEqual(u32(b, 161 + 16), 66, "EOCD central directory offset")

        // Reader round-trips names + payloads
        let entries = readEntries(b)
        XCTAssertEqual(entries.map { $0.name }, ["a", "bb"])
        XCTAssertEqual(entries[0].payload, Array("A".utf8))
        XCTAssertEqual(entries[1].payload, Array("BB".utf8))
    }

    // MARK: - Workbook smoke test

    func testWorkbookStructureAndEscaping() {
        // Fixture: single income, one category whose name and item contain
        // characters that MUST be XML-escaped.
        let cat = BudgetCategory(n: "Toys & Games", open: true, goal: 500, items: [
            BudgetRow(n: "Board <game>", a: 30, sel: false)
        ])
        let month = BudgetMonth(
            inc2On: false,
            inc: [
                BudgetIncome(label: "Paycheck", gross: 4000, tax: 20, ret: 5, oth: 0),
                BudgetIncome(label: "Income 2", gross: 0, tax: 0, ret: 0, oth: 0)
            ],
            cats: [cat]
        )
        let db = BudgetDB(v: 2, cur: "2026-07", months: ["2026-07": month])

        let data = BudgetXLSX.workbook(db: db)
        let b = [UInt8](data)

        // Valid ZIP shell: local header magic at 0, EOCD (last 22 bytes) says 5 parts.
        XCTAssertEqual(Array(b[0..<4]), [0x50, 0x4B, 0x03, 0x04])
        XCTAssertEqual(u16(b, b.count - 22 + 10), 5, "workbook should hold 5 parts")

        let entries = readEntries(b)
        XCTAssertEqual(entries.count, 5)
        XCTAssertTrue(entries.contains { $0.name == "[Content_Types].xml" })
        XCTAssertTrue(entries.contains { $0.name == "xl/workbook.xml" })

        guard let sheet = entries.first(where: { $0.name == "xl/worksheets/sheet1.xml" }) else {
            XCTFail("sheet1.xml entry not found")
            return
        }
        let xml = String(bytes: sheet.payload, encoding: .utf8) ?? ""

        // Escaping: & < > ' all rendered as entities, no raw specials survive.
        XCTAssertTrue(xml.contains("Toys &amp; Games"), "ampersand escaped")
        XCTAssertTrue(xml.contains("Board &lt;game&gt;"), "angle brackets escaped")
        XCTAssertTrue(xml.contains("Summit&apos;s Budget"), "apostrophe escaped")
        XCTAssertFalse(xml.contains("Toys & Games"), "no raw ampersand in text")

        // Content: title month, inline strings, numeric cells all present.
        XCTAssertTrue(xml.contains("July 2026"))
        XCTAssertTrue(xml.contains("t=\"inlineStr\""))
        XCTAssertTrue(xml.contains("t=\"n\""))
        XCTAssertTrue(xml.contains("<v>30</v>"), "item amount cell")
        XCTAssertTrue(xml.contains("<v>3000</v>"), "take-home 4000*(1-.25)=3000")
    }
}
