import Foundation

/// Turns a page of typed lines into list items — the "make it a list" button in
/// the Notes page. Pure and in SummitCore so it can be unit-tested without a view.
///
/// The rule: if ANY line carries a bullet/number marker, only the marked lines
/// become items (the user is writing prose with a list inside it); if NOTHING is
/// marked, every non-empty line is an item (they just typed a plain list).
public enum ListParse {
    private static let bulletMarkers = ["- ", "* ", "• ", "· ", "– ", "— "]

    /// Strips a leading bullet or "1." / "2)" number marker. Returns nil when the
    /// line has no marker, and "" when the line is ONLY a marker.
    /// A number is a marker only when the separator is followed by a space or the
    /// end of the line — so "1. milk" is an item but "1.5 cups flour" is a
    /// measurement, not a bullet (getting that wrong both corrupts the quantity
    /// and, because it counts as "marked", can discard every unmarked line).
    public static func stripMarker(_ line: String) -> String? {
        for marker in bulletMarkers where line.hasPrefix(marker) {
            return String(line.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
        }
        if bulletMarkers.contains(where: { line == $0.trimmingCharacters(in: .whitespaces) }) {
            return ""
        }
        let digits = line.prefix { $0.isNumber }
        if !digits.isEmpty {
            let rest = line.dropFirst(digits.count)
            if let separator = rest.first, separator == "." || separator == ")" {
                let after = rest.dropFirst()
                guard after.isEmpty || after.first == " " else { return nil }   // "1.5" is not a bullet
                return String(after).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    /// Lines -> items. Splits on newlines (CRLF-safe), trims, drops empties, caps
    /// at 200. Never returns a bare-marker line as an item.
    public static func listItems(from text: String) -> [String] {
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Marked lines with content. A line that is ONLY a marker strips to "" and
        // is dropped here, so it can never win the "any marked?" test with junk.
        let marked = lines.compactMap { stripMarker($0) }.filter { !$0.isEmpty }
        // Fallback: no real markers anywhere -> every non-bare line is an item.
        let items = marked.isEmpty ? lines.filter { stripMarker($0) != "" } : marked
        return Array(items.prefix(200))
    }
}
