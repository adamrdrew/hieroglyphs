import XCTest
@testable import Hieroglyphs

final class HieroglyphsVMTests: XCTestCase {

    // MARK: - loadWorkspace() Tests

    @MainActor
    func testLoadWorkspaceSuccess() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadProjects = false

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        XCTAssertEqual(viewModel.workspacePath, "/mock/workspace")
        XCTAssertEqual(viewModel.projects.count, 2)
        XCTAssertEqual(viewModel.projects[0].title, "Mock Project 1")
        XCTAssertEqual(viewModel.projects[1].title, "Mock Project 2")
    }

    @MainActor
    func testLoadWorkspaceConfigFailure() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = true

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        XCTAssertNil(viewModel.workspacePath)
        XCTAssertTrue(viewModel.projects.isEmpty)
    }

    @MainActor
    func testLoadWorkspaceProjectsFailure() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadProjects = true

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        XCTAssertNil(viewModel.workspacePath)
        XCTAssertTrue(viewModel.projects.isEmpty)
    }

    // MARK: - createProject() Tests

    @MainActor
    func testCreateProject() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnCreateProject = false

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        let initialCount = viewModel.projects.count
        viewModel.createProject(
            title: "New Project",
            description: "Description",
            tags: ["tag1"]
        )

        XCTAssertEqual(viewModel.projects.count, initialCount + 1)
        XCTAssertTrue(
            viewModel.projects.contains { $0.title == "New Project" }
        )
    }

    @MainActor
    func testCreateProjectWithNilWorkspacePath() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)

        viewModel.createProject(
            title: "New Project",
            description: "Description",
            tags: []
        )

        XCTAssertTrue(viewModel.projects.isEmpty)
    }

    @MainActor
    func testCreateProjectFailure() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnCreateProject = true

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        let initialCount = viewModel.projects.count
        viewModel.createProject(
            title: "New Project",
            description: "Description",
            tags: []
        )

        XCTAssertEqual(viewModel.projects.count, initialCount)
    }

    // MARK: - selectProject() Tests

    @MainActor
    func testSelectProject() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        XCTAssertNil(viewModel.selectedProject)

        let firstProject = viewModel.projects.first
        viewModel.selectProject(firstProject)

        XCTAssertEqual(viewModel.selectedProject, firstProject)
    }

    @MainActor
    func testSelectProjectNil() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        viewModel.selectProject(viewModel.projects.first)
        XCTAssertNotNil(viewModel.selectedProject)

        viewModel.selectProject(nil)
        XCTAssertNil(viewModel.selectedProject)
    }

    // MARK: - loadCards() Tests

    @MainActor
    func testLoadCardsSuccess() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadProjects = false
        mockService.shouldThrowOnLoadCards = false

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        viewModel.selectProject(viewModel.projects.first)

        viewModel.loadCards()

        XCTAssertEqual(viewModel.cards.count, 2)
        XCTAssertEqual(viewModel.cards[0].title, "Mock Card 1")
        XCTAssertEqual(viewModel.cards[1].title, "Mock Card 2")
    }

    @MainActor
    func testLoadCardsWithNilSelectedProject() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        XCTAssertNil(viewModel.selectedProject)

        viewModel.loadCards()

        XCTAssertTrue(viewModel.cards.isEmpty)
    }

    @MainActor
    func testLoadCardsError() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadProjects = false
        mockService.shouldThrowOnLoadCards = true

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        viewModel.selectProject(viewModel.projects.first)

        viewModel.loadCards()

        XCTAssertTrue(viewModel.cards.isEmpty)
    }

    // MARK: - createCard() Tests

    @MainActor
    func testCreateCardSuccess() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadProjects = false
        mockService.shouldThrowOnLoadCards = false
        mockService.shouldThrowOnCreateCard = false

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        viewModel.selectProject(viewModel.projects.first)

        viewModel.loadCards()
        let initialCount = viewModel.cards.count

        viewModel.createCard(
            title: "New Card",
            type: .task,
            status: .todo,
            priority: .medium,
            tags: ["test"],
            body: "Test body"
        )

        XCTAssertEqual(viewModel.cards.count, initialCount + 1)
        XCTAssertTrue(
            viewModel.cards.contains { $0.title == "New Card" }
        )
    }

    @MainActor
    func testCreateCardWithNilSelectedProject() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)

        XCTAssertNil(viewModel.selectedProject)

        viewModel.createCard(
            title: "New Card",
            type: .task,
            status: .todo,
            priority: .medium,
            tags: [],
            body: ""
        )

        XCTAssertTrue(viewModel.cards.isEmpty)
    }

    @MainActor
    func testCreateCardError() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadProjects = false
        mockService.shouldThrowOnLoadCards = false
        mockService.shouldThrowOnCreateCard = true

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        viewModel.selectProject(viewModel.projects.first)

        viewModel.loadCards()
        let initialCount = viewModel.cards.count

        viewModel.createCard(
            title: "New Card",
            type: .task,
            status: .todo,
            priority: .medium,
            tags: [],
            body: ""
        )

        XCTAssertEqual(viewModel.cards.count, initialCount)
    }
}

// MARK: - Mock Workspace Service

final class MockWorkspaceService: WorkspaceProviding {
    var shouldThrowOnLoadConfig = false
    var shouldThrowOnLoadProjects = false
    var shouldThrowOnLoadCards = false
    var shouldThrowOnCreateProject = false
    var shouldThrowOnCreateCard = false

    private var mockProjects: [Project] = []
    private var mockCards: [Card] = []
    private var createdProjectCount = 0

    func loadWorkspaceConfig(from configPath: String?) throws -> WorkspaceConfig {
        if shouldThrowOnLoadConfig {
            throw WorkspaceService.WorkspaceError.configNotFound
        }
        return WorkspaceConfig(workspacePath: "/mock/workspace")
    }

    func loadProjects(from workspacePath: String) throws -> [Project] {
        if shouldThrowOnLoadProjects {
            throw WorkspaceService.WorkspaceError.invalidDirectory
        }

        return mockProjects + [
            Project(
                id: UUID(),
                title: "Mock Project 1",
                description: "Description 1",
                tags: [],
                created: Date(),
                updated: Date(),
                slug: "mock-project-1"
            ),
            Project(
                id: UUID(),
                title: "Mock Project 2",
                description: "Description 2",
                tags: [],
                created: Date(),
                updated: Date(),
                slug: "mock-project-2"
            )
        ]
    }

    func loadCards(from projectPath: String, for project: Project) throws -> [Card] {
        if shouldThrowOnLoadCards {
            throw WorkspaceService.WorkspaceError.invalidDirectory
        }

        return mockCards + [
            Card(
                id: UUID(),
                title: "Mock Card 1",
                type: .task,
                status: .todo,
                priority: .medium,
                tags: [],
                created: Date(),
                updated: Date(),
                slug: "mock-card-1",
                body: "Mock body 1"
            ),
            Card(
                id: UUID(),
                title: "Mock Card 2",
                type: .bug,
                status: .inProgress,
                priority: .high,
                tags: ["bug"],
                created: Date(),
                updated: Date(),
                slug: "mock-card-2",
                body: "Mock body 2"
            )
        ]
    }

    func createWorkspace(at path: String, configDirectory: String?) throws {
        // Not used in these tests
    }

    func initializeWorkspaceFiles(at workspacePath: String) throws {
        // Not used in these tests
    }

    func createProject(
        title: String,
        description: String,
        tags: [String],
        at workspacePath: String
    ) throws -> Project {
        if shouldThrowOnCreateProject {
            throw WorkspaceService.WorkspaceError.invalidDirectory
        }

        let newProject = Project(
            id: UUID(),
            title: title,
            description: description,
            tags: tags,
            created: Date(),
            updated: Date(),
            slug: title.lowercased().replacingOccurrences(of: " ", with: "-")
        )

        mockProjects.append(newProject)
        createdProjectCount += 1
        return newProject
    }

    func createCard(
        title: String,
        type: CardType,
        status: CardStatus,
        priority: Priority,
        tags: [String],
        body: String,
        projectPath: String
    ) throws -> Card {
        if shouldThrowOnCreateCard {
            throw WorkspaceService.WorkspaceError.invalidDirectory
        }

        let newCard = Card(
            id: UUID(),
            title: title,
            type: type,
            status: status,
            priority: priority,
            tags: tags,
            created: Date(),
            updated: Date(),
            slug: title.lowercased().replacingOccurrences(of: " ", with: "-"),
            body: body
        )

        mockCards.append(newCard)
        return newCard
    }

    func updateProject(_ project: Project, at workspacePath: String) throws {
        // Not used in these tests
    }

    func updateCard(_ card: Card, projectPath: String) throws {
        // Not used in these tests
    }

    func deleteProject(at projectPath: String) throws {
        // Not used in these tests
    }

    func deleteCard(slug: String, projectPath: String) throws {
        // Not used in these tests
    }
}
