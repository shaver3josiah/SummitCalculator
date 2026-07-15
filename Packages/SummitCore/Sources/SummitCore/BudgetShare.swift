import Foundation

public enum BudgetShare {
    public static func export(db: BudgetDB) -> String {
        let m = db.months[db.cur] ?? BudgetDefaults.month()
        let label = BudgetMath.monthLabel(db.cur)
        let th = BudgetMath.takeHome(of: m)
        let pl = BudgetMath.planned(of: m)
        var out = "Budget · \(label)\n"
        out += "Take-home \(Formatters.money(th)) · planned \(Formatters.money(pl)) · left \(Formatters.money(th - pl))\n\nINCOME\n"
        for (ix, i) in m.inc.enumerated() {
            if ix == 1 && !m.inc2On {
                continue
            }
            let label2 = i.label.isEmpty ? "Income \(ix + 1)" : i.label
            let othPart = i.oth != 0 ? ", other \(numText(i.oth))%" : ""
            out += "• \(label2): $\(numText(i.gross)) gross (tax \(numText(i.tax))%, retire \(numText(i.ret))%\(othPart)) → \(Formatters.money(BudgetMath.netOf(i)))\n"
        }
        for c in m.cats {
            let ct = BudgetMath.catTotal(c)
            out += "\n\(c.n.uppercased()) - \(Formatters.money(ct))\n"
            for it in c.items where !it.n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                out += "• \(it.n) $\(numText(it.a))\n"
            }
            if let goal = c.goal {
                out += "(goal \(Formatters.money(goal)))\n"
            }
        }
        let payload = SharePayload(k: db.cur, m: m)
        if let b64 = encodePayload(payload) {
            out += "\n#summit-budget-v1 \(b64)"
        }
        return out
    }

    public static func parse(_ text: String) -> BudgetDB? {
        guard let range = text.range(of: "#summit-budget-v1\\s+([A-Za-z0-9+/=]+)", options: .regularExpression) else {
            return nil
        }
        let matched = String(text[range])
        guard let tokenRange = matched.range(of: "[A-Za-z0-9+/=]+$", options: .regularExpression) else {
            return nil
        }
        let token = String(matched[tokenRange])
        guard let payload = decodePayload(token) else {
            return nil
        }
        guard let ym = BudgetMath.parseYM(payload.k), (1...12).contains(ym.month),
              payload.m.inc.count >= 2, !payload.m.cats.isEmpty else {
            return nil
        }
        return BudgetDB(v: 2, cur: payload.k, months: [payload.k: payload.m])
    }

    private struct SharePayload: Codable {
        let k: String
        let m: BudgetMonth
    }

    private static func encodePayload(_ payload: SharePayload) -> String? {
        guard let data = try? JSONEncoder().encode(payload) else {
            return nil
        }
        return data.base64EncodedString()
    }

    private static func decodePayload(_ b64: String) -> SharePayload? {
        guard let data = Data(base64Encoded: b64) else {
            return nil
        }
        return try? JSONDecoder().decode(SharePayload.self, from: data)
    }

    private static func numText(_ n: Double) -> String {
        if n == n.rounded() && abs(n) < 1e15 {
            return String(format: "%.0f", n)
        }
        return Formatters.plain(n)
    }
}
