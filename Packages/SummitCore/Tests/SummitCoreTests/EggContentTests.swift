import XCTest
@testable import SummitCore

final class EggContentTests: XCTestCase {
    func testAllEggsLoad() {
        // 5 originals (42 egg retired) + 10 Bible-verse eggs
        let eggs = EasterEggs.all()
        XCTAssertEqual(eggs.count, 15)
    }

    func testVerseEggsMatchEveryOperator() {
        // Each verse reference fires on ×, −, ÷ and + (glyph and ascii forms).
        for seq in ["1×16×13", "1*16*13", "2−1−7", "2-1-7", "1÷2÷2", "1/2/2", "1+4+4", "4+1+10"] {
            XCTAssertNotNil(EasterEggs.match(sequence: seq), seq)
        }
        XCTAssertNil(EasterEggs.match(sequence: "7×6"), "the 42 egg should be gone")
        XCTAssertNil(EasterEggs.match(sequence: "3×3×3"), "not every triple is a verse")
    }

    func testEveryEggHasNonEmptyLinesAndTriggers() {
        let eggs = EasterEggs.all()
        for egg in eggs {
            XCTAssertFalse(egg.lines.isEmpty, egg.id)
            XCTAssertFalse(egg.triggers.isEmpty, egg.id)
            for line in egg.lines {
                XCTAssertFalse(line.isEmpty, egg.id)
            }
            for trigger in egg.triggers {
                XCTAssertFalse(trigger.isEmpty, egg.id)
            }
        }
    }

    func testPsalmEggHintsTheNextClimb() {
        let eggs = EasterEggs.all()
        guard let psalm = eggs.first(where: { $0.id == "lift-my-eyes" }) else {
            XCTFail("psalm egg (lift-my-eyes) not found")
            return
        }
        guard let more = psalm.more else {
            XCTFail("psalm egg has no more array")
            return
        }
        let containsFourteen = more.contains { $0.contains("14") }
        XCTAssertTrue(containsFourteen, "psalm egg more array should hint the 14×58 egg")
    }
}
