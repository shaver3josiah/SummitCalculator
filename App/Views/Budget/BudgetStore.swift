import Foundation
import SummitCore

@Observable
final class BudgetStore {
    var db: BudgetDB
    var view: String = "month"
    var yearSel: Int

    // Global "give first" prefs — NOT per-month budget data, so they live in their
    // own file (.stewardship) rather than inside BudgetMonth. Absent file → defaults.
    var stewardship: StewardshipSettings {
        didSet { JSONStore.shared.set(.stewardship, stewardship) }
    }

    // Persisted YYYY-MM keys are Gregorian by schema contract (BudgetMath.monthDays
    // pins .gregorian), so never derive them from the user's Calendar.current.
    private static let gregorian = Calendar(identifier: .gregorian)

    init() {
        let initialDB: BudgetDB
        if let saved = JSONStore.shared.get(.budget2, as: BudgetDB.self), !saved.months.isEmpty, saved.months[saved.cur] != nil {
            initialDB = saved
        } else {
            let key = BudgetMath.ymKey(year: Self.gregorian.component(.year, from: Date()), month: Self.gregorian.component(.month, from: Date()))
            initialDB = BudgetDB(v: 2, cur: key, months: [key: BudgetDefaults.month()])
        }
        db = initialDB
        yearSel = BudgetMath.parseYM(initialDB.cur)?.year ?? Self.gregorian.component(.year, from: Date())
        stewardship = JSONStore.shared.get(.stewardship, as: StewardshipSettings.self) ?? StewardshipSettings()
    }

    var month: BudgetMonth {
        get { db.months[db.cur] ?? BudgetDefaults.month() }
        set { db.months[db.cur] = newValue }
    }

    // MARK: - Give-first amounts (pure derived off `month` gross + `stewardship`).

    /// Gross this month = income 1 + income 2 (only when the second is on).
    /// Guards the inc array so a malformed/short month can't crash.
    var grossIncome: Double {
        let m = month
        let first = m.inc.indices.contains(0) ? m.inc[0].gross : 0
        let second = (m.inc2On && m.inc.indices.contains(1)) ? m.inc[1].gross : 0
        return first + second
    }
    var titheAmount: Double { grossIncome * stewardship.tithePct / 100 }
    var feastAmount: Double { grossIncome * stewardship.feastPct / 100 }
    var poorAmount: Double { grossIncome * stewardship.poorPct / 100 }
    var innovationAmount: Double { stewardship.innovationFlat }
    var givenFirstTotal: Double { titheAmount + feastAmount + poorAmount + innovationAmount }

    var monthLabel: String { BudgetMath.monthLabel(db.cur) }
    var takeHome: Double { BudgetMath.takeHome(of: month) }
    var planned: Double { BudgetMath.planned(of: month) }
    var leftOver: Double { takeHome - planned }
    // BudgetMath.monthDays returns 0 on a corrupt key; clamp so chart domains and
    // per-day division never see 0.
    var monthDays: Int { max(1, BudgetMath.monthDays(db.cur)) }
    var isCurrentRealMonth: Bool {
        db.cur == BudgetMath.ymKey(year: Self.gregorian.component(.year, from: Date()), month: Self.gregorian.component(.month, from: Date()))
    }
    var todayDay: Int? {
        guard isCurrentRealMonth else { return nil }
        return Self.gregorian.component(.day, from: Date())
    }

    func switchMonth(to key: String) {
        let (newMonth, copiedFrom) = BudgetMath.monthForSwitch(db: db, to: key)
        let alreadyExisted = db.months[key] != nil
        if !alreadyExisted {
            db.months[key] = newMonth
            let label = BudgetMath.monthLabel(key)
            if let priorKey = copiedFrom {
                let priorLabel = BudgetMath.monthLabel(priorKey)
                ToastCenter.shared.show(title: "New month", message: "\(label) started from \(priorLabel).")
            } else {
                ToastCenter.shared.show(title: "New month", message: "\(label) started from the starter template.")
            }
        }
        db.cur = key
        yearSel = BudgetMath.parseYM(key)?.year ?? yearSel
        save()
    }

    func shiftMonth(by delta: Int) {
        guard let (year, monthNum) = BudgetMath.parseYM(db.cur) else { return }
        var totalMonths = year * 12 + (monthNum - 1) + delta
        let newYear = totalMonths >= 0 ? totalMonths / 12 : -1 - (-totalMonths - 1) / 12
        totalMonths -= newYear * 12
        let newMonth = totalMonths + 1
        switchMonth(to: BudgetMath.ymKey(year: newYear, month: newMonth))
    }

    func shiftYear(by delta: Int) {
        yearSel += delta
    }

    func yearAggregate() -> [BudgetYearEntry] {
        BudgetMath.yearAggregate(db: db, year: yearSel)
    }

    func setIncome(_ index: Int, label: String? = nil, gross: Double? = nil, tax: Double? = nil, ret: Double? = nil, oth: Double? = nil) {
        var m = month
        guard m.inc.indices.contains(index) else { return }
        if let label { m.inc[index].label = label }
        if let gross { m.inc[index].gross = gross }
        if let tax { m.inc[index].tax = tax }
        if let ret { m.inc[index].ret = ret }
        if let oth { m.inc[index].oth = oth }
        month = m
        save()
    }

    func setInc2On(_ on: Bool) {
        var m = month
        m.inc2On = on
        month = m
        save()
    }

    func addCategory(preset: BudgetPreset) {
        var m = month
        let name = preset.n == "Blank category" ? "New category" : preset.n
        let items = preset.items.map { BudgetRow(n: $0.name, a: $0.amount, sel: false) }
        m.cats.append(BudgetCategory(n: name, open: true, goal: nil, items: items))
        month = m
        save()
        ToastCenter.shared.show(title: "Category added", message: "\(preset.n) is in this month\u{2019}s budget.")
    }

    func addCategory(fromList title: String, rows: [(name: String, qty: Double, amount: Double)]) {
        var m = month
        let items = rows.compactMap { BudgetMath.importRow(name: $0.name, qty: $0.qty, amount: $0.amount) }
        let cleanTitle = title.replacingOccurrences(of: " (open now)", with: "")
        m.cats.append(BudgetCategory(n: cleanTitle, open: true, goal: nil, items: items))
        month = m
        save()
        ToastCenter.shared.show(title: "List imported", message: "\(title) is now a budget category.")
    }

    func renameCategory(_ index: Int, name: String) {
        var m = month
        guard m.cats.indices.contains(index) else { return }
        m.cats[index].n = name
        month = m
        save()
    }

    func toggleCategoryOpen(_ index: Int) {
        var m = month
        guard m.cats.indices.contains(index) else { return }
        m.cats[index].open.toggle()
        month = m
        save()
    }

    func reorderCategory(_ index: Int, direction: Int) {
        var m = month
        let j = index + direction
        guard m.cats.indices.contains(index), m.cats.indices.contains(j) else { return }
        m.cats.swapAt(index, j)
        month = m
        save()
    }

    func deleteCategory(_ index: Int) {
        var m = month
        guard m.cats.indices.contains(index), m.cats[index].items.isEmpty else { return }
        m.cats.remove(at: index)
        month = m
        save()
    }

    func setCategorySelectAll(_ index: Int, on: Bool) {
        var m = month
        guard m.cats.indices.contains(index) else { return }
        for i in m.cats[index].items.indices {
            m.cats[index].items[i].sel = on
        }
        month = m
        save()
    }

    func addRow(to categoryIndex: Int) {
        var m = month
        guard m.cats.indices.contains(categoryIndex) else { return }
        m.cats[categoryIndex].items.append(BudgetRow(n: "", a: 0, sel: false))
        m.cats[categoryIndex].open = true
        month = m
        save()
    }

    func updateRow(category categoryIndex: Int, row rowIndex: Int, name: String? = nil, amount: Double? = nil, sel: Bool? = nil) {
        var m = month
        guard m.cats.indices.contains(categoryIndex), m.cats[categoryIndex].items.indices.contains(rowIndex) else { return }
        if let name { m.cats[categoryIndex].items[rowIndex].n = name }
        if let amount { m.cats[categoryIndex].items[rowIndex].a = amount }
        if let sel { m.cats[categoryIndex].items[rowIndex].sel = sel }
        month = m
        save()
    }

    func reorderRow(category categoryIndex: Int, row rowIndex: Int, direction: Int) {
        var m = month
        guard m.cats.indices.contains(categoryIndex) else { return }
        let j = rowIndex + direction
        guard m.cats[categoryIndex].items.indices.contains(rowIndex), m.cats[categoryIndex].items.indices.contains(j) else { return }
        m.cats[categoryIndex].items.swapAt(rowIndex, j)
        month = m
        save()
    }

    func deleteRow(category categoryIndex: Int, row rowIndex: Int) {
        var m = month
        guard m.cats.indices.contains(categoryIndex), m.cats[categoryIndex].items.indices.contains(rowIndex) else { return }
        m.cats[categoryIndex].items.remove(at: rowIndex)
        month = m
        save()
    }

    func setGoal(_ index: Int, value: Double?) {
        var m = month
        guard m.cats.indices.contains(index) else { return }
        m.cats[index].goal = value
        month = m
        save()
    }

    func importList(category categoryIndex: Int, title: String, rows: [(name: String, qty: Double, amount: Double)]) {
        var m = month
        guard m.cats.indices.contains(categoryIndex) else { return }
        let items = rows.compactMap { BudgetMath.importRow(name: $0.name, qty: $0.qty, amount: $0.amount) }
        m.cats[categoryIndex].items.append(contentsOf: items)
        m.cats[categoryIndex].open = true
        month = m
        save()
        ToastCenter.shared.show(title: "List imported", message: "\(items.count) items added to \(m.cats[categoryIndex].n).")
    }

    func activeCategories() -> [(index: Int, category: BudgetCategory, sel: Double)] {
        var out: [(Int, BudgetCategory, Double)] = []
        for (i, c) in month.cats.enumerated() {
            let s = BudgetMath.catSel(c)
            if s > 0 { out.append((i, c, s)) }
        }
        return out
    }

    func exportText() -> String {
        BudgetShare.export(db: db)
    }

    /// Writes the current budget as an .xlsx to a temp file, returns its URL (nil on failure).
    func exportXLSXURL() -> URL? {
        let safe = String(db.cur.map { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" ? $0 : "-" })
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Summit-Budget-\(safe).xlsx")
        do {
            try BudgetXLSX.workbook(db: db).write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    @discardableResult
    func importShared(_ text: String) -> Bool {
        guard let parsed = BudgetShare.parse(text), let m = parsed.months[parsed.cur] else { return false }
        db.months[parsed.cur] = m
        db.cur = parsed.cur
        yearSel = BudgetMath.parseYM(parsed.cur)?.year ?? yearSel
        view = "month"
        save()
        ToastCenter.shared.show(title: "Budget imported", message: "Loaded into \(parsed.cur).")
        return true
    }

    private func save() {
        JSONStore.shared.set(.budget2, db)
    }
}
