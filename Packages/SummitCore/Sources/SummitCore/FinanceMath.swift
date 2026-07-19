import Foundation

public enum FinanceMath {
    public static func futureValue(principal: Double, monthly: Double, annualRatePct: Double, years: Double) -> Double {
        let i = annualRatePct / 100.0 / 12.0
        let n = years * 12.0
        if i == 0 {
            return principal + monthly * n
        }
        return principal * pow(1 + i, n) + monthly * ((pow(1 + i, n) - 1) / i)
    }

    public static func contributions(principal: Double, monthly: Double, years: Double) -> Double {
        let n = years * 12.0
        return principal + monthly * n
    }

    public static func loanPayment(principal: Double, annualRatePct: Double, years: Double) -> Double {
        let p = principal
        let i = annualRatePct / 100.0 / 12.0
        let n = years * 12.0
        if i == 0 {
            return p / n
        }
        return (p * i) / (1 - pow(1 + i, -n))
    }

    public static func savingsGoalPayment(target: Double, principal: Double, annualRatePct: Double, years: Double) -> Double {
        let start = principal
        let i = annualRatePct / 100.0 / 12.0
        let n = years * 12.0
        let grow = pow(1 + i, n)
        let fvFactor = i == 0 ? n : (grow - 1) / i
        return (target - start * grow) / fvFactor
    }

    public static func realRate(nominalPct: Double, inflationPct: Double) -> Double {
        let nom = nominalPct / 100.0
        let inf = inflationPct / 100.0
        return ((1 + nom) / (1 + inf) - 1) * 100.0
    }

    public static func employerMatch(salary: Double, contribPct: Double, matchPct: Double, matchLimitPct: Double) -> Double {
        let c = contribPct
        let cap = matchLimitPct
        let rate = matchPct / 100.0
        return (salary * min(c, cap)) / 100.0 * rate
    }

    public static func ruleOf72(ratePct: Double) -> Double {
        return 72.0 / ratePct
    }

    public static func tip(bill: Double, tipPct: Double, people: Int) -> (tip: Double, total: Double, perPerson: Double) {
        let n = people == 0 ? 1.0 : Double(people)
        let t = (bill * tipPct) / 100.0
        let total = bill + t
        return (round2(t), round2(total), round2(total / n))
    }

    public static func percentOf(_ pct: Double, of value: Double) -> Double {
        return (value * pct) / 100.0
    }

    public static func percentChange(from a: Double, to b: Double) -> Double {
        return ((b - a) / a) * 100.0
    }

    static let jsEpsilon: Double = 2.220446049250313e-16

    static func round2(_ n: Double) -> Double {
        return Formatters.jsRound((n + jsEpsilon) * 100.0) / 100.0
    }

    // MARK: - Property appreciation (real estate / land)

    /// Compound annual appreciation of a property value. `netYieldPct` optionally
    /// layers rental income minus carrying costs as an additive annual rate
    /// (positive = income adds to growth; negative = costs drag). Raw land is
    /// usually appreciation-only (netYield 0 or slightly negative for taxes).
    public static func appreciatedValue(currentValue: Double, annualRatePct: Double,
                                        years: Double, netYieldPct: Double = 0) -> Double {
        let r = (annualRatePct + netYieldPct) / 100.0
        return currentValue * pow(1 + r, years)
    }

    /// Year-by-year appreciated value, index 0 = today — for the live Tools chart
    /// that redraws as she types. Clamped to a sane horizon.
    public static func appreciationSeries(currentValue: Double, annualRatePct: Double,
                                          years: Int, netYieldPct: Double = 0) -> [Double] {
        let r = (annualRatePct + netYieldPct) / 100.0
        let n = max(0, min(years, 200))
        return (0...n).map { currentValue * pow(1 + r, Double($0)) }
    }

    // MARK: - Baby / long-horizon (reuses the Grow model, sampled per year)

    /// Yearly sample points of futureValue() — a lump sum plus monthly
    /// contributions, compounding monthly. Index 0 = today.
    public static func futureValueSeries(principal: Double, monthly: Double,
                                         annualRatePct: Double, years: Int) -> [Double] {
        let n = max(0, min(years, 100))
        return (0...n).map {
            futureValue(principal: principal, monthly: monthly, annualRatePct: annualRatePct, years: Double($0))
        }
    }

    // MARK: - Trump Account (OBBBA 2025, IRC §530A)

    /// The one-time federal seed: $1,000 for a child born 2025–2028 (a pilot tied
    /// to those birth years). Children born outside the window get no seed.
    public static func trumpSeed(birthYear: Int) -> Double {
        (2025...2028).contains(birthYear) ? 1000 : 0
    }

    public struct TrumpYear: Equatable, Sendable {
        public let age: Int
        public let balance: Double
        public init(age: Int, balance: Double) { self.age = age; self.balance = balance }
    }

    /// Year-by-year Trump Account balance, annual compounding, contributions
    /// added at year-END and ONLY during the growth period (age < 18 — after 18
    /// the account converts to a traditional IRA and this projector stops
    /// contributing). `startBalance` should already include the seed. The net
    /// return is the assumed return minus the fund expense ratio.
    /// Contributions are clamped non-negative here as a defense-in-depth backstop;
    /// the annual/employer/aggregate caps are enforced at the input boundary.
    public static func trumpSeries(startBalance: Double, annualContribution: Double,
                                   currentAge: Int, targetAge: Int,
                                   returnPct: Double, expenseRatioPct: Double) -> [TrumpYear] {
        let net = (returnPct - expenseRatioPct) / 100.0
        let contribution = max(0, annualContribution)
        let start = max(0, min(currentAge, targetAge))
        let end = max(start, min(targetAge, 100))
        var balance = max(0, startBalance)
        var out: [TrumpYear] = [TrumpYear(age: start, balance: balance)]
        var age = start
        while age < end {
            balance *= (1 + net)
            if age < 18 { balance += contribution }
            age += 1
            out.append(TrumpYear(age: age, balance: balance))
        }
        return out
    }

    // MARK: - Whole life (simplified, NON-actuarial ballpark — see disclaimer)

    public struct WholeLifeYear: Equatable, Sendable {
        public let year: Int
        public let cashValue: Double            // projected, non-guaranteed
        public let guaranteedCashValue: Double  // the honest lower line
        public let deathBenefit: Double
        public init(year: Int, cashValue: Double, guaranteedCashValue: Double, deathBenefit: Double) {
            self.year = year
            self.cashValue = cashValue
            self.guaranteedCashValue = guaranteedCashValue
            self.deathBenefit = deathBenefit
        }
    }

    /// A deliberately simplified whole-life projection — a ballpark, NOT a policy
    /// illustration. The premium-efficiency factor `e` crudely models the fact
    /// that early premiums pay mortality + expenses before reaching cash value
    /// (so this OVERSTATES early cash value if e is set high — hence the
    /// mandatory guaranteed line + disclaimer). Dividends (rate × prior cash
    /// value) buy paid-up additions that raise the death benefit. The guaranteed
    /// line runs the same recurrence at a low floor rate; it is a conservative
    /// placeholder, not pulled from any specific contract.
    public static func wholeLifeSeries(annualPremium: Double, yearsPaying: Int,
                                       projectionYears: Int, ratePct: Double,
                                       initialDeathBenefit: Double, efficiencyPct: Double,
                                       guaranteedRatePct: Double = 2.0) -> [WholeLifeYear] {
        let r = ratePct / 100.0
        let rg = guaranteedRatePct / 100.0
        let e = max(0, min(efficiencyPct, 100)) / 100.0
        let payYears = max(0, yearsPaying)
        let years = max(0, min(projectionYears, 100))
        let premium = max(0, annualPremium)
        var cv = 0.0, cvg = 0.0
        var db = max(0, initialDeathBenefit)
        var out: [WholeLifeYear] = [WholeLifeYear(year: 0, cashValue: 0, guaranteedCashValue: 0, deathBenefit: db)]
        var year = 0
        while year < years {
            let pay = (year < payYears) ? premium : 0   // pay in policy years 1…N (0-indexed here)
            let divBase = cv                             // dividend on the prior year's cash value
            cv = (cv + pay * e) * (1 + r)
            cvg = (cvg + pay * e) * (1 + rg)
            let div = r * divBase
            db = max(max(0, initialDeathBenefit), db + div)
            year += 1
            out.append(WholeLifeYear(year: year, cashValue: cv, guaranteedCashValue: cvg, deathBenefit: db))
        }
        return out
    }
}
