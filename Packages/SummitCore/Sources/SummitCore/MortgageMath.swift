import Foundation

/// Extra-mortgage-principal vs Roth-IRA decision engine.
///
/// Pure-Foundation port of the month-by-month simulator in
/// `mortgage-vs-roth/index.html` (`readInputs`, `payoffMonths`, `simulate`).
/// It runs two futures on identical dollars:
///   Plan A — the extra goes to principal (prepay, then invest the freed payment)
///   Plan B — the extra is invested; the loan follows its normal schedule
/// The verdict is `sign(return − effective mortgage rate)`; PMI and the optional
/// itemize/interest deduction are the tie-breakers.
public struct MortgageInputs {
    public var balance: Double        // remaining loan balance
    public var apr: Double            // annual rate, as a fraction (0.057 = 5.7%)
    public var itemize: Bool          // deduct mortgage interest?
    public var tax: Double            // marginal bracket, as a fraction (0.22)
    public var payment: Double        // monthly P&I payment
    public var home: Double           // home value today
    public var pmi: Double            // PMI per month
    public var extra: Double          // extra per month (same dollars, either path)
    public var roth0: Double          // current Roth balance (rides along in both)
    public var annualReturn: Double   // assumed return r, as a fraction (0.10)
    public var appreciation: Double   // home appreciation g/yr, as a fraction (0.045)
    public var horizonYears: Double

    /// Clamps mirror the HTML's `readInputs()`.
    public init(balance: Double, apr: Double, itemize: Bool, tax: Double,
                payment: Double, home: Double, pmi: Double, extra: Double,
                roth0: Double, annualReturn: Double, appreciation: Double,
                horizonYears: Double) {
        self.balance = max(0, balance)
        self.apr = max(0.0025, apr)
        self.itemize = itemize
        self.tax = max(0, tax)
        self.payment = max(0, payment)
        self.home = max(1, home)
        self.pmi = max(0, pmi)
        self.extra = max(0, extra)
        self.roth0 = max(0, roth0)
        self.annualReturn = max(0, annualReturn)
        self.appreciation = max(0, appreciation)
        self.horizonYears = max(1, horizonYears)
    }
}

/// One simulated month. `A` = prepay path, `B` = normal-schedule/invest path.
public struct MortgageRow {
    public let month: Int
    public let balanceA: Double
    public let balanceB: Double
    public let investedA: Double
    public let investedB: Double
    public let interestA: Double   // cumulative interest paid, path A
    public let interestB: Double   // cumulative interest paid, path B
    public let homeValue: Double
    /// Net position = investments − remaining debt. The house cancels (identical
    /// in both futures), so this is the whole comparison.
    public var netA: Double { investedA - balanceA }
    public var netB: Double { investedB - balanceB }
}

public struct MortgageResult {
    public let rows: [MortgageRow]
    public let months: Int
    public let payoffA: Int?       // month prepay path retires the loan
    public let payoffB: Int?       // month the normal schedule retires the loan
    public let interestA: Double
    public let interestB: Double
    public let pmiOn: Bool
    public let pmiEndA: Int?
    public let pmiEndB: Int?
    public let pmiPaidA: Double
    public let pmiPaidB: Double
    public let rothFV: Double       // existing Roth grown over the window
    public var last: MortgageRow { rows[rows.count - 1] }
}

public enum MortgageMath {
    /// Months to retire a loan paying exactly `M`/mo at monthly rate `i` on `B`.
    /// `nil` when the payment can't cover interest (the JS `Infinity`).
    public static func payoffMonths(balance B: Double, monthlyRate i: Double, payment M: Double) -> Int? {
        if M <= B * i { return nil }
        if i == 0 { return Int(ceil(B / M)) }
        return Int(ceil(-log(1 - i * B / M) / log(1 + i)))
    }

    public static func simulate(_ p: MortgageInputs) -> MortgageResult {
        let i = p.apr / 12.0
        let rm = p.annualReturn / 12.0
        let months = max(1, min(480, Int((p.horizonYears * 12.0).rounded())))
        let tr = p.itemize ? p.tax : 0.0                 // itemizers get interest × bracket back
        let gm = pow(1 + p.appreciation, 1.0 / 12.0) - 1 // monthly home appreciation
        var hv = p.home
        let pmiOn = p.pmi > 0 && p.balance > 0.8 * p.home

        var bA = p.balance, bB = p.balance
        var invA = 0.0, invB = 0.0, intA = 0.0, intB = 0.0
        var payoffA: Int? = nil, payoffB: Int? = nil
        var pmiEndA: Int? = nil, pmiEndB: Int? = nil
        var pmiPaidA = 0.0, pmiPaidB = 0.0

        var rows: [MortgageRow] = []
        rows.reserveCapacity(months)

        for m in 1...months {
            hv *= (1 + gm)
            let pmiCut = 0.8 * hv                         // LTV against the CURRENT value
            invA *= (1 + rm); invB *= (1 + rm)

            // Path A — extra to principal
            if bA > 0 {
                let int = bA * i; intA += int
                if tr != 0 { invA += int * tr }
                let prin = p.payment + p.extra - int
                if prin >= bA { invA += (prin - bA); bA = 0; if payoffA == nil { payoffA = m } }
                else { bA -= prin }
            } else { invA += p.payment + p.extra }

            // Path B — extra invested
            if bB > 0 {
                let int = bB * i; intB += int
                if tr != 0 { invB += int * tr }
                let prin = p.payment - int
                if prin >= bB { invB += p.extra + (prin - bB); bB = 0; if payoffB == nil { payoffB = m } }
                else { bB -= prin; invB += p.extra }
            } else { invB += p.payment + p.extra }

            // PMI: an expense while LTV > 80%; once dropped, that cash is invested too
            if pmiOn {
                if bA > pmiCut { pmiPaidA += p.pmi } else { if pmiEndA == nil { pmiEndA = m }; invA += p.pmi }
                if bB > pmiCut { pmiPaidB += p.pmi } else { if pmiEndB == nil { pmiEndB = m }; invB += p.pmi }
            }

            rows.append(MortgageRow(month: m, balanceA: bA, balanceB: bB,
                                    investedA: invA, investedB: invB,
                                    interestA: intA, interestB: intB, homeValue: hv))
        }

        let rothFV = p.roth0 * pow(1 + rm, Double(months))
        return MortgageResult(rows: rows, months: months,
                              payoffA: payoffA, payoffB: payoffB,
                              interestA: intA, interestB: intB,
                              pmiOn: pmiOn, pmiEndA: pmiEndA, pmiEndB: pmiEndB,
                              pmiPaidA: pmiPaidA, pmiPaidB: pmiPaidB, rothFV: rothFV)
    }
}
