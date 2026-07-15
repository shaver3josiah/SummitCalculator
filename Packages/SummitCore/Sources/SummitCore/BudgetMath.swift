import Foundation

public enum BudgetMath {
    public static func jsRound(_ x: Double) -> Double {
        if x.isNaN {
            return x
        }
        let f = (x + 0.5).rounded(.down)
        if f == 0 && (x < 0 || x.sign == .minus) {
            return -0.0
        }
        return f
    }

    public static func netOf(_ i: BudgetIncome) -> Double {
        let g = i.gross
        let p = i.tax + i.ret + i.oth
        return max(0, g * (1 - min(100, p) / 100))
    }

    public static func takeHome(of m: BudgetMonth) -> Double {
        var t = m.inc.first.map(netOf) ?? 0
        if m.inc2On, m.inc.count > 1 {
            t += netOf(m.inc[1])
        }
        return t
    }

    public static func catTotal(_ c: BudgetCategory) -> Double {
        var t = 0.0
        for it in c.items {
            t += it.a
        }
        return t
    }

    public static func catSel(_ c: BudgetCategory) -> Double {
        var t = 0.0
        for it in c.items where it.sel {
            t += it.a
        }
        return t
    }

    public static func planned(of m: BudgetMonth) -> Double {
        var t = 0.0
        for c in m.cats {
            t += catTotal(c)
        }
        return t
    }

    public static func importRow(name: String, qty: Double?, amount: Double) -> BudgetRow {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let q = qty ?? 1
        let a = jsRound(q * amount * 100) / 100
        return BudgetRow(n: String(n.prefix(60)), a: a, sel: false)
    }

    public static func ymKey(year: Int, month: Int) -> String {
        return "\(year)-\(String(format: "%02d", month))"
    }

    public static func parseYM(_ key: String) -> (year: Int, month: Int)? {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2, let y = Int(parts[0]), let m = Int(parts[1]) else {
            return nil
        }
        return (year: y, month: m)
    }

    public static func monthDays(_ ymKey: String) -> Int {
        guard let parsed = parseYM(ymKey) else {
            return 0
        }
        var comps = DateComponents()
        comps.year = parsed.year
        comps.month = parsed.month
        comps.day = 1
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        guard let date = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 0
        }
        return range.count
    }

    public static func monthLabel(_ ymKey: String) -> String {
        guard let parsed = parseYM(ymKey), (1...12).contains(parsed.month) else {
            return ymKey
        }
        let name = BudgetDefaults.monthNames[parsed.month - 1]
        return "\(name) \(parsed.year)"
    }

    public static func perDay(sel: Double, days: Int) -> Double {
        return sel / Double(days)
    }

    public static func byToday(sel: Double, today: Int, days: Int) -> Double {
        return sel * Double(today) / Double(days)
    }

    public static func chartYMax(sels: [Double], goals: [Double?]) -> Double {
        var ymax = 1.0
        for idx in 0..<sels.count {
            let g = idx < goals.count ? (goals[idx] ?? 0) : 0
            ymax = max(ymax, sels[idx], g)
        }
        if sels.count > 1 {
            let allTot = sels.reduce(0, +)
            ymax = max(ymax, allTot)
        }
        return ymax * 1.08
    }

    public static func monthForSwitch(db: BudgetDB, to key: String) -> (month: BudgetMonth, copiedFrom: String?) {
        if let existing = db.months[key] {
            return (existing, nil)
        }
        let ks = db.months.keys.sorted()
        var prior: String? = nil
        for k in ks.reversed() where k < key {
            prior = k
            break
        }
        if prior == nil, let last = ks.last {
            prior = last
        }
        var src: BudgetMonth
        if let prior, let source = db.months[prior] {
            src = source
        } else {
            src = BudgetDefaults.month()
        }
        for i in 0..<src.cats.count {
            for j in 0..<src.cats[i].items.count {
                src.cats[i].items[j].sel = false
            }
            src.cats[i].goal = src.cats[i].goal
        }
        return (src, prior)
    }

    public static func yearAggregate(db: BudgetDB, year: Int) -> [BudgetYearEntry] {
        var out: [BudgetYearEntry] = []
        for m in 1...12 {
            let k = ymKey(year: year, month: m)
            let mo = db.months[k]
            let pl = mo.map { planned(of: $0) } ?? 0
            let th = mo.map { takeHome(of: $0) } ?? 0
            out.append(BudgetYearEntry(key: k, has: mo != nil, planned: pl, takeHome: th))
        }
        return out
    }
}
