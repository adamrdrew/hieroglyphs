import XCTest
@testable import Hieroglyphs

private final class ResultsBox: @unchecked Sendable {
    var results: [SearchResult] = []
}

final class SpotlightServiceTests: XCTestCase {
    var service: SpotlightService!

    override func setUp() async throws {
        try await super.setUp()
        service = SpotlightService()
    }

    // MARK: - Empty Query

    func testEmptyQueryReturnsEmpty() async {
        let expectation = expectation(
            description: "Empty query returns empty"
        )
        let resultsBox = ResultsBox()

        service.performSearch(
            query: "",
            scope: "/tmp"
        ) { results in
            resultsBox.results = results
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)

        XCTAssertEqual(resultsBox.results.count, 0)
    }

    // MARK: - determineResultType

    func testDetermineResultTypeProject() {
        let result = service.determineResultType(
            path: "/workspace/my-project/project.md"
        )
        XCTAssertEqual(result, .project)
    }

    func testDetermineResultTypeCard() {
        let result = service.determineResultType(
            path: "/workspace/proj/cards/my-card/card.md"
        )
        XCTAssertEqual(result, .card)
    }

    func testDetermineResultTypeUnknownFile() {
        let result = service.determineResultType(
            path: "/workspace/proj/notes.md"
        )
        XCTAssertNil(result)
    }

    func testDetermineResultTypePartialMatch() {
        let result = service.determineResultType(
            path: "/workspace/proj/not-project.md"
        )
        XCTAssertNil(result)
    }

    // MARK: - extractSlugs

    func testExtractSlugsForProject() {
        let (projectSlug, cardSlug) = service.extractSlugs(
            path: "/workspace/my-project/project.md",
            type: .project
        )
        XCTAssertEqual(projectSlug, "my-project")
        XCTAssertNil(cardSlug)
    }

    func testExtractSlugsForCard() {
        let (projectSlug, cardSlug) = service.extractSlugs(
            path: "/workspace/my-project/cards/my-card/card.md",
            type: .card
        )
        XCTAssertEqual(projectSlug, "my-project")
        XCTAssertEqual(cardSlug, "my-card")
    }

    func testExtractSlugsProjectShortPath() {
        let (projectSlug, cardSlug) = service.extractSlugs(
            path: "project.md",
            type: .project
        )
        XCTAssertNil(projectSlug)
        XCTAssertNil(cardSlug)
    }

    func testExtractSlugsCardShortPath() {
        let (projectSlug, cardSlug) = service.extractSlugs(
            path: "card.md",
            type: .card
        )
        XCTAssertNil(projectSlug)
        XCTAssertNil(cardSlug)
    }
}
