import XCTest
@testable import Hieroglyphs

final class WorkspaceServiceTests: XCTestCase {

    private var fixtureRoot: URL!
    private var workspaceURL: URL!
    private var configURL: URL!
    private var fileManager: FileManager!

    override func setUp() {
        super.setUp()
        fileManager = FileManager.default

        let tempDir = fileManager.temporaryDirectory
        fixtureRoot = tempDir.appendingPathComponent(UUID().uuidString)
        workspaceURL = fixtureRoot.appendingPathComponent("workspace")
        configURL = fixtureRoot.appendingPathComponent(".hieroglyphs")

        try? fileManager.createDirectory(
            at: fixtureRoot,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        if let fixtureRoot = fixtureRoot {
            try? fileManager.removeItem(at: fixtureRoot)
        }
        super.tearDown()
    }

    private func createFixtureWorkspace() throws {
        try fileManager.createDirectory(
            at: workspaceURL,
            withIntermediateDirectories: true
        )

        try fileManager.createDirectory(
            at: configURL,
            withIntermediateDirectories: true
        )

        let configContent = """
        workspacePath: \(workspaceURL.path)
        """
        let configFile = configURL.appendingPathComponent("config.yaml")
        try configContent.write(to: configFile, atomically: true, encoding: .utf8)
    }

    private func createProject(
        slug: String,
        id: String,
        title: String,
        description: String = "",
        tags: [String] = [],
        created: String = "2026-01-01T10:00:00Z",
        updated: String = "2026-01-02T10:00:00Z"
    ) throws {
        let projectDir = workspaceURL.appendingPathComponent(slug)
        try fileManager.createDirectory(
            at: projectDir,
            withIntermediateDirectories: true
        )

        let tagsYAML = tags.isEmpty ? "[]" : "\n  - " + tags.joined(separator: "\n  - ")
        let projectContent = """
        ---
        id: \(id)
        title: \(title)
        description: \(description)
        tags: \(tagsYAML)
        created: \(created)
        updated: \(updated)
        ---

        Project body content.
        """

        let projectFile = projectDir.appendingPathComponent("project.md")
        try projectContent.write(to: projectFile, atomically: true, encoding: .utf8)
    }

    private func createCard(
        projectSlug: String,
        cardSlug: String,
        id: String,
        title: String,
        type: String = "task",
        status: String = "backlog",
        priority: String = "medium",
        tags: [String] = [],
        created: String = "2026-01-01T10:00:00Z",
        updated: String = "2026-01-02T10:00:00Z",
        body: String = "Card body content."
    ) throws {
        let projectDir = workspaceURL.appendingPathComponent(projectSlug)
        let cardsDir = projectDir.appendingPathComponent("cards")
        let cardDir = cardsDir.appendingPathComponent(cardSlug)

        try fileManager.createDirectory(
            at: cardDir,
            withIntermediateDirectories: true
        )

        let tagsYAML = tags.isEmpty ? "[]" : "\n  - " + tags.joined(separator: "\n  - ")
        let cardContent = """
        ---
        id: \(id)
        title: \(title)
        type: \(type)
        status: \(status)
        priority: \(priority)
        tags: \(tagsYAML)
        created: \(created)
        updated: \(updated)
        ---

        \(body)
        """

        let cardFile = cardDir.appendingPathComponent("card.md")
        try cardContent.write(to: cardFile, atomically: true, encoding: .utf8)
    }

    // MARK: - loadWorkspaceConfig() Tests

    func testLoadWorkspaceConfig() throws {
        try createFixtureWorkspace()

        let service = WorkspaceService(fileManager: fileManager)
        let configFile = configURL.appendingPathComponent("config.yaml")
        let config = try service.loadWorkspaceConfig(from: configFile.path)

        XCTAssertEqual(config.workspacePath, workspaceURL.path)
    }

    func testLoadWorkspaceConfigMissingFile() throws {
        let service = WorkspaceService(fileManager: fileManager)
        let nonExistentPath = fixtureRoot.appendingPathComponent("missing.yaml").path

        XCTAssertThrowsError(try service.loadWorkspaceConfig(from: nonExistentPath)) { error in
            XCTAssertTrue(error is WorkspaceService.WorkspaceError)
        }
    }

    // MARK: - loadProjects() Discovery Tests

    func testLoadProjectsDiscovery() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "project-alpha",
            id: "11111111-1111-1111-1111-111111111111",
            title: "Project Alpha"
        )
        try createProject(
            slug: "project-beta",
            id: "22222222-2222-2222-2222-222222222222",
            title: "Project Beta"
        )

        let service = WorkspaceService(fileManager: fileManager)
        let projects = try service.loadProjects(from: workspaceURL.path)

        XCTAssertEqual(projects.count, 2)
        let slugs = projects.map { $0.slug }.sorted()
        XCTAssertEqual(slugs, ["project-alpha", "project-beta"])
    }

    func testLoadProjectsEmptyWorkspace() throws {
        try createFixtureWorkspace()

        let service = WorkspaceService(fileManager: fileManager)
        let projects = try service.loadProjects(from: workspaceURL.path)

        XCTAssertEqual(projects.count, 0)
    }

    // MARK: - loadProjects() Parsing Tests

    func testLoadProjectsParsing() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "33333333-3333-3333-3333-333333333333",
            title: "Test Project",
            description: "A test project",
            tags: ["swift", "testing"],
            created: "2026-01-15T10:00:00Z",
            updated: "2026-01-20T15:30:00Z"
        )

        let service = WorkspaceService(fileManager: fileManager)
        let projects = try service.loadProjects(from: workspaceURL.path)

        XCTAssertEqual(projects.count, 1)
        let project = projects[0]

        XCTAssertEqual(project.id.uuidString, "33333333-3333-3333-3333-333333333333")
        XCTAssertEqual(project.title, "Test Project")
        XCTAssertEqual(project.description, "A test project")
        XCTAssertEqual(project.tags, ["swift", "testing"])
        XCTAssertEqual(project.slug, "test-project")

        let dateFormatter = ISO8601DateFormatter()
        let expectedCreated = dateFormatter.date(from: "2026-01-15T10:00:00Z")
        let expectedUpdated = dateFormatter.date(from: "2026-01-20T15:30:00Z")
        XCTAssertEqual(project.created, expectedCreated)
        XCTAssertEqual(project.updated, expectedUpdated)
    }

    func testLoadProjectsSkipsMalformed() throws {
        try createFixtureWorkspace()

        let goodProjectDir = workspaceURL.appendingPathComponent("good-project")
        try fileManager.createDirectory(at: goodProjectDir, withIntermediateDirectories: true)
        let goodContent = """
        ---
        id: 44444444-4444-4444-4444-444444444444
        title: Good Project
        description: Valid
        tags: []
        created: 2026-01-01T10:00:00Z
        updated: 2026-01-02T10:00:00Z
        ---
        """
        try goodContent.write(
            to: goodProjectDir.appendingPathComponent("project.md"),
            atomically: true,
            encoding: .utf8
        )

        let badProjectDir = workspaceURL.appendingPathComponent("bad-project")
        try fileManager.createDirectory(at: badProjectDir, withIntermediateDirectories: true)
        let badContent = """
        ---
        title: Missing ID
        ---
        """
        try badContent.write(
            to: badProjectDir.appendingPathComponent("project.md"),
            atomically: true,
            encoding: .utf8
        )

        let service = WorkspaceService(fileManager: fileManager)
        let projects = try service.loadProjects(from: workspaceURL.path)

        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects[0].slug, "good-project")
    }

    // MARK: - loadCards() Discovery Tests

    func testLoadCardsDiscovery() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "55555555-5555-5555-5555-555555555555",
            title: "Test Project"
        )
        try createCard(
            projectSlug: "test-project",
            cardSlug: "card-one",
            id: "66666666-6666-6666-6666-666666666666",
            title: "Card One"
        )
        try createCard(
            projectSlug: "test-project",
            cardSlug: "card-two",
            id: "77777777-7777-7777-7777-777777777777",
            title: "Card Two"
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project").path
        let project = Project(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            title: "Test Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test-project"
        )

        let service = WorkspaceService(fileManager: fileManager)
        let cards = try service.loadCards(from: projectPath, for: project)

        XCTAssertEqual(cards.count, 2)
        let slugs = cards.map { $0.slug }.sorted()
        XCTAssertEqual(slugs, ["card-one", "card-two"])
    }

    func testLoadCardsNoCardsDirectory() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "empty-project",
            id: "88888888-8888-8888-8888-888888888888",
            title: "Empty Project"
        )

        let projectPath = workspaceURL.appendingPathComponent("empty-project").path
        let project = Project(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            title: "Empty Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "empty-project"
        )

        let service = WorkspaceService(fileManager: fileManager)
        let cards = try service.loadCards(from: projectPath, for: project)

        XCTAssertEqual(cards.count, 0)
    }

    // MARK: - loadCards() Parsing Tests

    func testLoadCardsParsing() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "99999999-9999-9999-9999-999999999999",
            title: "Test Project"
        )
        try createCard(
            projectSlug: "test-project",
            cardSlug: "test-card",
            id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            title: "Test Card",
            type: "bug",
            status: "in-progress",
            priority: "high",
            tags: ["urgent", "backend"],
            created: "2026-01-10T09:00:00Z",
            updated: "2026-01-12T14:00:00Z",
            body: "This is the card body content."
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project").path
        let project = Project(
            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            title: "Test Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test-project"
        )

        let service = WorkspaceService(fileManager: fileManager)
        let cards = try service.loadCards(from: projectPath, for: project)

        XCTAssertEqual(cards.count, 1)
        let card = cards[0]

        XCTAssertEqual(card.id.uuidString, "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")
        XCTAssertEqual(card.title, "Test Card")
        XCTAssertEqual(card.type, .bug)
        XCTAssertEqual(card.status, .inProgress)
        XCTAssertEqual(card.priority, .high)
        XCTAssertEqual(card.tags, ["urgent", "backend"])
        XCTAssertEqual(card.slug, "test-card")
        XCTAssertEqual(card.body, "This is the card body content.")

        let dateFormatter = ISO8601DateFormatter()
        let expectedCreated = dateFormatter.date(from: "2026-01-10T09:00:00Z")
        let expectedUpdated = dateFormatter.date(from: "2026-01-12T14:00:00Z")
        XCTAssertEqual(card.created, expectedCreated)
        XCTAssertEqual(card.updated, expectedUpdated)
    }

    func testLoadCardsSkipsMalformed() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
            title: "Test Project"
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project")
        let cardsDir = projectPath.appendingPathComponent("cards")

        let goodCardDir = cardsDir.appendingPathComponent("good-card")
        try fileManager.createDirectory(at: goodCardDir, withIntermediateDirectories: true)
        let goodContent = """
        ---
        id: cccccccc-cccc-cccc-cccc-cccccccccccc
        title: Good Card
        type: task
        status: backlog
        priority: medium
        tags: []
        created: 2026-01-01T10:00:00Z
        updated: 2026-01-02T10:00:00Z
        ---

        Body content.
        """
        try goodContent.write(
            to: goodCardDir.appendingPathComponent("card.md"),
            atomically: true,
            encoding: .utf8
        )

        let badCardDir = cardsDir.appendingPathComponent("bad-card")
        try fileManager.createDirectory(at: badCardDir, withIntermediateDirectories: true)
        let badContent = """
        ---
        title: Missing ID
        ---
        """
        try badContent.write(
            to: badCardDir.appendingPathComponent("card.md"),
            atomically: true,
            encoding: .utf8
        )

        let project = Project(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            title: "Test Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test-project"
        )

        let service = WorkspaceService(fileManager: fileManager)
        let cards = try service.loadCards(from: projectPath.path, for: project)

        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].slug, "good-card")
    }

    // MARK: - Error Handling Tests

    func testLoadProjectsInvalidDirectory() throws {
        let service = WorkspaceService(fileManager: fileManager)
        let nonExistentPath = fixtureRoot.appendingPathComponent("nonexistent").path

        XCTAssertThrowsError(try service.loadProjects(from: nonExistentPath)) { error in
            guard let workspaceError = error as? WorkspaceService.WorkspaceError else {
                XCTFail("Expected WorkspaceError")
                return
            }
            if case .invalidDirectory = workspaceError {
                // Expected error
            } else {
                XCTFail("Expected invalidDirectory error")
            }
        }
    }

    func testLoadProjectsWithInvalidYAML() throws {
        try createFixtureWorkspace()

        let projectDir = workspaceURL.appendingPathComponent("invalid-yaml")
        try fileManager.createDirectory(at: projectDir, withIntermediateDirectories: true)

        let invalidYAML = """
        ---
        this is not: valid: yaml: syntax
        ---
        """
        try invalidYAML.write(
            to: projectDir.appendingPathComponent("project.md"),
            atomically: true,
            encoding: .utf8
        )

        let service = WorkspaceService(fileManager: fileManager)
        let projects = try service.loadProjects(from: workspaceURL.path)

        XCTAssertEqual(projects.count, 0)
    }

    func testLoadCardsHandlesMissingRequiredFields() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "dddddddd-dddd-dddd-dddd-dddddddddddd",
            title: "Test Project"
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project")
        let cardDir = projectPath.appendingPathComponent("cards/incomplete-card")
        try fileManager.createDirectory(at: cardDir, withIntermediateDirectories: true)

        let incompleteCard = """
        ---
        type: task
        status: backlog
        ---

        Missing id and title.
        """
        try incompleteCard.write(
            to: cardDir.appendingPathComponent("card.md"),
            atomically: true,
            encoding: .utf8
        )

        let project = Project(
            id: UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!,
            title: "Test Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test-project"
        )

        let service = WorkspaceService(fileManager: fileManager)
        let cards = try service.loadCards(from: projectPath.path, for: project)

        XCTAssertEqual(cards.count, 0)
    }

    func testLoadCardsHandlesDefaultEnumValues() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
            title: "Test Project"
        )
        try createCard(
            projectSlug: "test-project",
            cardSlug: "invalid-enums",
            id: "ffffffff-ffff-ffff-ffff-ffffffffffff",
            title: "Invalid Enum Card",
            type: "invalid-type",
            status: "invalid-status",
            priority: "invalid-priority"
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project").path
        let project = Project(
            id: UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!,
            title: "Test Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test-project"
        )

        let service = WorkspaceService(fileManager: fileManager)
        let cards = try service.loadCards(from: projectPath, for: project)

        XCTAssertEqual(cards.count, 1)
        let card = cards[0]
        XCTAssertEqual(card.type, .task)
        XCTAssertEqual(card.status, .backlog)
        XCTAssertEqual(card.priority, .medium)
    }
}
