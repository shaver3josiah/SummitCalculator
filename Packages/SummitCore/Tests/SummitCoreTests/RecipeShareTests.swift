import XCTest
@testable import SummitCore

final class RecipeShareTests: XCTestCase {

    func testHTMLEscapeCoversAllFive() {
        XCTAssertEqual(RecipeShare.htmlEscape("Mom's B&B <\"pancakes\">"),
                       "Mom&#39;s B&amp;B &lt;&quot;pancakes&quot;&gt;")
    }

    func testHTMLEscapePlainTextUnchanged() {
        XCTAssertEqual(RecipeShare.htmlEscape("2 cups flour"), "2 cups flour")
    }

    func testSafeURLRejectsNonHTTP() {
        XCTAssertNil(RecipeShare.safeURL("javascript:alert(1)"))
        XCTAssertNil(RecipeShare.safeURL("data:text/html,<script>"))
        XCTAssertNil(RecipeShare.safeURL(""))
        XCTAssertEqual(RecipeShare.safeURL("https://example.com/r"), "https://example.com/r")
    }

    func testHostStripsWWW() {
        XCTAssertEqual(RecipeShare.host(of: "https://www.seriouseats.com/recipe"), "seriouseats.com")
        XCTAssertNil(RecipeShare.host(of: "notaurl"))
    }

    func testTextNumbersStepsAndBulletsIngredients() {
        let out = RecipeShare.text(
            name: "Cookies", serves: "24", time: "45 min",
            ingredients: ["1 cup butter", "  ", "2 eggs"],
            steps: ["Brown the butter\nuntil nutty", "", "Bake 11 min"],
            notes: "Chill overnight.", sourceUrl: "https://www.example.com/c")
        // blank ingredient/step dropped
        XCTAssertTrue(out.contains("•  1 cup butter"))
        XCTAssertTrue(out.contains("•  2 eggs"))
        XCTAssertFalse(out.contains("•  \n"))
        // steps numbered 1..2 (blank removed) and multiline flattened to one line
        XCTAssertTrue(out.contains("1. Brown the butter until nutty"))
        XCTAssertTrue(out.contains("2. Bake 11 min"))
        XCTAssertTrue(out.contains("INGREDIENTS"))
        XCTAssertTrue(out.contains("METHOD"))
        XCTAssertTrue(out.contains("NOTES"))
        XCTAssertTrue(out.contains("From example.com"))
        XCTAssertTrue(out.contains("— logged at base camp • Summit Kitchen ▲"))
    }

    func testTextEmptyRecipeStillHasTitle() {
        let out = RecipeShare.text(name: "", serves: "", time: "",
                                   ingredients: [], steps: [], notes: "", sourceUrl: "")
        XCTAssertTrue(out.hasPrefix("Recipe"))
        XCTAssertFalse(out.contains("INGREDIENTS"))   // no empty sections
        XCTAssertFalse(out.contains("From "))
    }

    func testHTMLEscapesRecipeFieldsAndTitle() {
        let out = RecipeShare.html(
            name: "Mom's <Best> Cookies", serves: "24", time: "45 min",
            ingredients: ["1 cup \"sugar\""], steps: ["Mix & bake"],
            notes: "Store in a tin & enjoy", sourceUrl: "")
        XCTAssertTrue(out.contains("Mom&#39;s &lt;Best&gt; Cookies"))
        XCTAssertFalse(out.contains("<Best>"))
        XCTAssertTrue(out.contains("1 cup &quot;sugar&quot;"))
        XCTAssertTrue(out.contains("Mix &amp; bake"))
        XCTAssertTrue(out.contains("Store in a tin &amp; enjoy"))
    }

    func testHTMLRejectsUnsafeSourceURL() {
        let out = RecipeShare.html(name: "Tea", serves: "", time: "",
                                   ingredients: [], steps: [], notes: "",
                                   sourceUrl: "javascript:alert(1)")
        XCTAssertFalse(out.contains("javascript:alert"))
    }

    func testHTMLIncludesSafeSourceLink() {
        let out = RecipeShare.html(name: "Tea", serves: "", time: "",
                                   ingredients: [], steps: [], notes: "",
                                   sourceUrl: "https://www.example.com/tea")
        XCTAssertTrue(out.contains("href=\"https://www.example.com/tea\""))
        XCTAssertTrue(out.contains(">example.com<"))
    }

    func testHTMLSelfContainedNoExternalRequests() {
        let out = RecipeShare.html(name: "Tea", serves: "", time: "",
                                   ingredients: ["Water"], steps: ["Boil it"], notes: "",
                                   sourceUrl: "")
        XCTAssertFalse(out.contains("http://") && out.contains("<script src="))
        XCTAssertFalse(out.contains("<link rel=\"stylesheet\" href=\"http"))
    }
}
