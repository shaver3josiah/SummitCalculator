import Foundation

public enum Formatters {
    public static func round8(_ n: Double) -> Double {
        if n.isNaN || n.isInfinite {
            return n
        }
        return jsRound(n * 1e8) / 1e8
    }

    public static func fmt(_ n: Double) -> String {
        if n.isNaN || n.isInfinite {
            return "Error"
        }
        if n == 0 {
            return "0"
        }
        let absN = abs(n)
        if absN >= 1e15 || (absN < 1e-6 && absN > 0) {
            return toExponential4(n)
        }
        let r = round8(n)
        return fmtGrouped(r)
    }

    public static func plain(_ n: Double) -> String {
        return numberToString(round8(n))
    }

    public static func money(_ n: Double) -> String {
        let safe = (n.isNaN || n.isInfinite) ? 0.0 : n
        let neg = safe < 0 || (safe == 0 && safe.sign == .minus)
        let v = abs(safe)
        let scaled = v * 100.0
        let centsRounded = (scaled + 0.5).rounded(.down)
        var centsStr = String(format: "%.0f", centsRounded)
        while centsStr.count < 3 {
            centsStr = "0" + centsStr
        }
        let splitIndex = centsStr.index(centsStr.endIndex, offsetBy: -2)
        let intPart = String(centsStr[centsStr.startIndex..<splitIndex])
        let fracPart = String(centsStr[splitIndex...])
        let grouped = groupInteger(intPart)
        let sign = neg ? "-" : ""
        return "$" + sign + grouped + "." + fracPart
    }

    public static func usd(_ n: Double) -> String {
        let safe = (n.isNaN || n.isInfinite) ? 0.0 : n
        let r = jsRound(safe)
        let neg = r < 0 || (r == 0 && r.sign == .minus)
        let v = abs(r)
        let intPart = String(format: "%.0f", v)
        let grouped = groupInteger(intPart)
        let sign = neg ? "-" : ""
        return "$" + sign + grouped
    }

    static func jsRound(_ x: Double) -> Double {
        if x.isNaN {
            return x
        }
        let f = (x + 0.5).rounded(.down)
        if f == 0 && (x < 0 || x.sign == .minus) {
            return -0.0
        }
        return f
    }

    static func groupInteger(_ digits: String) -> String {
        let chars = Array(digits)
        let n = chars.count
        var out = ""
        for (i, ch) in chars.enumerated() {
            let posFromRight = n - i
            out.append(ch)
            if posFromRight > 1 && posFromRight % 3 == 1 {
                out.append(",")
            }
        }
        return out
    }

    static func toExponential4(_ value: Double) -> String {
        if value == 0 {
            let neg = value.sign == .minus
            return (neg ? "-" : "") + "0.0000e+0"
        }
        let neg = value < 0
        let v = abs(value)
        let s = String(format: "%.4e", v)
        let parts = s.split(separator: "e")
        let mantissa = String(parts[0])
        let expString = String(parts[1])
        let expValue = Int(expString) ?? 0
        let expSign = expValue >= 0 ? "+" : "-"
        return (neg ? "-" : "") + mantissa + "e" + expSign + String(abs(expValue))
    }

    static func fmtGrouped(_ r: Double) -> String {
        let neg = r < 0
        let v = abs(r)
        let s = String(format: "%.8f", v)
        let parts = s.split(separator: ".", maxSplits: 1)
        let intPart = String(parts[0])
        var fracPart = parts.count > 1 ? String(parts[1]) : ""
        while fracPart.hasSuffix("0") {
            fracPart.removeLast()
        }
        let grouped = groupInteger(intPart)
        let out = grouped + (fracPart.isEmpty ? "" : "." + fracPart)
        return (neg ? "-" : "") + out
    }

    static func shortestDigitsAndExponent(_ value: Double) -> (digits: String, n: Int) {
        for precision in 0..<17 {
            let s = String(format: "%.\(precision)e", value)
            if let parsed = Double(s), parsed == value {
                return parseExponentialForm(s)
            }
        }
        let s = String(format: "%.16e", value)
        return parseExponentialForm(s)
    }

    static func parseExponentialForm(_ s: String) -> (digits: String, n: Int) {
        let parts = s.split(separator: "e")
        let mantissa = String(parts[0])
        let expValue = Int(parts[1]) ?? 0
        var digits = mantissa.replacingOccurrences(of: ".", with: "")
        digits = digits.replacingOccurrences(of: "-", with: "")
        while digits.count > 1 && digits.hasSuffix("0") {
            digits.removeLast()
        }
        let n = expValue + 1
        return (digits, n)
    }

    static func numberToString(_ value: Double) -> String {
        if value.isNaN {
            return "NaN"
        }
        if value == 0 {
            return "0"
        }
        let neg = value < 0 || value.sign == .minus
        let v = abs(value)
        if v.isInfinite {
            return (neg ? "-Infinity" : "Infinity")
        }
        let (digits, n) = shortestDigitsAndExponent(v)
        let k = digits.count
        let sign = neg ? "-" : ""
        let chars = Array(digits)
        if k <= n && n <= 21 {
            return sign + digits + String(repeating: "0", count: n - k)
        }
        if n > 0 && n <= 21 {
            let head = String(chars[0..<n])
            let tail = String(chars[n...])
            return sign + head + "." + tail
        }
        if n > -6 && n <= 0 {
            return sign + "0." + String(repeating: "0", count: -n) + digits
        }
        let mant: String
        if k == 1 {
            mant = digits
        } else {
            mant = String(chars[0..<1]) + "." + String(chars[1...])
        }
        let e = n - 1
        let eSign = e >= 0 ? "+" : "-"
        return sign + mant + "e" + eSign + String(abs(e))
    }
}
