import Foundation

public enum RecipeParse {
    private static let unicodeFrac: [String: Double] = [
        "\u{00bd}": 0.5,
        "\u{2153}": 1.0 / 3.0,
        "\u{2154}": 2.0 / 3.0,
        "\u{00bc}": 0.25,
        "\u{00be}": 0.75,
        "\u{215b}": 0.125,
        "\u{215c}": 0.375,
        "\u{215d}": 0.625,
        "\u{215e}": 0.875,
        "\u{2155}": 0.2,
        "\u{2156}": 0.4,
        "\u{2157}": 0.6,
        "\u{2158}": 0.8,
        "\u{2159}": 1.0 / 6.0,
        "\u{215a}": 5.0 / 6.0
    ]

    private static let unitAliases: [String: String] = [
        "tsp": "tsp", "teaspoon": "tsp", "teaspoons": "tsp",
        "tbsp": "tbsp", "tbs": "tbsp", "tablespoon": "tbsp", "tablespoons": "tbsp",
        "cup": "cup", "cups": "cup",
        "oz": "oz", "ounce": "oz", "ounces": "oz",
        "lb": "lb", "lbs": "lb", "pound": "lb", "pounds": "lb",
        "g": "g", "gram": "g", "grams": "g", "gr": "g",
        "kg": "kg",
        "ml": "mL", "milliliter": "mL", "milliliters": "mL",
        "l": "L", "liter": "L", "liters": "L", "litre": "L", "litres": "L",
        "pinch": "pinch",
        "clove": "clove", "cloves": "clove",
        "can": "can", "cans": "can",
        "stick": "stick", "sticks": "stick",
        "slice": "slice", "slices": "slice",
        "pkg": "pkg", "package": "pkg"
    ]

    private static let bulletChars: Set<Character> = [" ", "\t", "\n", "\r", "-", "*", "\u{2022}", "\u{2023}", "\u{25e6}"]

    private static let descriptorWords: Set<String> = [
        "large", "small", "medium", "extra",
        "fresh", "freshly",
        "chopped", "diced", "minced", "sliced", "cubed", "julienned",
        "grated", "shredded", "crushed", "crumbled",
        "boneless", "skinless",
        "ripe", "raw", "cooked",
        "peeled", "seeded", "trimmed",
        "packed", "drained", "rinsed",
        "softened", "melted", "beaten", "divided",
        "cold", "warm",
        "thinly", "finely", "coarsely", "roughly", "lightly"
    ]

    public static func parseLine(_ line: String) -> ParsedIngredient? {
        guard !line.isEmpty else {
            return nil
        }
        var trimmed = stripLeadingBullets(line)
        trimmed = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        let tokens = trimmed.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" || $0 == "\r" }).map { String($0) }
        var i = 0
        var qty = 0.0
        var hasQty = false
        while i < tokens.count {
            guard let v = tokenQtyValue(tokens[i]) else {
                break
            }
            qty += v
            hasQty = true
            i += 1
        }
        var unit: String? = nil
        if i < tokens.count {
            let raw = stripDotsCommas(tokens[i].lowercased())
            if raw == "fl" && i + 1 < tokens.count {
                let next = stripDotsCommas(tokens[i + 1].lowercased())
                if next == "oz" || next == "ounce" || next == "ounces" {
                    unit = "fl oz"
                    i += 2
                }
            }
            if unit == nil, let mapped = unitAliases[raw] {
                unit = mapped
                i += 1
            }
        }
        var name = tokens[i...].joined(separator: " ")
        name = stripLeadingOf(name)
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        name = stripTrailingCommaParen(name)
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        name = stripDescriptorWords(name)
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            name = trimmed
        }
        return ParsedIngredient(qty: hasQty ? qty : nil, unit: unit, name: name, raw: trimmed)
    }

    public static func scale(_ ing: ParsedIngredient, by factor: Double) -> ParsedIngredient {
        let newQty: Double?
        if let q = ing.qty {
            newQty = q * factor
        } else {
            newQty = nil
        }
        return ParsedIngredient(qty: newQty, unit: ing.unit, name: ing.name, raw: ing.raw)
    }

    public static func fmtQty(_ q: Double) -> String {
        if !q.isFinite {
            return ""
        }
        if q <= 0 {
            return "0"
        }
        let whole = (q + 1e-9).rounded(.down)
        let frac = q - whole
        let table: [(Double, String)] = [
            (0, ""), (0.125, "1/8"), (0.25, "1/4"), (1.0 / 3.0, "1/3"),
            (0.375, "3/8"), (0.5, "1/2"), (0.625, "5/8"), (2.0 / 3.0, "2/3"),
            (0.75, "3/4"), (0.875, "7/8"), (1, "")
        ]
        var best = table[0]
        var bestDiff = abs(frac - table[0].0)
        for entry in table {
            let d = abs(frac - entry.0)
            if d < bestDiff {
                bestDiff = d
                best = entry
            }
        }
        if bestDiff < 0.04 {
            if best.0 == 1 {
                return String(format: "%.0f", whole + 1)
            }
            if best.0 == 0 {
                return String(format: "%.0f", whole)
            }
            let wholePart = whole > 0 ? String(format: "%.0f", whole) + " " : ""
            return wholePart + best.1
        }
        let rounded = Formatters.jsRound(q * 100.0) / 100.0
        return Formatters.fmt(rounded)
    }

    public static func cleanUrl(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ""
        }
        var candidate = trimmed
        if !hasHttpScheme(candidate) {
            candidate = "https://" + candidate
        }
        guard var components = URLComponents(string: candidate) else {
            return raw
        }
        if let items = components.queryItems {
            let filtered = items.filter { !isTrackingParam($0.name) }
            components.queryItems = filtered.isEmpty ? nil : filtered
        }
        guard let url = components.url else {
            return raw
        }
        var result = url.absoluteString
        if result.hasSuffix("/") {
            result.removeLast()
        }
        return result
    }

    public static func jsonLDIngredients(html: String) -> [String] {
        var out: [String] = []
        let scripts = extractJsonLdScripts(html)
        for script in scripts {
            guard let data = script.data(using: .utf8) else {
                continue
            }
            guard let obj = try? JSONSerialization.jsonObject(with: data) else {
                continue
            }
            collectIngredients(obj, into: &out)
        }
        return out
    }

    private static func collectIngredients(_ node: Any, into out: inout [String]) {
        if let arr = node as? [Any] {
            for n in arr {
                collectIngredients(n, into: &out)
            }
            return
        }
        guard let dict = node as? [String: Any] else {
            return
        }
        if let list = dict["recipeIngredient"] as? [Any] {
            for item in list {
                if let s = item as? String {
                    let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !t.isEmpty {
                        out.append(t)
                    }
                }
            }
        }
        if let graph = dict["@graph"] {
            collectIngredients(graph, into: &out)
        }
        if let main = dict["mainEntity"] {
            collectIngredients(main, into: &out)
        }
    }

    private static func extractJsonLdScripts(_ html: String) -> [String] {
        var results: [String] = []
        let nsHtml = html as NSString
        let fullRange = NSRange(location: 0, length: nsHtml.length)
        let quote = "\""
        let squote = "'"
        let pattern = "<script[^>]*type=[" + quote + squote + "](?:application/ld\\+json)[" + quote + squote + "][^>]*>([\\s\\S]*?)</script\\s*>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return results
        }
        let matches = regex.matches(in: html, options: [], range: fullRange)
        for match in matches {
            guard match.numberOfRanges > 1 else {
                continue
            }
            let bodyRange = match.range(at: 1)
            guard bodyRange.location != NSNotFound else {
                continue
            }
            let body = nsHtml.substring(with: bodyRange).trimmingCharacters(in: .whitespacesAndNewlines)
            if !body.isEmpty {
                results.append(body)
            }
        }
        return results
    }

    private static func hasHttpScheme(_ s: String) -> Bool {
        let lower = s.lowercased()
        return lower.hasPrefix("http://") || lower.hasPrefix("https://")
    }

    private static func isTrackingParam(_ name: String) -> Bool {
        let lower = name.lowercased()
        if lower.hasPrefix("utm_") || lower.hasPrefix("mc_") {
            return true
        }
        let exact: Set<String> = ["fbclid", "gclid", "ref", "ref_src", "igshid", "si", "_ga", "yclid", "spm", "scm"]
        return exact.contains(lower)
    }

    private static func stripLeadingBullets(_ line: String) -> String {
        var chars = Substring(line)
        while let first = chars.first, bulletChars.contains(first) {
            chars.removeFirst()
        }
        return String(chars)
    }

    private static func stripDotsCommas(_ s: String) -> String {
        return s.filter { $0 != "." && $0 != "," }
    }

    private static func stripLeadingOf(_ s: String) -> String {
        if s.lowercased().hasPrefix("of ") {
            return String(s.dropFirst(3))
        }
        return s
    }

    private static func stripTrailingCommaParen(_ s: String) -> String {
        if let idx = s.firstIndex(where: { $0 == "," || $0 == "(" }) {
            return String(s[s.startIndex..<idx]).trimmingCharacters(in: .whitespaces)
        }
        return s
    }

    private static func stripDescriptorWords(_ s: String) -> String {
        let parts = s.split(whereSeparator: { $0 == " " || $0 == "\t" })
        let kept = parts.filter { part in
            let normalized = stripDotsCommas(String(part)).lowercased()
            return !descriptorWords.contains(normalized)
        }
        let result = kept.joined(separator: " ")
        return result.isEmpty ? s.trimmingCharacters(in: .whitespaces) : result
    }

    static func tokenQtyValue(_ t: String) -> Double? {
        if let f = unicodeFrac[t] {
            return f
        }
        if let combo = digitPlusFraction(t) {
            return combo
        }
        if let slash = plainFraction(t) {
            return slash
        }
        if let dec = plainDecimal(t) {
            return dec
        }
        if let range = rangeFirstValue(t) {
            return range
        }
        return nil
    }

    private static func digitPlusFraction(_ t: String) -> Double? {
        guard let last = t.last, let fracValue = unicodeFrac[String(last)] else {
            return nil
        }
        let digitsPart = String(t.dropLast())
        if digitsPart.isEmpty {
            return nil
        }
        guard digitsPart.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            return nil
        }
        guard let whole = Int(digitsPart) else {
            return nil
        }
        return Double(whole) + fracValue
    }

    private static func plainFraction(_ t: String) -> Double? {
        let parts = t.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2 else {
            return nil
        }
        let numStr = String(parts[0])
        let denStr = String(parts[1])
        guard !numStr.isEmpty, !denStr.isEmpty else {
            return nil
        }
        guard numStr.allSatisfy({ $0.isASCII && $0.isNumber }), denStr.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            return nil
        }
        guard let num = Double(numStr), let den = Double(denStr), den != 0 else {
            return nil
        }
        return num / den
    }

    private static func plainDecimal(_ t: String) -> Double? {
        guard isDecimalNumberToken(t) else {
            return nil
        }
        return Double(t)
    }

    private static func isDecimalNumberToken(_ t: String) -> Bool {
        if t.isEmpty {
            return false
        }
        let chars = Array(t)
        var idx = 0
        var sawDigitBeforeDot = false
        while idx < chars.count && chars[idx].isASCII && chars[idx].isNumber {
            sawDigitBeforeDot = true
            idx += 1
        }
        var sawDot = false
        if idx < chars.count && chars[idx] == "." {
            sawDot = true
            idx += 1
        }
        var sawDigitAfterDot = false
        while idx < chars.count && chars[idx].isASCII && chars[idx].isNumber {
            sawDigitAfterDot = true
            idx += 1
        }
        if idx != chars.count {
            return false
        }
        if sawDot {
            return sawDigitAfterDot
        }
        return sawDigitBeforeDot
    }

    private static func rangeFirstValue(_ t: String) -> Double? {
        let dashes: Set<Character> = ["-", "\u{2013}", "\u{2014}"]
        guard let dashIndex = t.firstIndex(where: { dashes.contains($0) }) else {
            return nil
        }
        let left = String(t[t.startIndex..<dashIndex])
        let right = String(t[t.index(after: dashIndex)...])
        guard isDecimalNumberToken(left), isDecimalNumberToken(right) else {
            return nil
        }
        return Double(left)
    }
}
