import Foundation

public struct BudgetRow: Codable, Equatable {
    public var n: String
    public var a: Double
    public var sel: Bool

    public init(n: String, a: Double, sel: Bool) {
        self.n = n
        self.a = a
        self.sel = sel
    }
}

public struct BudgetIncome: Codable, Equatable {
    public var label: String
    public var gross: Double
    public var tax: Double
    public var ret: Double
    public var oth: Double

    public init(label: String, gross: Double, tax: Double, ret: Double, oth: Double) {
        self.label = label
        self.gross = gross
        self.tax = tax
        self.ret = ret
        self.oth = oth
    }
}

public struct BudgetCategory: Equatable {
    public var n: String
    public var open: Bool
    public var goal: Double?
    public var items: [BudgetRow]

    public init(n: String, open: Bool, goal: Double?, items: [BudgetRow]) {
        self.n = n
        self.open = open
        self.goal = goal
        self.items = items
    }
}

extension BudgetCategory: Codable {
    enum CodingKeys: String, CodingKey {
        case n, open, goal, items
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        n = try c.decode(String.self, forKey: .n)
        open = try c.decode(Bool.self, forKey: .open)
        goal = try c.decodeIfPresent(Double.self, forKey: .goal)
        items = try c.decode([BudgetRow].self, forKey: .items)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(n, forKey: .n)
        try c.encode(open, forKey: .open)
        if let goal {
            try c.encode(goal, forKey: .goal)
        } else {
            try c.encodeNil(forKey: .goal)
        }
        try c.encode(items, forKey: .items)
    }
}

public struct BudgetMonth: Codable, Equatable {
    public var inc2On: Bool
    public var inc: [BudgetIncome]
    public var cats: [BudgetCategory]

    public init(inc2On: Bool, inc: [BudgetIncome], cats: [BudgetCategory]) {
        self.inc2On = inc2On
        self.inc = inc
        self.cats = cats
    }
}

public struct BudgetDB: Codable, Equatable {
    public var v: Int
    public var cur: String
    public var months: [String: BudgetMonth]

    public init(v: Int, cur: String, months: [String: BudgetMonth]) {
        self.v = v
        self.cur = cur
        self.months = months
    }
}

public struct BudgetPresetItem {
    public let name: String
    public let amount: Double

    public init(name: String, amount: Double) {
        self.name = name
        self.amount = amount
    }
}

public struct BudgetPreset {
    public let n: String
    public let items: [BudgetPresetItem]

    public init(n: String, items: [BudgetPresetItem]) {
        self.n = n
        self.items = items
    }
}

public struct BudgetYearEntry: Equatable {
    public let key: String
    public let has: Bool
    public let planned: Double
    public let takeHome: Double

    public init(key: String, has: Bool, planned: Double, takeHome: Double) {
        self.key = key
        self.has = has
        self.planned = planned
        self.takeHome = takeHome
    }
}

public enum BudgetDefaults {
    public static func month() -> BudgetMonth {
        return BudgetMonth(
            inc2On: true,
            inc: [
                BudgetIncome(label: "Income 1", gross: 4200, tax: 18, ret: 5, oth: 2),
                BudgetIncome(label: "Income 2", gross: 3600, tax: 16, ret: 5, oth: 0)
            ],
            cats: [
                BudgetCategory(n: "Housing", open: true, goal: nil, items: [
                    BudgetRow(n: "Rent or mortgage", a: 1400, sel: false),
                    BudgetRow(n: "Renters or home insurance", a: 25, sel: false)
                ]),
                BudgetCategory(n: "Utilities", open: false, goal: nil, items: [
                    BudgetRow(n: "Electric", a: 110, sel: false),
                    BudgetRow(n: "Gas heat", a: 60, sel: false),
                    BudgetRow(n: "Water and sewer", a: 45, sel: false),
                    BudgetRow(n: "Internet", a: 70, sel: false),
                    BudgetRow(n: "Cell phones", a: 90, sel: false)
                ]),
                BudgetCategory(n: "Groceries & Household", open: false, goal: nil, items: [
                    BudgetRow(n: "Groceries", a: 550, sel: false),
                    BudgetRow(n: "Household goods", a: 60, sel: false)
                ]),
                BudgetCategory(n: "Transportation", open: false, goal: nil, items: [
                    BudgetRow(n: "Car payment", a: 320, sel: false),
                    BudgetRow(n: "Fuel", a: 160, sel: false),
                    BudgetRow(n: "Car insurance", a: 130, sel: false),
                    BudgetRow(n: "Maintenance", a: 40, sel: false)
                ]),
                BudgetCategory(n: "Health", open: false, goal: nil, items: [
                    BudgetRow(n: "Health insurance", a: 180, sel: false),
                    BudgetRow(n: "Prescriptions", a: 20, sel: false),
                    BudgetRow(n: "Gym", a: 25, sel: false)
                ]),
                BudgetCategory(n: "Debt Payoff", open: false, goal: nil, items: [
                    BudgetRow(n: "Student loans", a: 220, sel: false),
                    BudgetRow(n: "Credit card", a: 100, sel: false)
                ]),
                BudgetCategory(n: "Savings & Future", open: false, goal: nil, items: [
                    BudgetRow(n: "Emergency fund", a: 200, sel: false),
                    BudgetRow(n: "Baby fund", a: 150, sel: false),
                    BudgetRow(n: "House down payment", a: 200, sel: false)
                ]),
                BudgetCategory(n: "Kids & Family", open: false, goal: nil, items: [
                    BudgetRow(n: "Diapers and baby gear", a: 80, sel: false),
                    BudgetRow(n: "Childcare", a: 0, sel: false)
                ]),
                BudgetCategory(n: "Lifestyle", open: false, goal: nil, items: [
                    BudgetRow(n: "Dining out", a: 180, sel: false),
                    BudgetRow(n: "Date nights", a: 80, sel: false),
                    BudgetRow(n: "Streaming and subscriptions", a: 35, sel: false),
                    BudgetRow(n: "Clothing", a: 60, sel: false)
                ]),
                BudgetCategory(n: "Giving", open: false, goal: nil, items: [
                    BudgetRow(n: "Church or charity", a: 150, sel: false),
                    BudgetRow(n: "Gifts", a: 40, sel: false)
                ]),
                BudgetCategory(n: "Everything Else", open: false, goal: nil, items: [
                    BudgetRow(n: "Buffer for surprises", a: 75, sel: false)
                ])
            ]
        )
    }

    public static let presets: [BudgetPreset] = [
        BudgetPreset(n: "Pets", items: [
            BudgetPresetItem(name: "Food & litter", amount: 60),
            BudgetPresetItem(name: "Vet fund", amount: 40),
            BudgetPresetItem(name: "Grooming", amount: 25)
        ]),
        BudgetPreset(n: "Travel & Vacations", items: [
            BudgetPresetItem(name: "Vacation fund", amount: 150),
            BudgetPresetItem(name: "Weekend trips", amount: 60)
        ]),
        BudgetPreset(n: "Baby Prep", items: [
            BudgetPresetItem(name: "Nursery fund", amount: 120),
            BudgetPresetItem(name: "Hospital bills fund", amount: 100),
            BudgetPresetItem(name: "Baby clothes", amount: 40)
        ]),
        BudgetPreset(n: "College Fund", items: [
            BudgetPresetItem(name: "529 contribution", amount: 100)
        ]),
        BudgetPreset(n: "Home Maintenance", items: [
            BudgetPresetItem(name: "Repairs fund", amount: 100),
            BudgetPresetItem(name: "Lawn & garden", amount: 30)
        ]),
        BudgetPreset(n: "Personal Care", items: [
            BudgetPresetItem(name: "Haircuts", amount: 45),
            BudgetPresetItem(name: "Toiletries", amount: 35),
            BudgetPresetItem(name: "Self-care", amount: 40)
        ]),
        BudgetPreset(n: "Medical & HSA", items: [
            BudgetPresetItem(name: "HSA contribution", amount: 150),
            BudgetPresetItem(name: "Copays", amount: 30)
        ]),
        BudgetPreset(n: "Insurance Extras", items: [
            BudgetPresetItem(name: "Life insurance", amount: 45),
            BudgetPresetItem(name: "Disability insurance", amount: 30)
        ]),
        BudgetPreset(n: "Education", items: [
            BudgetPresetItem(name: "Tuition or courses", amount: 100),
            BudgetPresetItem(name: "Books & supplies", amount: 25)
        ]),
        BudgetPreset(n: "Christmas & Holidays", items: [
            BudgetPresetItem(name: "Gift fund", amount: 80),
            BudgetPresetItem(name: "Decorations", amount: 15)
        ]),
        BudgetPreset(n: "Charity & Support", items: [
            BudgetPresetItem(name: "Family support", amount: 50),
            BudgetPresetItem(name: "Sponsorships", amount: 40)
        ]),
        BudgetPreset(n: "Blank category", items: [
            BudgetPresetItem(name: "", amount: 0)
        ])
    ]

    public static let colors: [String] = [
        "#E2417F", "#8E1560", "#B04266", "#2E9E5B", "#C22E85", "#D9822B",
        "#7A4FBF", "#CE3E63", "#421527", "#E56A87", "#8F5F7E", "#F06FA7"
    ]

    public static let monthNames: [String] = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
}
