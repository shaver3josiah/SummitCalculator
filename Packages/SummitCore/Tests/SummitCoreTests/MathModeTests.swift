import XCTest
@testable import SummitCore

final class MathModeTests: XCTestCase {
    func testQuadraticRealRoots() {
        let r = MathModes.quadratic(a: 1, b: -3, c: 2)!
        XCTAssertEqual(r.discriminant, 1, accuracy: 1e-9)
        XCTAssertEqual(r.roots[0].re, 2, accuracy: 1e-9)
        XCTAssertEqual(r.roots[1].re, 1, accuracy: 1e-9)
        XCTAssertTrue(r.roots[0].isReal)
    }

    func testQuadraticComplexRoots() {
        let r = MathModes.quadratic(a: 1, b: 0, c: 1)!
        XCTAssertLessThan(r.discriminant, 0)
        XCTAssertEqual(r.roots[0].re, 0, accuracy: 1e-9)
        XCTAssertEqual(abs(r.roots[0].im), 1, accuracy: 1e-9)
        XCTAssertFalse(r.roots[0].isReal)
    }

    func testQuadraticLinearFallback() {
        let r = MathModes.quadratic(a: 0, b: 2, c: -4)!
        XCTAssertEqual(r.roots.count, 1)
        XCTAssertEqual(r.roots[0].re, 2, accuracy: 1e-9)
    }

    func testLinearSystemUnique() {
        let s = MathModes.linearSystem(a1: 1, b1: 1, c1: 5, a2: 1, b2: -1, c2: 1)!
        XCTAssertEqual(s.x, 3, accuracy: 1e-9)
        XCTAssertEqual(s.y, 2, accuracy: 1e-9)
    }

    func testLinearSystemParallel() {
        XCTAssertNil(MathModes.linearSystem(a1: 1, b1: 1, c1: 2, a2: 2, b2: 2, c2: 5))
    }

    func testPythagoreanHypotenuse() {
        let p = MathModes.pythagorean(a: 3, b: 4, c: nil)!
        XCTAssertEqual(p.side, .hypotenuse)
        XCTAssertEqual(p.value, 5, accuracy: 1e-9)
    }

    func testPythagoreanLeg() {
        let p = MathModes.pythagorean(a: nil, b: 4, c: 5)!
        XCTAssertEqual(p.side, .legA)
        XCTAssertEqual(p.value, 3, accuracy: 1e-9)
    }

    func testPythagoreanImpossible() {
        XCTAssertNil(MathModes.pythagorean(a: 9, b: nil, c: 4))
    }

    func testFractionAdd() {
        let f = MathModes.fraction(1, 2, .add, 1, 3)!
        XCTAssertEqual(f.num, 5)
        XCTAssertEqual(f.den, 6)
    }

    func testFractionSubtractNegativeSimplify() {
        let f = MathModes.fraction(1, 2, .subtract, 5, 6)!
        XCTAssertEqual(f.num, -1)
        XCTAssertEqual(f.den, 3)
    }

    func testFractionDivide() {
        let f = MathModes.fraction(3, 4, .divide, 3, 8)!
        XCTAssertEqual(f.num, 2)
        XCTAssertEqual(f.den, 1)
    }

    func testTrigDegrees() {
        XCTAssertEqual(MathModes.trig(.sin, 30, mode: .degrees), 0.5, accuracy: 1e-9)
        XCTAssertEqual(MathModes.trig(.cos, 60, mode: .degrees), 0.5, accuracy: 1e-9)
    }

    func testTrigRadians() {
        XCTAssertEqual(MathModes.trig(.sin, Double.pi / 6, mode: .radians), 0.5, accuracy: 1e-9)
    }

    func testInverseTrigDegrees() {
        XCTAssertEqual(MathModes.trig(.asin, 0.5, mode: .degrees), 30, accuracy: 1e-9)
        XCTAssertEqual(MathModes.trig(.atan, 1, mode: .degrees), 45, accuracy: 1e-9)
    }
}
