import XCTest
@testable import SummitCore

final class MortgageMathTests: XCTestCase {
    /// The page's default scenario, with rates overridable per test.
    private func scenario(apr: Double, ret: Double, pmi: Double = 0, itemize: Bool = false) -> MortgageInputs {
        MortgageInputs(balance: 180_000, apr: apr, itemize: itemize, tax: 0.22,
                       payment: 1161, home: 200_000, pmi: pmi, extra: 306,
                       roth0: 17_500, annualReturn: ret, appreciation: 0.045,
                       horizonYears: 24)
    }

    func testPayoffMonthsMatchesHTML() {
        // $180k at 5.7% (i = 0.00475) paying $1161/mo → ~23.5 yrs.
        XCTAssertEqual(MortgageMath.payoffMonths(balance: 180_000, monthlyRate: 0.00475, payment: 1161), 282)
        // Zero-rate branch: pure division, rounded up.
        XCTAssertEqual(MortgageMath.payoffMonths(balance: 1200, monthlyRate: 0, payment: 100), 12)
        // Payment can't cover interest → never amortizes.
        XCTAssertNil(MortgageMath.payoffMonths(balance: 180_000, monthlyRate: 0.00475, payment: 855))
    }

    func testFirstMonthArithmetic() {
        let m1 = MortgageMath.simulate(scenario(apr: 0.057, ret: 0.10)).rows[0]
        // interest = 180000 × 0.00475 = 855
        XCTAssertEqual(m1.interestA, 855, accuracy: 1e-6)
        // Plan A principal = 1161 + 306 − 855 = 612 → balance 179,388
        XCTAssertEqual(m1.balanceA, 179_388, accuracy: 1e-6)
        // Plan B principal = 1161 − 855 = 306 → balance 179,694, and $306 invested
        XCTAssertEqual(m1.balanceB, 179_694, accuracy: 1e-6)
        XCTAssertEqual(m1.investedB, 306, accuracy: 1e-6)
        // Same outlay, no growth yet → both net positions equal
        XCTAssertEqual(m1.netA, m1.netB, accuracy: 1e-6)
    }

    func testEqualRatesTie() {
        // return == mortgage rate, no PMI, no itemize → the two futures must tie:
        // both compound identical dollars at the same rate (proof 5).
        let r = MortgageMath.simulate(scenario(apr: 0.057, ret: 0.057))
        XCTAssertEqual(r.last.netB - r.last.netA, 0, accuracy: 0.5)
    }

    func testHigherReturnFavorsInvesting() {
        let r = MortgageMath.simulate(scenario(apr: 0.057, ret: 0.10))
        XCTAssertGreaterThan(r.last.netB, r.last.netA)
    }

    func testLowerReturnFavorsPrepaying() {
        let r = MortgageMath.simulate(scenario(apr: 0.057, ret: 0.03))
        XCTAssertGreaterThan(r.last.netA, r.last.netB)
    }

    func testMonthsCappedAt480() {
        let r = MortgageMath.simulate(scenario(apr: 0.057, ret: 0.10))   // horizon 24 yrs
        XCTAssertEqual(r.months, 288)
        XCTAssertEqual(r.rows.count, 288)
    }
}
