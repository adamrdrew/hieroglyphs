import XCTest
@testable import Hieroglyphs

final class ModelTests: XCTestCase {

    // MARK: - CardStatus Tests

    func testCardStatusAllCases() {
        let allCases = CardStatus.allCases
        XCTAssertEqual(allCases.count, 6)
        XCTAssertTrue(allCases.contains(.backlog))
        XCTAssertTrue(allCases.contains(.triage))
        XCTAssertTrue(allCases.contains(.todo))
        XCTAssertTrue(allCases.contains(.inProgress))
        XCTAssertTrue(allCases.contains(.done))
        XCTAssertTrue(allCases.contains(.archived))
    }

    func testCardStatusRawValues() {
        XCTAssertEqual(CardStatus.backlog.rawValue, "backlog")
        XCTAssertEqual(CardStatus.triage.rawValue, "triage")
        XCTAssertEqual(CardStatus.todo.rawValue, "todo")
        XCTAssertEqual(CardStatus.inProgress.rawValue, "in-progress")
        XCTAssertEqual(CardStatus.done.rawValue, "done")
        XCTAssertEqual(CardStatus.archived.rawValue, "archived")
    }

    func testCardStatusCodable() throws {
        let status = CardStatus.inProgress
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(status)
        let decoded = try decoder.decode(CardStatus.self, from: encoded)

        XCTAssertEqual(status, decoded)
    }

    func testCardStatusTriageCodable() throws {
        let status = CardStatus.triage
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(status)
        let decoded = try decoder.decode(CardStatus.self, from: encoded)

        XCTAssertEqual(status, decoded)
        XCTAssertEqual(decoded.rawValue, "triage")
    }

    // MARK: - CardType Tests

    func testCardTypeAllCases() {
        let allCases = CardType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.task))
        XCTAssertTrue(allCases.contains(.bug))
        XCTAssertTrue(allCases.contains(.feature))
        XCTAssertTrue(allCases.contains(.note))
    }

    func testCardTypeRawValues() {
        XCTAssertEqual(CardType.task.rawValue, "task")
        XCTAssertEqual(CardType.bug.rawValue, "bug")
        XCTAssertEqual(CardType.feature.rawValue, "feature")
        XCTAssertEqual(CardType.note.rawValue, "note")
    }

    func testCardTypeCodable() throws {
        let cardType = CardType.feature
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(cardType)
        let decoded = try decoder.decode(CardType.self, from: encoded)

        XCTAssertEqual(cardType, decoded)
    }

    // MARK: - Priority Tests

    func testPriorityAllCases() {
        let allCases = Priority.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.low))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.high))
        XCTAssertTrue(allCases.contains(.critical))
    }

    func testPriorityRawValues() {
        XCTAssertEqual(Priority.low.rawValue, "low")
        XCTAssertEqual(Priority.medium.rawValue, "medium")
        XCTAssertEqual(Priority.high.rawValue, "high")
        XCTAssertEqual(Priority.critical.rawValue, "critical")
    }

    func testPriorityCodable() throws {
        let priority = Priority.high
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(priority)
        let decoded = try decoder.decode(Priority.self, from: encoded)

        XCTAssertEqual(priority, decoded)
    }

    // MARK: - Project Tests

    func testProjectInitialization() {
        let projectId = UUID()
        let created = Date()
        let updated = Date()

        let project = Project(
            id: projectId,
            title: "Test Project",
            description: "A test project",
            tags: ["test", "sample"],
            created: created,
            updated: updated,
            slug: "test-project",
            sourceDirectory: nil
        )

        XCTAssertEqual(project.id, projectId)
        XCTAssertEqual(project.title, "Test Project")
        XCTAssertEqual(project.description, "A test project")
        XCTAssertEqual(project.tags, ["test", "sample"])
        XCTAssertEqual(project.created, created)
        XCTAssertEqual(project.updated, updated)
        XCTAssertEqual(project.slug, "test-project")
    }

    func testProjectEquatable() {
        let projectId = UUID()
        let created = Date()
        let updated = Date()

        let project1 = Project(
            id: projectId,
            title: "Test",
            description: "Desc",
            tags: ["tag"],
            created: created,
            updated: updated,
            slug: "test",
            sourceDirectory: nil
        )

        let project2 = Project(
            id: projectId,
            title: "Test",
            description: "Desc",
            tags: ["tag"],
            created: created,
            updated: updated,
            slug: "test",
            sourceDirectory: nil
        )

        XCTAssertEqual(project1, project2)
    }

    func testProjectCodable() throws {
        let projectId = UUID()
        let created = Date()
        let updated = Date()

        let project = Project(
            id: projectId,
            title: "Test Project",
            description: "A test project",
            tags: ["test"],
            created: created,
            updated: updated,
            slug: "test-project",
            sourceDirectory: nil
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(project)
        let decoded = try decoder.decode(Project.self, from: encoded)

        XCTAssertEqual(project, decoded)
    }

    func testProjectIdentifiable() {
        let projectId = UUID()

        let project = Project(
            id: projectId,
            title: "Test",
            description: "Desc",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test",
            sourceDirectory: nil
        )

        XCTAssertEqual(project.id, projectId)
    }

    // MARK: - Card Tests

    func testCardInitialization() {
        let cardId = UUID()
        let created = Date()
        let updated = Date()

        let card = Card(
            id: cardId,
            title: "Test Card",
            type: .task,
            status: .todo,
            priority: .high,
            tags: ["test", "sample"],
            created: created,
            updated: updated,
            slug: "test-card",
            body: "This is the card body."
        )

        XCTAssertEqual(card.id, cardId)
        XCTAssertEqual(card.title, "Test Card")
        XCTAssertEqual(card.type, .task)
        XCTAssertEqual(card.status, .todo)
        XCTAssertEqual(card.priority, .high)
        XCTAssertEqual(card.tags, ["test", "sample"])
        XCTAssertEqual(card.created, created)
        XCTAssertEqual(card.updated, updated)
        XCTAssertEqual(card.slug, "test-card")
        XCTAssertEqual(card.body, "This is the card body.")
    }

    func testCardEquatable() {
        let cardId = UUID()
        let created = Date()
        let updated = Date()

        let card1 = Card(
            id: cardId,
            title: "Test",
            type: .task,
            status: .todo,
            priority: .medium,
            tags: ["tag"],
            created: created,
            updated: updated,
            slug: "test",
            body: "Body"
        )

        let card2 = Card(
            id: cardId,
            title: "Test",
            type: .task,
            status: .todo,
            priority: .medium,
            tags: ["tag"],
            created: created,
            updated: updated,
            slug: "test",
            body: "Body"
        )

        XCTAssertEqual(card1, card2)
    }

    func testCardCodable() throws {
        let cardId = UUID()
        let created = Date()
        let updated = Date()

        let card = Card(
            id: cardId,
            title: "Test Card",
            type: .feature,
            status: .inProgress,
            priority: .critical,
            tags: ["test"],
            created: created,
            updated: updated,
            slug: "test-card",
            body: "Card body content"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(card)
        let decoded = try decoder.decode(Card.self, from: encoded)

        XCTAssertEqual(card, decoded)
    }

    func testCardIdentifiable() {
        let cardId = UUID()

        let card = Card(
            id: cardId,
            title: "Test",
            type: .note,
            status: .backlog,
            priority: .low,
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test",
            body: ""
        )

        XCTAssertEqual(card.id, cardId)
    }

    func testCardBodyStoresMarkdown() {
        let markdownBody = """
        # Heading

        This is a paragraph with **bold** and *italic* text.

        - List item 1
        - List item 2
        """

        let card = Card(
            id: UUID(),
            title: "Test",
            type: .note,
            status: .done,
            priority: .medium,
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test",
            body: markdownBody
        )

        XCTAssertEqual(card.body, markdownBody)
    }

    // MARK: - WorkspaceConfig Tests

    func testWorkspaceConfigInitialization() {
        let config = WorkspaceConfig(workspacePath: "/Users/test/workspace")

        XCTAssertEqual(config.workspacePath, "/Users/test/workspace")
    }

    func testWorkspaceConfigEquatable() {
        let config1 = WorkspaceConfig(workspacePath: "/Users/test/workspace")
        let config2 = WorkspaceConfig(workspacePath: "/Users/test/workspace")

        XCTAssertEqual(config1, config2)
    }

    func testWorkspaceConfigCodable() throws {
        let config = WorkspaceConfig(workspacePath: "/Users/test/workspace")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(config)
        let decoded = try decoder.decode(WorkspaceConfig.self, from: encoded)

        XCTAssertEqual(config, decoded)
    }

    // MARK: - SearchResult Tests

    func testSearchResultInitializationProject() {
        let resultId = UUID()

        let result = SearchResult(
            id: resultId,
            title: "Test Project",
            path: "/workspace/test-project/project.md",
            resultType: .project,
            projectSlug: "test-project",
            cardSlug: nil
        )

        XCTAssertEqual(result.id, resultId)
        XCTAssertEqual(result.title, "Test Project")
        XCTAssertEqual(result.path, "/workspace/test-project/project.md")
        XCTAssertEqual(result.resultType, .project)
        XCTAssertEqual(result.projectSlug, "test-project")
        XCTAssertNil(result.cardSlug)
    }

    func testSearchResultInitializationCard() {
        let resultId = UUID()

        let result = SearchResult(
            id: resultId,
            title: "Test Card",
            path: "/workspace/test-project/cards/test-card/card.md",
            resultType: .card,
            projectSlug: "test-project",
            cardSlug: "test-card"
        )

        XCTAssertEqual(result.id, resultId)
        XCTAssertEqual(result.title, "Test Card")
        XCTAssertEqual(result.path, "/workspace/test-project/cards/test-card/card.md")
        XCTAssertEqual(result.resultType, .card)
        XCTAssertEqual(result.projectSlug, "test-project")
        XCTAssertEqual(result.cardSlug, "test-card")
    }

    func testSearchResultIdentifiable() {
        let resultId = UUID()

        let result = SearchResult(
            id: resultId,
            title: "Test",
            path: "/test/path",
            resultType: .project
        )

        XCTAssertEqual(result.id, resultId)
    }

    func testSearchResultEquatable() {
        let resultId = UUID()

        let result1 = SearchResult(
            id: resultId,
            title: "Test",
            path: "/test/path",
            resultType: .project,
            projectSlug: "test"
        )

        let result2 = SearchResult(
            id: resultId,
            title: "Test",
            path: "/test/path",
            resultType: .project,
            projectSlug: "test"
        )

        XCTAssertEqual(result1, result2)
    }

    func testSearchResultHashable() {
        let resultId = UUID()

        let result1 = SearchResult(
            id: resultId,
            title: "Test",
            path: "/test/path",
            resultType: .project
        )

        let result2 = SearchResult(
            id: resultId,
            title: "Test",
            path: "/test/path",
            resultType: .project
        )

        var set = Set<SearchResult>()
        set.insert(result1)
        set.insert(result2)

        XCTAssertEqual(set.count, 1)
    }

    func testSearchResultTypeProject() {
        let type = SearchResultType.project
        XCTAssertEqual(type.rawValue, "project")
    }

    func testSearchResultTypeCard() {
        let type = SearchResultType.card
        XCTAssertEqual(type.rawValue, "card")
    }
}
