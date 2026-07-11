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
}
