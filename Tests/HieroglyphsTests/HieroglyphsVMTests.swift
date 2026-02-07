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

    // MARK: - updateCard() Tests

    @MainActor
    func testUpdateCardSuccess() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadProjects = false
        mockService.shouldThrowOnLoadCards = false
        mockService.shouldThrowOnUpdateCard = false

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        viewModel.selectProject(viewModel.projects.first)

        viewModel.loadCards()
        XCTAssertFalse(viewModel.cards.isEmpty)

        let cardToUpdate = viewModel.cards[0]
        let updatedCard = Card(
            id: cardToUpdate.id,
            title: "Updated Title",
            type: cardToUpdate.type,
            status: cardToUpdate.status,
            priority: cardToUpdate.priority,
            tags: cardToUpdate.tags,
            created: cardToUpdate.created,
            updated: Date(),
            slug: cardToUpdate.slug,
            body: cardToUpdate.body
        )

        viewModel.updateCard(updatedCard)

        XCTAssertTrue(mockService.updateCardWasCalled)
        XCTAssertEqual(mockService.lastUpdatedCard?.title, "Updated Title")
    }

    @MainActor
    func testUpdateCardWithNilWorkspacePath() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)

        XCTAssertNil(viewModel.workspacePath)

        let card = Card(
            id: UUID(),
            title: "Test Card",
            type: .task,
            status: .todo,
            priority: .medium,
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test-card",
            body: ""
        )

        viewModel.updateCard(card)

        XCTAssertFalse(mockService.updateCardWasCalled)
    }

    @MainActor
    func testUpdateCardWithNilSelectedProject() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        XCTAssertNotNil(viewModel.workspacePath)
        XCTAssertNil(viewModel.selectedProject)

        let card = Card(
            id: UUID(),
            title: "Test Card",
            type: .task,
            status: .todo,
            priority: .medium,
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test-card",
            body: ""
        )

        viewModel.updateCard(card)

        XCTAssertFalse(mockService.updateCardWasCalled)
    }

    // MARK: - File Watching Tests

    @MainActor
    func testStartWatchingCalledOnLoadWorkspace() {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()
        mockService.shouldThrowOnLoadConfig = false

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher
        )
        viewModel.loadWorkspace()

        XCTAssertTrue(mockWatcher.startWatchingCalled)
        XCTAssertEqual(mockWatcher.watchedPath, "/mock/workspace")
    }

    @MainActor
    func testStartWatchingNotCalledOnLoadWorkspaceFailure() {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()
        mockService.shouldThrowOnLoadConfig = true

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher
        )
        viewModel.loadWorkspace()

        XCTAssertFalse(mockWatcher.startWatchingCalled)
    }

    @MainActor
    func testStopWatching() {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher
        )
        viewModel.loadWorkspace()

        XCTAssertTrue(mockWatcher.startWatchingCalled)

        viewModel.stopWatching()

        XCTAssertTrue(mockWatcher.stopWatchingCalled)
    }

    @MainActor
    func testFileChangeTriggersProjectReload() {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()
        mockService.shouldThrowOnLoadConfig = false

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher
        )
        viewModel.loadWorkspace()

        let initialProjectCount = viewModel.projects.count

        let projectURL = URL(
            fileURLWithPath: "/mock/workspace/test-project/project.md"
        )
        mockWatcher.simulateChange(url: projectURL)

        XCTAssertEqual(viewModel.projects.count, initialProjectCount)
    }

    @MainActor
    func testFileChangeTriggersCardReload() {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadCards = false

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher
        )
        viewModel.loadWorkspace()
        viewModel.selectProject(viewModel.projects.first)
        viewModel.loadCards()

        let initialCardCount = viewModel.cards.count

        guard let selectedProject = viewModel.selectedProject else {
            XCTFail("No project selected")
            return
        }

        let cardURL = URL(
            fileURLWithPath: "/mock/workspace/\(selectedProject.slug)/cards/test-card/card.md"
        )
        mockWatcher.simulateChange(url: cardURL)

        XCTAssertEqual(viewModel.cards.count, initialCardCount)
    }

    @MainActor
    func testFileChangeOutsideSelectedProjectIgnored() {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadCards = false

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher
        )
        viewModel.loadWorkspace()
        viewModel.selectProject(viewModel.projects.first)
        viewModel.loadCards()

        let initialCardCount = viewModel.cards.count

        let cardURL = URL(
            fileURLWithPath: "/mock/workspace/different-project/cards/test-card/card.md"
        )
        mockWatcher.simulateChange(url: cardURL)

        XCTAssertEqual(viewModel.cards.count, initialCardCount)
    }

    // MARK: - Tag Reconciliation Tests

    @MainActor
    func testProjectChangeTriggersTagReconciliation() {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()
        let mockReconciler = MockTagReconciler()
        mockService.shouldThrowOnLoadConfig = false

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher,
            tagReconciler: mockReconciler
        )
        viewModel.loadWorkspace()

        let projectURL = URL(
            fileURLWithPath: "/mock/workspace/mock-project-1/project.md"
        )
        mockWatcher.simulateChange(url: projectURL)

        XCTAssertTrue(mockReconciler.reconcileTagsCalled)
        XCTAssertEqual(
            mockReconciler.lastPath,
            "/mock/workspace/mock-project-1/project.md"
        )
    }

    @MainActor
    func testCardChangeTriggersTagReconciliation() {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()
        let mockReconciler = MockTagReconciler()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadCards = false

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher,
            tagReconciler: mockReconciler
        )
        viewModel.loadWorkspace()
        viewModel.selectProject(viewModel.projects.first)
        viewModel.loadCards()

        guard let selectedProject = viewModel.selectedProject else {
            XCTFail("No project selected")
            return
        }

        let cardURL = URL(
            fileURLWithPath: "/mock/workspace/\(selectedProject.slug)/cards/mock-card-1/card.md"
        )
        mockWatcher.simulateChange(url: cardURL)

        XCTAssertTrue(mockReconciler.reconcileTagsCalled)
        XCTAssertTrue(
            mockReconciler.lastPath?.contains("card.md") ?? false
        )
    }

    @MainActor
    func testTagReconciliationNotCalledWhenReconcilerNil() {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()
        mockService.shouldThrowOnLoadConfig = false

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher,
            tagReconciler: nil
        )
        viewModel.loadWorkspace()

        let projectURL = URL(
            fileURLWithPath: "/mock/workspace/mock-project-1/project.md"
        )
        mockWatcher.simulateChange(url: projectURL)

        // Should not crash when reconciler is nil
        XCTAssertEqual(viewModel.projects.count, 2)
    }
}

// MARK: - Mock Workspace Service

final class MockWorkspaceService: WorkspaceProviding {
    var shouldThrowOnLoadConfig = false
    var shouldThrowOnLoadProjects = false
    var shouldThrowOnLoadCards = false
    var shouldThrowOnCreateProject = false
    var shouldThrowOnCreateCard = false
    var shouldThrowOnUpdateCard = false

    var updateCardWasCalled = false
    var lastUpdatedCard: Card?

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
        if shouldThrowOnUpdateCard {
            throw WorkspaceService.WorkspaceError.cardNotFound
        }

        updateCardWasCalled = true
        lastUpdatedCard = card
    }

    func deleteProject(at projectPath: String) throws {
        // Not used in these tests
    }

    func deleteCard(slug: String, projectPath: String) throws {
        // Not used in these tests
    }
}

// MARK: - Mock File Watcher

final class MockFileWatcher: FileWatching {
    var startWatchingCalled = false
    var stopWatchingCalled = false
    var watchedPath: String?
    var onChange: ((URL) -> Void)?

    func startWatching(path: String, onChange: @escaping (URL) -> Void) {
        startWatchingCalled = true
        watchedPath = path
        self.onChange = onChange
    }

    func stopWatching() {
        stopWatchingCalled = true
        onChange = nil
    }

    func simulateChange(url: URL) {
        onChange?(url)
    }
}

// MARK: - Mock Tag Reconciler

final class MockTagReconciler: TagReconciling {
    var reconcileTagsCalled = false
    var lastTags: [String]?
    var lastPath: String?

    func reconcileTags(for tags: [String], at path: String) {
        reconcileTagsCalled = true
        lastTags = tags
        lastPath = path
    }
}
