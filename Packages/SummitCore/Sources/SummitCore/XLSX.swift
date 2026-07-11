import Foundation

private let xmlDecl = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"

// Minimal, dependency-free .xlsx writer. Pure Foundation, cross-platform (no
// Compression/CryptoKit/UIKit) so it builds and tests on Linux.
//
// ZIP entries are STORED (compression method 0) — valid per PKZIP APPNOTE and
// accepted by Excel/Numbers/LibreOffice. We hand-roll CRC-32 and the local /
// central-directory / EOCD records. DOS date-time is a fixed constant
// (determinism over accuracy): 1980-01-01 00:00:00.

// MARK: - ZIP layer

enum XLSXZip {
    // CRC-32, standard polynomial 0xEDB88320, table-driven.
    static let crcTable: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1) == 1 ? (0xEDB8_8320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()

    static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            let idx = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ crcTable[idx]
        }
        return crc ^ 0xFFFF_FFFF
    }

    static func le16(_ v: UInt16) -> [UInt8] {
        [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF)]
    }

    static func le32(_ v: UInt32) -> [UInt8] {
        [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 24) & 0xFF)]
    }

    // Fixed DOS date/time (deterministic): 1980-01-01 00:00:00.
    // date bits: year-1980 (0) << 9 | month (1) << 5 | day (1) = 0x0021; time = 0.
    static let dosDate: UInt16 = 0x0021
    static let dosTime: UInt16 = 0x0000

    /// Build a STORED (uncompressed) ZIP archive from named entries.
    ///
    /// Worked example — two entries: ("a", "A"), ("bb", "BB"):
    ///   local header = 30 + nameLen + extra(0).
    ///   entry a: header 30+1 = 31, +data 1  → 32 bytes, local offset 0.
    ///   entry bb: header 30+2 = 32, +data 2 → 34 bytes, local offset 32.
    ///   total local = 66. central header = 46 + nameLen.
    ///   central a = 47, central bb = 48 → total central = 95, cdOffset = 66.
    ///   EOCD = 22. total file = 66 + 95 + 22 = 183, EOCD begins at 161.
    /// (XLSXTests walks these exact numbers.)
    static func zipArchive(entries: [(name: String, data: Data)]) -> Data {
        var local: [UInt8] = []
        var central: [UInt8] = []
        var offset: UInt32 = 0

        for entry in entries {
            let nameBytes = Array(entry.name.utf8)
            let crc = crc32(entry.data)
            let size = UInt32(entry.data.count)
            let localOffset = offset

            // Local file header (PK\03\04)
            var lh: [UInt8] = [0x50, 0x4B, 0x03, 0x04]
            lh += le16(20)                          // version needed
            lh += le16(0)                           // general-purpose flag
            lh += le16(0)                           // method: stored
            lh += le16(dosTime)
            lh += le16(dosDate)
            lh += le32(crc)
            lh += le32(size)                        // compressed size
            lh += le32(size)                        // uncompressed size
            lh += le16(UInt16(nameBytes.count))
            lh += le16(0)                           // extra field length
            lh += nameBytes
            local += lh
            local += Array(entry.data)
            offset += UInt32(lh.count) + size

            // Central directory header (PK\01\02)
            var ch: [UInt8] = [0x50, 0x4B, 0x01, 0x02]
            ch += le16(20)                          // version made by
            ch += le16(20)                          // version needed
            ch += le16(0)                           // flags
            ch += le16(0)                           // method
            ch += le16(dosTime)
            ch += le16(dosDate)
            ch += le32(crc)
            ch += le32(size)
            ch += le32(size)
            ch += le16(UInt16(nameBytes.count))
            ch += le16(0)                           // extra length
            ch += le16(0)                           // comment length
            ch += le16(0)                           // disk number start
            ch += le16(0)                           // internal attrs
            ch += le32(0)                           // external attrs
            ch += le32(localOffset)                 // offset of local header
            ch += nameBytes
            central += ch
        }

        let cdOffset = UInt32(local.count)
        let cdSize = UInt32(central.count)

        var out = local
        out += central

        // End of central directory record (PK\05\06)
        var eocd: [UInt8] = [0x50, 0x4B, 0x05, 0x06]
        eocd += le16(0)                             // this disk number
        eocd += le16(0)                             // disk with CD start
        eocd += le16(UInt16(entries.count))         // CD records on this disk
        eocd += le16(UInt16(entries.count))         // total CD records
        eocd += le32(cdSize)
        eocd += le32(cdOffset)
        eocd += le16(0)                             // comment length
        out += eocd

        return Data(out)
    }
}

// MARK: - Workbook layer

public enum BudgetXLSX {
    /// Single-sheet workbook for the current month (db.cur), inline strings only.
    public static func workbook(db: BudgetDB) -> Data {
        let m = db.months[db.cur] ?? BudgetDefaults.month()
        let label = BudgetMath.monthLabel(db.cur)

        var rows: [[Cell]] = []
        rows.append([.text("Summit's Budget \u{2014} \(label)")])
        rows.append([])                             // spacer

        rows.append([.text("Income"), .text("Gross"), .text("Tax %"), .text("Retire %"), .text("Other %"), .text("Take-home")])
        for (ix, i) in m.inc.enumerated() {
            if ix == 1 && !m.inc2On { continue }
            let name = i.label.isEmpty ? "Income \(ix + 1)" : i.label
            rows.append([.text(name), .num(i.gross), .num(i.tax), .num(i.ret), .num(i.oth), .num(BudgetMath.netOf(i))])
        }
        rows.append([])                             // spacer

        for c in m.cats {
            rows.append([.text(c.n), .num(BudgetMath.catTotal(c))])
            for it in c.items where !it.n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                rows.append([.text(it.n), .num(it.a)])
            }
            if let goal = c.goal {
                rows.append([.text("Goal"), .num(goal)])
            }
            rows.append([])                         // spacer between categories
        }

        let th = BudgetMath.takeHome(of: m)
        let pl = BudgetMath.planned(of: m)
        rows.append([.text("Take-home"), .num(th)])
        rows.append([.text("Planned"), .num(pl)])
        rows.append([.text("Remainder"), .num(th - pl)])

        let entries: [(name: String, data: Data)] = [
            ("[Content_Types].xml", Data(contentTypesXML.utf8)),
            ("_rels/.rels", Data(rootRelsXML.utf8)),
            ("xl/workbook.xml", Data(workbookXML.utf8)),
            ("xl/_rels/workbook.xml.rels", Data(workbookRelsXML.utf8)),
            ("xl/worksheets/sheet1.xml", Data(sheetXML(rows).utf8))
        ]
        return XLSXZip.zipArchive(entries: entries)
    }

    // MARK: Cells

    private enum Cell {
        case text(String)
        case num(Double)
    }

    private static func sheetXML(_ rows: [[Cell]]) -> String {
        var xml = xmlDecl
        xml += "<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\"><sheetData>"
        for (i, cells) in rows.enumerated() where !cells.isEmpty {
            let r = i + 1                            // blank rows leave a gap (valid)
            xml += "<row r=\"\(r)\">"
            for (ci, cell) in cells.enumerated() {
                let ref = "\(colRef(ci))\(r)"
                switch cell {
                case .text(let s):
                    xml += "<c r=\"\(ref)\" t=\"inlineStr\"><is><t xml:space=\"preserve\">\(esc(s))</t></is></c>"
                case .num(let v):
                    xml += "<c r=\"\(ref)\" t=\"n\"><v>\(numStr(v))</v></c>"
                }
            }
            xml += "</row>"
        }
        xml += "</sheetData></worksheet>"
        return xml
    }

    /// Bijective base-26 column reference (0 -> A, 25 -> Z, 26 -> AA).
    static func colRef(_ col: Int) -> String {
        var c = col
        var s = ""
        repeat {
            let rem = c % 26
            s = String(Character(UnicodeScalar(UInt8(65 + rem)))) + s
            c = c / 26 - 1
        } while c >= 0
        return s
    }

    static func esc(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&apos;"
            default: out.append(ch)
            }
        }
        return out
    }

    // Clean decimal for <v> (no trailing ".0", no scientific for budget values).
    private static func numStr(_ n: Double) -> String {
        n.isFinite ? Formatters.plain(n) : "0"
    }

    // MARK: Static package parts

    private static let contentTypesXML =
        xmlDecl +
        "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">" +
        "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>" +
        "<Default Extension=\"xml\" ContentType=\"application/xml\"/>" +
        "<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>" +
        "<Override PartName=\"/xl/worksheets/sheet1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>" +
        "</Types>"

    private static let rootRelsXML =
        xmlDecl +
        "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">" +
        "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/>" +
        "</Relationships>"

    private static let workbookXML =
        xmlDecl +
        "<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">" +
        "<sheets><sheet name=\"Budget\" sheetId=\"1\" r:id=\"rId1\"/></sheets>" +
        "</workbook>"

    private static let workbookRelsXML =
        xmlDecl +
        "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">" +
        "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/>" +
        "</Relationships>"
}
