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
        updated: String = "2026-01-02T10:00:00Z",
        sourceDirectory: String? = nil
    ) throws {
        let projectDir = workspaceURL.appendingPathComponent(slug)
        try fileManager.createDirectory(
            at: projectDir,
            withIntermediateDirectories: true
        )

        let tagsYAML = tags.isEmpty ? "[]" : "\n  - " + tags.joined(separator: "\n  - ")
        let sourceDirectoryLine = sourceDirectory.map { "\nsource_directory: \($0)" } ?? ""
        let projectContent = """
        ---
        id: \(id)
        title: \(title)
        description: \(description)
        tags: \(tagsYAML)
        created: \(created)
        updated: \(updated)\(sourceDirectoryLine)
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
            slug: "test-project",
            sourceDirectory: nil
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
            slug: "empty-project",
            sourceDirectory: nil
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
            slug: "test-project",
            sourceDirectory: nil
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
            slug: "test-project",
            sourceDirectory: nil
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
            slug: "test-project",
            sourceDirectory: nil
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
            slug: "test-project",
            sourceDirectory: nil
        )

        let service = WorkspaceService(fileManager: fileManager)
        let cards = try service.loadCards(from: projectPath, for: project)

        XCTAssertEqual(cards.count, 1)
        let card = cards[0]
        XCTAssertEqual(card.type, .task)
        XCTAssertEqual(card.status, .backlog)
        XCTAssertEqual(card.priority, .medium)
    }

    // MARK: - createWorkspace() Tests

    func testCreateWorkspace() throws {
        let workspacePath = fixtureRoot.appendingPathComponent("new-workspace").path
        let configDir = fixtureRoot.appendingPathComponent(".hieroglyphs").path
        let service = WorkspaceService(fileManager: fileManager)

        try service.createWorkspace(at: workspacePath, configDirectory: configDir)

        XCTAssertTrue(fileManager.fileExists(atPath: workspacePath))

        let configPath = fixtureRoot
            .appendingPathComponent(".hieroglyphs/config.yaml")
        XCTAssertTrue(fileManager.fileExists(atPath: configPath.path))

        let configContent = try String(contentsOf: configPath, encoding: .utf8)
        XCTAssertTrue(configContent.contains(workspacePath))
    }

    func testCreateWorkspaceCreatesHieroglyphsDirectory() throws {
        let workspacePath = fixtureRoot.appendingPathComponent("test-workspace").path
        let configDir = fixtureRoot.appendingPathComponent(".hieroglyphs").path
        let service = WorkspaceService(fileManager: fileManager)

        try service.createWorkspace(at: workspacePath, configDirectory: configDir)

        let hieroglyphsDir = fixtureRoot.appendingPathComponent(".hieroglyphs")
        XCTAssertTrue(fileManager.fileExists(atPath: hieroglyphsDir.path))
    }

    // MARK: - initializeWorkspaceFiles() Tests

    func testInitializeWorkspaceFiles() throws {
        let workspacePath = fixtureRoot.appendingPathComponent("init-workspace")
        try fileManager.createDirectory(
            at: workspacePath,
            withIntermediateDirectories: true
        )

        let service = WorkspaceService(fileManager: fileManager)
        try service.initializeWorkspaceFiles(at: workspacePath.path)

        let claudePath = workspacePath.appendingPathComponent("CLAUDE.md")
        let agentPath = workspacePath.appendingPathComponent("AGENT.md")

        XCTAssertTrue(fileManager.fileExists(atPath: claudePath.path))
        XCTAssertTrue(fileManager.fileExists(atPath: agentPath.path))

        let claudeContent = try String(contentsOf: claudePath, encoding: .utf8)
        let agentContent = try String(contentsOf: agentPath, encoding: .utf8)

        XCTAssertFalse(claudeContent.isEmpty)
        XCTAssertFalse(agentContent.isEmpty)
        XCTAssertTrue(claudeContent.contains("Hieroglyphs"))
        XCTAssertTrue(agentContent.contains("frontmatter"))
    }

    // MARK: - createProject() Tests

    func testCreateProject() throws {
        try createFixtureWorkspace()

        let service = WorkspaceService(fileManager: fileManager)
        let project = try service.createProject(
            title: "New Project",
            description: "A test project",
            tags: ["test", "demo"],
            sourceDirectory: nil,
            at: workspaceURL.path
        )

        XCTAssertEqual(project.title, "New Project")
        XCTAssertEqual(project.description, "A test project")
        XCTAssertEqual(project.tags, ["test", "demo"])
        XCTAssertEqual(project.slug, "new-project")

        let projectPath = workspaceURL.appendingPathComponent("new-project")
        XCTAssertTrue(fileManager.fileExists(atPath: projectPath.path))

        let projectFilePath = projectPath.appendingPathComponent("project.md")
        XCTAssertTrue(fileManager.fileExists(atPath: projectFilePath.path))

        let content = try String(contentsOf: projectFilePath, encoding: .utf8)
        XCTAssertTrue(content.contains("title: New Project"))
        XCTAssertTrue(content.contains("description: A test project"))
        XCTAssertTrue(content.contains("id: \(project.id.uuidString)"))
        XCTAssertTrue(content.contains("slug: new-project"))
    }

    func testCreateProjectGeneratesSlug() throws {
        try createFixtureWorkspace()

        let service = WorkspaceService(fileManager: fileManager)
        let project = try service.createProject(
            title: "My Test Project!!!",
            description: "",
            tags: [],
            sourceDirectory: nil,
            at: workspaceURL.path
        )

        XCTAssertEqual(project.slug, "my-test-project")

        let projectPath = workspaceURL.appendingPathComponent("my-test-project")
        XCTAssertTrue(fileManager.fileExists(atPath: projectPath.path))
    }

    func testCreateProjectSetsTimestamps() throws {
        try createFixtureWorkspace()

        let beforeCreate = Date()
        let service = WorkspaceService(fileManager: fileManager)
        let project = try service.createProject(
            title: "Timestamped Project",
            description: "",
            tags: [],
            sourceDirectory: nil,
            at: workspaceURL.path
        )
        let afterCreate = Date()

        XCTAssertGreaterThanOrEqual(project.created, beforeCreate)
        XCTAssertLessThanOrEqual(project.created, afterCreate)
        XCTAssertEqual(project.created, project.updated)
    }

    func testCreateProjectWritesFrontmatter() throws {
        try createFixtureWorkspace()

        let service = WorkspaceService(fileManager: fileManager)
        let project = try service.createProject(
            title: "Frontmatter Test",
            description: "Testing frontmatter",
            tags: ["yaml", "test"],
            sourceDirectory: nil,
            at: workspaceURL.path
        )

        let projectFilePath = workspaceURL
            .appendingPathComponent(project.slug)
            .appendingPathComponent("project.md")
        let content = try String(contentsOf: projectFilePath, encoding: .utf8)

        let parsed = try FrontmatterParser.parse(content)
        XCTAssertEqual(parsed.frontmatter["title"] as? String, "Frontmatter Test")
        XCTAssertEqual(parsed.frontmatter["description"] as? String, "Testing frontmatter")
        XCTAssertEqual(parsed.frontmatter["tags"] as? [String], ["yaml", "test"])
        XCTAssertEqual(parsed.frontmatter["slug"] as? String, "frontmatter-test")
    }

    // MARK: - createCard() Tests

    func testCreateCard() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "11111111-1111-1111-1111-111111111111",
            title: "Test Project"
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project").path
        let service = WorkspaceService(fileManager: fileManager)
        let card = try service.createCard(
            title: "New Card",
            type: .feature,
            status: .inProgress,
            priority: .high,
            tags: ["urgent"],
            body: "This is the card body.",
            projectPath: projectPath
        )

        XCTAssertEqual(card.title, "New Card")
        XCTAssertEqual(card.type, .feature)
        XCTAssertEqual(card.status, .inProgress)
        XCTAssertEqual(card.priority, .high)
        XCTAssertEqual(card.tags, ["urgent"])
        XCTAssertEqual(card.body, "This is the card body.")
        XCTAssertEqual(card.slug, "new-card")

        let cardPath = workspaceURL
            .appendingPathComponent("test-project/cards/new-card")
        XCTAssertTrue(fileManager.fileExists(atPath: cardPath.path))

        let cardFilePath = cardPath.appendingPathComponent("card.md")
        XCTAssertTrue(fileManager.fileExists(atPath: cardFilePath.path))

        let content = try String(contentsOf: cardFilePath, encoding: .utf8)
        XCTAssertTrue(content.contains("title: New Card"))
        XCTAssertTrue(content.contains("type: feature"))
        XCTAssertTrue(content.contains("This is the card body."))
    }

    func testCreateCardCreatesCardsDirectory() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "empty-project",
            id: "22222222-2222-2222-2222-222222222222",
            title: "Empty Project"
        )

        let projectPath = workspaceURL.appendingPathComponent("empty-project").path
        let cardsPath = workspaceURL.appendingPathComponent("empty-project/cards")

        XCTAssertFalse(fileManager.fileExists(atPath: cardsPath.path))

        let service = WorkspaceService(fileManager: fileManager)
        _ = try service.createCard(
            title: "First Card",
            type: .task,
            status: .backlog,
            priority: .medium,
            tags: [],
            body: "",
            projectPath: projectPath
        )

        XCTAssertTrue(fileManager.fileExists(atPath: cardsPath.path))
    }

    func testCreateCardGeneratesSlug() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "33333333-3333-3333-3333-333333333333",
            title: "Test Project"
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project").path
        let service = WorkspaceService(fileManager: fileManager)
        let card = try service.createCard(
            title: "Fix Bug #42!!!",
            type: .bug,
            status: .backlog,
            priority: .medium,
            tags: [],
            body: "",
            projectPath: projectPath
        )

        XCTAssertEqual(card.slug, "fix-bug-42")

        let cardPath = workspaceURL
            .appendingPathComponent("test-project/cards/fix-bug-42")
        XCTAssertTrue(fileManager.fileExists(atPath: cardPath.path))
    }

    func testCreateCardSetsTimestamps() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "44444444-4444-4444-4444-444444444444",
            title: "Test Project"
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project").path
        let beforeCreate = Date()
        let service = WorkspaceService(fileManager: fileManager)
        let card = try service.createCard(
            title: "Timestamped Card",
            type: .task,
            status: .backlog,
            priority: .medium,
            tags: [],
            body: "",
            projectPath: projectPath
        )
        let afterCreate = Date()

        XCTAssertGreaterThanOrEqual(card.created, beforeCreate)
        XCTAssertLessThanOrEqual(card.created, afterCreate)
        XCTAssertEqual(card.created, card.updated)
    }

    func testCreateCardWritesFrontmatterAndBody() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "55555555-5555-5555-5555-555555555555",
            title: "Test Project"
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project").path
        let service = WorkspaceService(fileManager: fileManager)
        _ = try service.createCard(
            title: "Full Card",
            type: .feature,
            status: .done,
            priority: .low,
            tags: ["complete"],
            body: "Card body content.",
            projectPath: projectPath
        )

        let cardFilePath = workspaceURL
            .appendingPathComponent("test-project/cards/full-card/card.md")
        let content = try String(contentsOf: cardFilePath, encoding: .utf8)

        let parsed = try FrontmatterParser.parse(content)
        XCTAssertEqual(parsed.frontmatter["title"] as? String, "Full Card")
        XCTAssertEqual(parsed.frontmatter["type"] as? String, "feature")
        XCTAssertEqual(parsed.frontmatter["status"] as? String, "done")
        XCTAssertEqual(parsed.frontmatter["priority"] as? String, "low")
        XCTAssertEqual(parsed.frontmatter["tags"] as? [String], ["complete"])
        XCTAssertEqual(parsed.body.trimmingCharacters(in: .whitespacesAndNewlines), "Card body content.")
    }

    // MARK: - updateProject() Tests

    func testUpdateProject() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "update-test",
            id: "66666666-6666-6666-6666-666666666666",
            title: "Original Title",
            description: "Original description",
            tags: ["old"]
        )

        let service = WorkspaceService(fileManager: fileManager)

        let updatedProject = Project(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            title: "Updated Title",
            description: "Updated description",
            tags: ["new", "updated"],
            created: Date(),
            updated: Date(),
            slug: "update-test",
            sourceDirectory: nil
        )

        try service.updateProject(updatedProject, at: workspaceURL.path)

        let projectFilePath = workspaceURL
            .appendingPathComponent("update-test/project.md")
        let content = try String(contentsOf: projectFilePath, encoding: .utf8)

        XCTAssertTrue(content.contains("title: Updated Title"))
        XCTAssertTrue(content.contains("description: Updated description"))
        XCTAssertTrue(content.contains("new"))
        XCTAssertTrue(content.contains("updated"))
    }

    func testUpdateProjectPreservesUnknownFields() throws {
        try createFixtureWorkspace()

        let projectDir = workspaceURL.appendingPathComponent("preserve-test")
        try fileManager.createDirectory(at: projectDir, withIntermediateDirectories: true)

        let originalContent = """
        ---
        id: 77777777-7777-7777-7777-777777777777
        title: Original
        description: Test
        tags: []
        created: 2026-01-01T10:00:00Z
        updated: 2026-01-01T10:00:00Z
        slug: preserve-test
        custom_field: custom_value
        another_field: 123
        ---
        """
        try originalContent.write(
            to: projectDir.appendingPathComponent("project.md"),
            atomically: true,
            encoding: .utf8
        )

        let service = WorkspaceService(fileManager: fileManager)
        let updatedProject = Project(
            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            title: "Updated",
            description: "Changed",
            tags: ["new"],
            created: Date(),
            updated: Date(),
            slug: "preserve-test",
            sourceDirectory: nil
        )

        try service.updateProject(updatedProject, at: workspaceURL.path)

        let projectFilePath = projectDir.appendingPathComponent("project.md")
        let content = try String(contentsOf: projectFilePath, encoding: .utf8)
        let parsed = try FrontmatterParser.parse(content)

        XCTAssertEqual(parsed.frontmatter["title"] as? String, "Updated")
        XCTAssertEqual(parsed.frontmatter["description"] as? String, "Changed")
        XCTAssertEqual(parsed.frontmatter["custom_field"] as? String, "custom_value")
        XCTAssertEqual(parsed.frontmatter["another_field"] as? Int, 123)
    }

    func testUpdateProjectUpdatesTimestamp() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "timestamp-test",
            id: "88888888-8888-8888-8888-888888888888",
            title: "Test",
            created: "2026-01-01T10:00:00Z",
            updated: "2026-01-01T10:00:00Z"
        )

        let service = WorkspaceService(fileManager: fileManager)
        let project = Project(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            title: "Test",
            description: "",
            tags: [],
            created: ISO8601DateFormatter().date(from: "2026-01-01T10:00:00Z")!,
            updated: Date(),
            slug: "timestamp-test",
            sourceDirectory: nil
        )

        try service.updateProject(project, at: workspaceURL.path)

        let projectFilePath = workspaceURL
            .appendingPathComponent("timestamp-test/project.md")
        let content = try String(contentsOf: projectFilePath, encoding: .utf8)
        let parsed = try FrontmatterParser.parse(content)

        let createdString = parsed.frontmatter["created"] as? String
        let updatedString = parsed.frontmatter["updated"] as? String
        XCTAssertNotNil(createdString)
        XCTAssertNotNil(updatedString)

        XCTAssertEqual(createdString, "2026-01-01T10:00:00Z")
        XCTAssertNotEqual(updatedString, "2026-01-01T10:00:00Z")

        let formatter = ISO8601DateFormatter()
        let updatedDate = formatter.date(from: updatedString!)
        XCTAssertNotNil(updatedDate)
    }

    func testUpdateProjectNotFound() throws {
        try createFixtureWorkspace()

        let service = WorkspaceService(fileManager: fileManager)
        let project = Project(
            id: UUID(),
            title: "Nonexistent",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "nonexistent",
            sourceDirectory: nil
        )

        XCTAssertThrowsError(try service.updateProject(project, at: workspaceURL.path)) { error in
            guard let workspaceError = error as? WorkspaceService.WorkspaceError else {
                XCTFail("Expected WorkspaceError")
                return
            }
            if case .projectNotFound = workspaceError {
                // Expected
            } else {
                XCTFail("Expected projectNotFound error")
            }
        }
    }

    // MARK: - updateCard() Tests

    func testUpdateCard() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "99999999-9999-9999-9999-999999999999",
            title: "Test Project"
        )
        try createCard(
            projectSlug: "test-project",
            cardSlug: "update-card",
            id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            title: "Original Card",
            type: "task",
            status: "backlog",
            priority: "medium",
            body: "Original body."
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project").path
        let service = WorkspaceService(fileManager: fileManager)

        let updatedCard = Card(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            title: "Updated Card",
            type: .bug,
            status: .done,
            priority: .high,
            tags: ["updated"],
            created: Date(),
            updated: Date(),
            slug: "update-card",
            body: "Updated body."
        )

        try service.updateCard(updatedCard, projectPath: projectPath)

        let cardFilePath = workspaceURL
            .appendingPathComponent("test-project/cards/update-card/card.md")
        let content = try String(contentsOf: cardFilePath, encoding: .utf8)

        XCTAssertTrue(content.contains("title: Updated Card"))
        XCTAssertTrue(content.contains("type: bug"))
        XCTAssertTrue(content.contains("status: done"))
        XCTAssertTrue(content.contains("priority: high"))
        XCTAssertTrue(content.contains("Updated body."))
    }

    func testUpdateCardPreservesUnknownFields() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
            title: "Test Project"
        )

        let cardDir = workspaceURL
            .appendingPathComponent("test-project/cards/preserve-card")
        try fileManager.createDirectory(at: cardDir, withIntermediateDirectories: true)

        let originalContent = """
        ---
        id: cccccccc-cccc-cccc-cccc-cccccccccccc
        title: Original
        type: task
        status: backlog
        priority: medium
        tags: []
        created: 2026-01-01T10:00:00Z
        updated: 2026-01-01T10:00:00Z
        slug: preserve-card
        custom_field: custom_value
        extra_data: 456
        ---

        Original body.
        """
        try originalContent.write(
            to: cardDir.appendingPathComponent("card.md"),
            atomically: true,
            encoding: .utf8
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project").path
        let service = WorkspaceService(fileManager: fileManager)

        let updatedCard = Card(
            id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            title: "Updated",
            type: .feature,
            status: .inProgress,
            priority: .low,
            tags: ["new"],
            created: Date(),
            updated: Date(),
            slug: "preserve-card",
            body: "Updated body."
        )

        try service.updateCard(updatedCard, projectPath: projectPath)

        let cardFilePath = cardDir.appendingPathComponent("card.md")
        let content = try String(contentsOf: cardFilePath, encoding: .utf8)
        let parsed = try FrontmatterParser.parse(content)

        XCTAssertEqual(parsed.frontmatter["title"] as? String, "Updated")
        XCTAssertEqual(parsed.frontmatter["type"] as? String, "feature")
        XCTAssertEqual(parsed.frontmatter["custom_field"] as? String, "custom_value")
        XCTAssertEqual(parsed.frontmatter["extra_data"] as? Int, 456)
        XCTAssertEqual(
            parsed.body.trimmingCharacters(in: .whitespacesAndNewlines),
            "Updated body."
        )
    }

    func testUpdateCardNotFound() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "dddddddd-dddd-dddd-dddd-dddddddddddd",
            title: "Test Project"
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project").path
        let service = WorkspaceService(fileManager: fileManager)

        let card = Card(
            id: UUID(),
            title: "Nonexistent",
            type: .task,
            status: .backlog,
            priority: .medium,
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "nonexistent",
            body: ""
        )

        XCTAssertThrowsError(try service.updateCard(card, projectPath: projectPath)) { error in
            guard let workspaceError = error as? WorkspaceService.WorkspaceError else {
                XCTFail("Expected WorkspaceError")
                return
            }
            if case .cardNotFound = workspaceError {
                // Expected
            } else {
                XCTFail("Expected cardNotFound error")
            }
        }
    }

    // MARK: - deleteProject() Tests

    func testDeleteProject() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "delete-me",
            id: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
            title: "Delete Me"
        )

        let projectPath = workspaceURL.appendingPathComponent("delete-me").path
        XCTAssertTrue(fileManager.fileExists(atPath: projectPath))

        let service = WorkspaceService(fileManager: fileManager)
        try service.deleteProject(at: projectPath)

        XCTAssertFalse(fileManager.fileExists(atPath: projectPath))
    }

    func testDeleteProjectNotFound() throws {
        try createFixtureWorkspace()

        let service = WorkspaceService(fileManager: fileManager)
        let nonexistentPath = workspaceURL.appendingPathComponent("nonexistent").path

        XCTAssertThrowsError(try service.deleteProject(at: nonexistentPath)) { error in
            guard let workspaceError = error as? WorkspaceService.WorkspaceError else {
                XCTFail("Expected WorkspaceError")
                return
            }
            if case .projectNotFound = workspaceError {
                // Expected
            } else {
                XCTFail("Expected projectNotFound error")
            }
        }
    }

    // MARK: - deleteCard() Tests

    func testDeleteCard() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "ffffffff-ffff-ffff-ffff-ffffffffffff",
            title: "Test Project"
        )
        try createCard(
            projectSlug: "test-project",
            cardSlug: "delete-me",
            id: "00000000-0000-0000-0000-000000000000",
            title: "Delete Me"
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project").path
        let cardPath = workspaceURL
            .appendingPathComponent("test-project/cards/delete-me").path

        XCTAssertTrue(fileManager.fileExists(atPath: cardPath))

        let service = WorkspaceService(fileManager: fileManager)
        try service.deleteCard(slug: "delete-me", projectPath: projectPath)

        XCTAssertFalse(fileManager.fileExists(atPath: cardPath))
    }

    func testDeleteCardNotFound() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "test-project",
            id: "11111111-1111-1111-1111-111111111111",
            title: "Test Project"
        )

        let projectPath = workspaceURL.appendingPathComponent("test-project").path
        let service = WorkspaceService(fileManager: fileManager)

        XCTAssertThrowsError(try service.deleteCard(slug: "nonexistent", projectPath: projectPath)) { error in
            guard let workspaceError = error as? WorkspaceService.WorkspaceError else {
                XCTFail("Expected WorkspaceError")
                return
            }
            if case .cardNotFound = workspaceError {
                // Expected
            } else {
                XCTFail("Expected cardNotFound error")
            }
        }
    }

    // MARK: - source_directory Tests

    func testCreateProjectWithSourceDirectory() throws {
        try createFixtureWorkspace()

        let service = WorkspaceService(fileManager: fileManager)
        let sourceDir = "/Users/test/code/project"
        let project = try service.createProject(
            title: "Project with Source",
            description: "Has source directory",
            tags: [],
            sourceDirectory: sourceDir,
            at: workspaceURL.path
        )

        XCTAssertEqual(project.sourceDirectory, sourceDir)

        let projectFilePath = workspaceURL
            .appendingPathComponent(project.slug)
            .appendingPathComponent("project.md")
        let content = try String(contentsOf: projectFilePath, encoding: .utf8)

        XCTAssertTrue(content.contains("source_directory: \(sourceDir)"))
    }

    func testCreateProjectWithoutSourceDirectory() throws {
        try createFixtureWorkspace()

        let service = WorkspaceService(fileManager: fileManager)
        let project = try service.createProject(
            title: "Project without Source",
            description: "No source directory",
            tags: [],
            sourceDirectory: nil,
            at: workspaceURL.path
        )

        XCTAssertNil(project.sourceDirectory)

        let projectFilePath = workspaceURL
            .appendingPathComponent(project.slug)
            .appendingPathComponent("project.md")
        let content = try String(contentsOf: projectFilePath, encoding: .utf8)

        XCTAssertFalse(content.contains("source_directory"))
    }

    func testLoadProjectWithSourceDirectory() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "with-source",
            id: "12345678-1234-1234-1234-123456789012",
            title: "With Source",
            sourceDirectory: "/path/to/source"
        )

        let service = WorkspaceService(fileManager: fileManager)
        let projects = try service.loadProjects(from: workspaceURL.path)

        XCTAssertEqual(projects.count, 1)
        let project = projects[0]
        XCTAssertEqual(project.sourceDirectory, "/path/to/source")
    }

    func testLoadProjectWithoutSourceDirectory() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "without-source",
            id: "98765432-9876-9876-9876-987654321098",
            title: "Without Source"
        )

        let service = WorkspaceService(fileManager: fileManager)
        let projects = try service.loadProjects(from: workspaceURL.path)

        XCTAssertEqual(projects.count, 1)
        let project = projects[0]
        XCTAssertNil(project.sourceDirectory)
    }

    func testUpdateProjectToAddSourceDirectory() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "add-source",
            id: "aaaaaaaa-1111-2222-3333-bbbbbbbbbbbb",
            title: "Add Source"
        )

        let service = WorkspaceService(fileManager: fileManager)

        let updatedProject = Project(
            id: UUID(uuidString: "aaaaaaaa-1111-2222-3333-bbbbbbbbbbbb")!,
            title: "Add Source",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "add-source",
            sourceDirectory: "/new/source/path"
        )

        try service.updateProject(updatedProject, at: workspaceURL.path)

        let projectFilePath = workspaceURL
            .appendingPathComponent("add-source/project.md")
        let content = try String(contentsOf: projectFilePath, encoding: .utf8)
        let parsed = try FrontmatterParser.parse(content)

        XCTAssertEqual(parsed.frontmatter["source_directory"] as? String, "/new/source/path")
    }

    func testUpdateProjectToRemoveSourceDirectory() throws {
        try createFixtureWorkspace()
        try createProject(
            slug: "remove-source",
            id: "cccccccc-4444-5555-6666-dddddddddddd",
            title: "Remove Source",
            sourceDirectory: "/old/source/path"
        )

        let service = WorkspaceService(fileManager: fileManager)

        let updatedProject = Project(
            id: UUID(uuidString: "cccccccc-4444-5555-6666-dddddddddddd")!,
            title: "Remove Source",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "remove-source",
            sourceDirectory: nil
        )

        try service.updateProject(updatedProject, at: workspaceURL.path)

        let projectFilePath = workspaceURL
            .appendingPathComponent("remove-source/project.md")
        let content = try String(contentsOf: projectFilePath, encoding: .utf8)
        let parsed = try FrontmatterParser.parse(content)

        XCTAssertNil(parsed.frontmatter["source_directory"])
    }

    func testUpdateProjectPreservesSourceDirectoryWithUnknownFields() throws {
        try createFixtureWorkspace()

        let projectDir = workspaceURL.appendingPathComponent("preserve-all")
        try fileManager.createDirectory(at: projectDir, withIntermediateDirectories: true)

        let originalContent = """
        ---
        id: eeeeeeee-7777-8888-9999-ffffffffffff
        title: Original
        description: Test
        tags: []
        created: 2026-01-01T10:00:00Z
        updated: 2026-01-01T10:00:00Z
        slug: preserve-all
        source_directory: /original/source
        custom_field: custom_value
        ---
        """
        try originalContent.write(
            to: projectDir.appendingPathComponent("project.md"),
            atomically: true,
            encoding: .utf8
        )

        let service = WorkspaceService(fileManager: fileManager)
        let updatedProject = Project(
            id: UUID(uuidString: "eeeeeeee-7777-8888-9999-ffffffffffff")!,
            title: "Updated",
            description: "Changed",
            tags: ["new"],
            created: Date(),
            updated: Date(),
            slug: "preserve-all",
            sourceDirectory: "/updated/source"
        )

        try service.updateProject(updatedProject, at: workspaceURL.path)

        let projectFilePath = projectDir.appendingPathComponent("project.md")
        let content = try String(contentsOf: projectFilePath, encoding: .utf8)
        let parsed = try FrontmatterParser.parse(content)

        XCTAssertEqual(parsed.frontmatter["title"] as? String, "Updated")
        XCTAssertEqual(parsed.frontmatter["source_directory"] as? String, "/updated/source")
        XCTAssertEqual(parsed.frontmatter["custom_field"] as? String, "custom_value")
    }
}
