import XCTest
@testable import SummitCore

final class FoodTests: XCTestCase {
    func testFoodCount() {
        let foods = FoodLibrary.load()
        XCTAssertEqual(foods.count, 410)
    }

    func testMatchFlour() {
        let match = FoodLibrary.match("flour")
        XCTAssertNotNil(match)
    }

    func testGroupsNonEmpty() {
        let groups = FoodLibrary.groups()
        XCTAssertFalse(groups.isEmpty)
    }

    func testParseStripsDescriptorLargeEggs() {
        XCTAssertEqual(RecipeParse.parseLine("2 large eggs")?.name, "eggs")
    }

    func testParseStripsDescriptorRipeBanana() {
        XCTAssertEqual(RecipeParse.parseLine("1 ripe banana")?.name, "banana")
    }

    func testParseStripsDescriptorBonelessSkinlessChicken() {
        XCTAssertEqual(RecipeParse.parseLine("boneless skinless chicken breast")?.name, "chicken breast")
    }

    func testParseKeepsAllPurposeFlour() {
        XCTAssertEqual(RecipeParse.parseLine("1 cup all-purpose flour")?.name, "all-purpose flour")
    }

    func testParseKeepsOliveOil() {
        XCTAssertEqual(RecipeParse.parseLine("3 tablespoons olive oil")?.name, "olive oil")
    }

    func testParseKeepsGroundBeef() {
        XCTAssertEqual(RecipeParse.parseLine("1 lb ground beef")?.name, "ground beef")
    }

    func testMatchLargeEggsResolves() {
        let parsed = RecipeParse.parseLine("2 large eggs")
        XCTAssertNotNil(FoodLibrary.match(parsed?.name ?? ""))
    }

    func testMatchBonelessSkinlessChickenResolves() {
        let parsed = RecipeParse.parseLine("boneless skinless chicken breast")
        XCTAssertNotNil(FoodLibrary.match(parsed?.name ?? ""))
    }

    func testMatchRipeBananaResolves() {
        let parsed = RecipeParse.parseLine("1 ripe banana")
        XCTAssertNotNil(FoodLibrary.match(parsed?.name ?? ""))
    }

    func testNoOverMatchGibberish() {
        XCTAssertNil(FoodLibrary.match("1 zzqx of glorp"))
    }

    func testNoOverMatchNonsenseWord() {
        XCTAssertNil(FoodLibrary.match("flibbertigibbet"))
    }
}
