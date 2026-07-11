import XCTest
@testable import SummitCore

final class EggContentTests: XCTestCase {
    func testAllEggsLoad() {
        let eggs = EasterEggs.all()
        XCTAssertEqual(eggs.count, 6)
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
