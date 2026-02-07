import XCTest
@testable import Hieroglyphs

final class SlugGeneratorTests: XCTestCase {

    func testSimpleTitle() {
        let result = SlugGenerator.generateSlug(from: "Hello World")
        XCTAssertEqual(result, "hello-world")
    }

    func testSpecialCharacters() {
        let result = SlugGenerator.generateSlug(from: "Add @mentions & #tags!")
        XCTAssertEqual(result, "add-mentions-tags")
    }

    func testConsecutiveSpaces() {
        let result = SlugGenerator.generateSlug(from: "Too    Many     Spaces")
        XCTAssertEqual(result, "too-many-spaces")
    }

    func testLeadingAndTrailingSpaces() {
        let result = SlugGenerator.generateSlug(from: "  Trim Me  ")
        XCTAssertEqual(result, "trim-me")
    }

    func testAlreadyLowercase() {
        let result = SlugGenerator.generateSlug(from: "already-done")
        XCTAssertEqual(result, "already-done")
    }

    func testNumbers() {
        let result = SlugGenerator.generateSlug(from: "Plan 2024")
        XCTAssertEqual(result, "plan-2024")
    }

    func testEmptyString() {
        let result = SlugGenerator.generateSlug(from: "")
        XCTAssertEqual(result, "")
    }

    func testUnicode() {
        let result = SlugGenerator.generateSlug(from: "Café René")
        XCTAssertEqual(result, "café-rené")
    }
}
