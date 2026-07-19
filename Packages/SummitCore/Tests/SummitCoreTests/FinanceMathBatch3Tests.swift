import XCTest
@testable import SummitCore

final class FinanceMathBatch3Tests: XCTestCase {
    private func close(_ a: Double, _ b: Double, _ tol: Double = 1e-6) {
        XCTAssertEqual(a, b, accuracy: tol)
    }

    // MARK: appreciation

    func testAppreciatedValueCompoundsAnnually() {
        // $300k at 4.5% for 10 years = 300000 * 1.045^10
        close(FinanceMath.appreciatedValue(currentValue: 300_000, annualRatePct: 4.5, years: 10),
              300_000 * pow(1.045, 10))
    }

    func testAppreciationNetYieldIsAdditive() {
        // appreciation 4% + net yield 3% == 7% compounded
        close(FinanceMath.appreciatedValue(currentValue: 100_000, annualRatePct: 4, years: 5, netYieldPct: 3),
              100_000 * pow(1.07, 5))
    }

    func testAppreciationSeriesEndpoints() {
        let s = FinanceMath.appreciationSeries(currentValue: 250_000, annualRatePct: 4.5, years: 20)
        XCTAssertEqual(s.count, 21)             // index 0..20
        close(s[0], 250_000)                    // today
        close(s[20], 250_000 * pow(1.045, 20))  // horizon
    }

    // MARK: baby / future-value series

    func testFutureValueSeriesMatchesFutureValue() {
        let s = FinanceMath.futureValueSeries(principal: 1000, monthly: 50, annualRatePct: 7, years: 18)
        XCTAssertEqual(s.count, 19)
        close(s[0], 1000)
        close(s[18], FinanceMath.futureValue(principal: 1000, monthly: 50, annualRatePct: 7, years: 18))
    }

    func testBabyExampleMagnitude() {
        // $50/mo for 18 yr at 7% ~ $21.5k; +$1000 seed ~ $25k (research worked example)
        let noSeed = FinanceMath.futureValue(principal: 0, monthly: 50, annualRatePct: 7, years: 18)
        XCTAssertGreaterThan(noSeed, 20_000)
        XCTAssertLessThan(noSeed, 23_000)
        let withSeed = FinanceMath.futureValue(principal: 1000, monthly: 50, annualRatePct: 7, years: 18)
        XCTAssertGreaterThan(withSeed, 24_000)
        XCTAssertLessThan(withSeed, 26_000)
    }

    // MARK: trump account

    func testTrumpSeedWindow() {
        XCTAssertEqual(FinanceMath.trumpSeed(birthYear: 2024), 0)
        XCTAssertEqual(FinanceMath.trumpSeed(birthYear: 2025), 1000)
        XCTAssertEqual(FinanceMath.trumpSeed(birthYear: 2028), 1000)
        XCTAssertEqual(FinanceMath.trumpSeed(birthYear: 2029), 0)
    }

    func testTrumpSeriesStopsContributingAt18() {
        // $1000 seed, $5000/yr, birth to 30, 7% net-of-nothing. Contributions
        // only 0..17 (18 deposits), then pure growth 18..30.
        let s = FinanceMath.trumpSeries(startBalance: 1000, annualContribution: 5000,
                                        currentAge: 0, targetAge: 30, returnPct: 7, expenseRatioPct: 0)
        XCTAssertEqual(s.count, 31)
        XCTAssertEqual(s.first?.age, 0)
        XCTAssertEqual(s.last?.age, 30)
        // Reference: manual recurrence with contributions only while age < 18.
        var bal = 1000.0
        for age in 0..<30 {
            bal *= 1.07
            if age < 18 { bal += 5000 }
        }
        close(s.last!.balance, bal, 1e-4)
    }

    func testTrumpExpenseRatioReducesReturn() {
        let hi = FinanceMath.trumpSeries(startBalance: 1000, annualContribution: 0,
                                         currentAge: 0, targetAge: 18, returnPct: 10, expenseRatioPct: 0).last!.balance
        let lo = FinanceMath.trumpSeries(startBalance: 1000, annualContribution: 0,
                                         currentAge: 0, targetAge: 18, returnPct: 10, expenseRatioPct: 0.10).last!.balance
        XCTAssertLessThan(lo, hi)
        close(hi, 1000 * pow(1.10, 18), 1e-6)
        // net = 10% − 0.10% expense = 9.90% → factor 1.099
        close(lo, 1000 * pow(1.099, 18), 1e-6)
    }

    // MARK: whole life

    func testWholeLifeGuaranteedBelowProjected() {
        let s = FinanceMath.wholeLifeSeries(annualPremium: 5000, yearsPaying: 20, projectionYears: 30,
                                            ratePct: 5.75, initialDeathBenefit: 250_000, efficiencyPct: 85)
        XCTAssertEqual(s.count, 31)
        // The projected (non-guaranteed) line must sit at or above the guaranteed one.
        for y in s { XCTAssertGreaterThanOrEqual(y.cashValue, y.guaranteedCashValue) }
        // Death benefit never drops below the starting face amount.
        for y in s { XCTAssertGreaterThanOrEqual(y.deathBenefit, 250_000) }
        // Dividends raise the death benefit above the initial over time.
        XCTAssertGreaterThan(s.last!.deathBenefit, 250_000)
    }

    func testWholeLifePremiumsStopAtYearsPaying() {
        // Paying 10 years but projecting 20 — cash value should still grow after
        // premiums stop (paid-up growth), just without new premium going in.
        let s = FinanceMath.wholeLifeSeries(annualPremium: 6000, yearsPaying: 10, projectionYears: 20,
                                            ratePct: 5.75, initialDeathBenefit: 100_000, efficiencyPct: 85)
        XCTAssertGreaterThan(s[20].cashValue, s[10].cashValue)
    }

    func testWholeLifeZeroPremiumIsZeroCash() {
        let s = FinanceMath.wholeLifeSeries(annualPremium: 0, yearsPaying: 10, projectionYears: 10,
                                            ratePct: 5.75, initialDeathBenefit: 50_000, efficiencyPct: 85)
        close(s.last!.cashValue, 0)
        close(s.last!.deathBenefit, 50_000)   // no dividends, stays at face
    }
}
