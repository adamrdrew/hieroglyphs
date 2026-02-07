import XCTest
@testable import Hieroglyphs

final class FrontmatterParserTests: XCTestCase {

    // MARK: - Parse Tests

    func testParseValidFrontmatterWithBody() throws {
        let markdown = """
        ---
        title: Test Card
        status: todo
        ---
        This is the body.
        """

        let result = try FrontmatterParser.parse(markdown)

        XCTAssertEqual(result.frontmatter["title"] as? String, "Test Card")
        XCTAssertEqual(result.frontmatter["status"] as? String, "todo")
        XCTAssertEqual(result.body, "This is the body.")
    }

    func testParseFrontmatterWithUnknownFields() throws {
        let markdown = """
        ---
        title: Test Card
        custom_field: custom value
        another_field: 123
        ---
        Body content
        """

        let result = try FrontmatterParser.parse(markdown)

        XCTAssertEqual(result.frontmatter["title"] as? String, "Test Card")
        XCTAssertEqual(result.frontmatter["custom_field"] as? String, "custom value")
        XCTAssertEqual(result.frontmatter["another_field"] as? Int, 123)
        XCTAssertEqual(result.body, "Body content")
    }

    func testParseMissingFrontmatter() throws {
        let markdown = "This is just body content without frontmatter."

        let result = try FrontmatterParser.parse(markdown)

        XCTAssertTrue(result.frontmatter.isEmpty)
        XCTAssertEqual(result.body, markdown)
    }

    func testParseEmptyFrontmatter() throws {
        let markdown = """
        ---
        ---
        Body content
        """

        let result = try FrontmatterParser.parse(markdown)

        XCTAssertTrue(result.frontmatter.isEmpty)
        XCTAssertEqual(result.body, "Body content")
    }

    func testParseMalformedYAML() {
        let markdown = """
        ---
        title: Test
        invalid: [unclosed array
        ---
        Body
        """

        XCTAssertThrowsError(try FrontmatterParser.parse(markdown)) { error in
            if case FrontmatterParser.ParserError.yamlParsingFailed = error {
                // Expected error type
            } else {
                XCTFail("Expected yamlParsingFailed error, got \(error)")
            }
        }
    }

    func testParseEmptyString() throws {
        let markdown = ""

        let result = try FrontmatterParser.parse(markdown)

        XCTAssertTrue(result.frontmatter.isEmpty)
        XCTAssertEqual(result.body, "")
    }

    func testParseFrontmatterWithNestedStructures() throws {
        let markdown = """
        ---
        title: Complex Card
        tags:
          - tag1
          - tag2
        metadata:
          author: John
          version: 1
        ---
        Body
        """

        let result = try FrontmatterParser.parse(markdown)

        XCTAssertEqual(result.frontmatter["title"] as? String, "Complex Card")
        XCTAssertEqual(result.frontmatter["tags"] as? [String], ["tag1", "tag2"])

        let metadata = result.frontmatter["metadata"] as? [String: Any]
        XCTAssertNotNil(metadata)
        XCTAssertEqual(metadata?["author"] as? String, "John")
        XCTAssertEqual(metadata?["version"] as? Int, 1)

        XCTAssertEqual(result.body, "Body")
    }

    // MARK: - Serialize Tests

    func testSerializeValidFrontmatterWithBody() throws {
        let frontmatter: [String: Any] = ["title": "Test Card", "status": "todo"]
        let body = "This is the body."

        let result = try FrontmatterParser.serialize(frontmatter: frontmatter, body: body)

        XCTAssertTrue(result.hasPrefix("---\n"))
        XCTAssertTrue(result.contains("title: Test Card"))
        XCTAssertTrue(result.contains("status: todo"))
        XCTAssertTrue(result.hasSuffix("---\nThis is the body."))
    }

    func testSerializeEmptyFrontmatterWithBody() throws {
        let frontmatter: [String: Any] = [:]
        let body = "Just body content"

        let result = try FrontmatterParser.serialize(frontmatter: frontmatter, body: body)

        XCTAssertEqual(result, "Just body content")
    }

    func testSerializeFrontmatterWithEmptyBody() throws {
        let frontmatter: [String: Any] = ["title": "Test"]
        let body = ""

        let result = try FrontmatterParser.serialize(frontmatter: frontmatter, body: body)

        XCTAssertTrue(result.hasPrefix("---\n"))
        XCTAssertTrue(result.contains("title: Test"))
        XCTAssertTrue(result.hasSuffix("---\n"))
    }

    func testRoundTripPreservesContent() throws {
        let original = """
        ---
        title: Test Card
        status: todo
        priority: high
        ---
        Body content here.
        """

        let parsed = try FrontmatterParser.parse(original)
        let serialized = try FrontmatterParser.serialize(frontmatter: parsed.frontmatter, body: parsed.body)
        let reparsed = try FrontmatterParser.parse(serialized)

        XCTAssertEqual(parsed.frontmatter["title"] as? String, reparsed.frontmatter["title"] as? String)
        XCTAssertEqual(parsed.frontmatter["status"] as? String, reparsed.frontmatter["status"] as? String)
        XCTAssertEqual(parsed.frontmatter["priority"] as? String, reparsed.frontmatter["priority"] as? String)
        XCTAssertEqual(parsed.body, reparsed.body)
    }

    func testRoundTripPreservesUnknownFields() throws {
        let original = """
        ---
        title: Test Card
        custom_field: custom value
        another_field: 123
        ---
        Body
        """

        let parsed = try FrontmatterParser.parse(original)
        let serialized = try FrontmatterParser.serialize(frontmatter: parsed.frontmatter, body: parsed.body)
        let reparsed = try FrontmatterParser.parse(serialized)

        XCTAssertEqual(parsed.frontmatter["title"] as? String, reparsed.frontmatter["title"] as? String)
        XCTAssertEqual(parsed.frontmatter["custom_field"] as? String, reparsed.frontmatter["custom_field"] as? String)
        XCTAssertEqual(parsed.frontmatter["another_field"] as? Int, reparsed.frontmatter["another_field"] as? Int)
        XCTAssertEqual(parsed.body, reparsed.body)
    }
}
