import Foundation

/// Turns a recipe into the two shareable forms a cook can send from the share
/// panel: a plain-text version tuned for SMS (numbered, highly legible) and a
/// self-contained "pretty page" HTML (parchment + summit marks) that opens
/// standalone in Safari from a text. Pure string-building, no SwiftUI — the App
/// layer only wires the results to ShareLink (mirroring how BudgetShare/XLSX split).
///
/// Recipe fields are freeform user/publisher text, so everything that lands in
/// markup is HTML-escaped here, and the source URL is scheme-checked before it's
/// ever turned into a link.
public enum RecipeShare {

    // MARK: - Plain text (SMS)

    /// A clean, numbered, highly legible plain-text recipe for texting. Ingredients
    /// are bulleted, steps are numbered, blank rows are dropped, and multi-line
    /// steps are flattened to one line so they read tidily in a message bubble.
    public static func text(name: String, serves: String, time: String,
                            ingredients: [String], steps: [String],
                            notes: String, sourceUrl: String) -> String {
        var lines: [String] = []
        let title = trimmed(name).isEmpty ? "Recipe" : trimmed(name)
        lines.append(title)

        let meta = [trimmed(serves), trimmed(time)].filter { !$0.isEmpty }.joined(separator: "  •  ")
        if !meta.isEmpty { lines.append(meta) }

        let ing = cleanLines(ingredients)
        if !ing.isEmpty {
            lines.append("")
            lines.append("INGREDIENTS")
            lines.append(contentsOf: ing.map { "•  \($0)" })
        }

        let st = cleanLines(steps).map(flatten)
        if !st.isEmpty {
            lines.append("")
            lines.append("METHOD")
            for (i, s) in st.enumerated() { lines.append("\(i + 1). \(s)") }
        }

        let note = trimmed(notes)
        if !note.isEmpty {
            lines.append("")
            lines.append("NOTES")
            lines.append(note)
        }

        if let host = host(of: sourceUrl) {
            lines.append("")
            lines.append("From \(host)")
        }

        lines.append("")
        lines.append("— logged at base camp • Summit Kitchen ▲")
        return lines.joined(separator: "\n")
    }

    // MARK: - Escaping / helpers (shared with the HTML builder)

    /// HTML-escape text before it goes into element content OR a double-quoted
    /// attribute. Ampersand first, then the rest.
    public static func htmlEscape(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count + 8)
        for ch in s {
            switch ch {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&#39;"
            default: out.append(ch)
            }
        }
        return out
    }

    static func trimmed(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Trim each row and drop the blank ones (the same filter `saveRecipe` applies).
    static func cleanLines(_ arr: [String]) -> [String] {
        arr.map(trimmed).filter { !$0.isEmpty }
    }

    /// Collapse any internal whitespace/newlines to single spaces — a step typed on
    /// several lines should read as one tidy sentence in a text message.
    static func flatten(_ s: String) -> String {
        s.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).joined(separator: " ")
    }

    /// Only http(s) URLs are honored — a `javascript:`/`data:` source (attacker or
    /// publisher controlled) never becomes a link or a displayed host.
    static func safeURL(_ s: String) -> String? {
        let t = trimmed(s)
        guard !t.isEmpty, let u = URL(string: t),
              let scheme = u.scheme?.lowercased(), scheme == "http" || scheme == "https"
        else { return nil }
        return t
    }

    static func host(of urlString: String) -> String? {
        guard let safe = safeURL(urlString), let u = URL(string: safe), let h = u.host else { return nil }
        return h.hasPrefix("www.") ? String(h.dropFirst(4)) : h
    }
}
