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

    // MARK: - performSearch() Tests

    @MainActor
    func testPerformSearchWithResults() async {
        let mockWorkspaceService = MockWorkspaceService()
        let mockSearchService = MockSearchService()

        mockSearchService.mockResults = [
            SearchResult(
                title: "Test Card",
                path: "/workspace/project/cards/test/card.md",
                resultType: .card,
                projectSlug: "project",
                cardSlug: "test"
            )
        ]

        let viewModel = HieroglyphsVM(
            workspaceService: mockWorkspaceService,
            searchService: mockSearchService
        )
        viewModel.loadWorkspace()

        viewModel.performSearch(query: "test")

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertEqual(viewModel.searchResults[0].title, "Test Card")
    }

    @MainActor
    func testPerformSearchWithEmptyQuery() {
        let mockWorkspaceService = MockWorkspaceService()
        let mockSearchService = MockSearchService()

        let viewModel = HieroglyphsVM(
            workspaceService: mockWorkspaceService,
            searchService: mockSearchService
        )
        viewModel.loadWorkspace()

        viewModel.performSearch(query: "")

        XCTAssertEqual(viewModel.searchResults.count, 0)
    }

    @MainActor
    func testPerformSearchWithNilSearchService() {
        let mockWorkspaceService = MockWorkspaceService()

        let viewModel = HieroglyphsVM(
            workspaceService: mockWorkspaceService,
            searchService: nil
        )
        viewModel.loadWorkspace()

        viewModel.performSearch(query: "test")

        XCTAssertEqual(viewModel.searchResults.count, 0)
    }

    @MainActor
    func testPerformSearchWithNilWorkspacePath() {
        let mockWorkspaceService = MockWorkspaceService()
        let mockSearchService = MockSearchService()

        let viewModel = HieroglyphsVM(
            workspaceService: mockWorkspaceService,
            searchService: mockSearchService
        )

        viewModel.performSearch(query: "test")

        XCTAssertEqual(viewModel.searchResults.count, 0)
    }

    // MARK: - navigateToSearchResult() Tests

    @MainActor
    func testNavigateToProjectResult() {
        let mockWorkspaceService = MockWorkspaceService()

        let viewModel = HieroglyphsVM(workspaceService: mockWorkspaceService)
        viewModel.loadWorkspace()

        let result = SearchResult(
            title: "Mock Project 1",
            path: "/workspace/mock-project-1/project.md",
            resultType: .project,
            projectSlug: "mock-project-1"
        )

        viewModel.navigateToSearchResult(result)

        XCTAssertNotNil(viewModel.selectedProject)
        XCTAssertEqual(viewModel.selectedProject?.slug, "mock-project-1")
    }

    @MainActor
    func testNavigateToCardResult() {
        let mockWorkspaceService = MockWorkspaceService()

        let viewModel = HieroglyphsVM(workspaceService: mockWorkspaceService)
        viewModel.loadWorkspace()

        let result = SearchResult(
            title: "Mock Card 1",
            path: "/workspace/mock-project-1/cards/mock-card-1/card.md",
            resultType: .card,
            projectSlug: "mock-project-1",
            cardSlug: "mock-card-1"
        )

        viewModel.navigateToSearchResult(result)

        XCTAssertNotNil(viewModel.selectedProject)
        XCTAssertEqual(viewModel.selectedProject?.slug, "mock-project-1")
    }

    @MainActor
    func testNavigateToSearchResultWithNilSlug() {
        let mockWorkspaceService = MockWorkspaceService()

        let viewModel = HieroglyphsVM(workspaceService: mockWorkspaceService)
        viewModel.loadWorkspace()

        let result = SearchResult(
            title: "Invalid Result",
            path: "/workspace/invalid/project.md",
            resultType: .project,
            projectSlug: nil
        )

        viewModel.navigateToSearchResult(result)

        XCTAssertNil(viewModel.selectedProject)
    }

    // MARK: - initializeWorkspace() Tests

    @MainActor
    func testInitializeWorkspaceSuccess() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnCreateWorkspace = false
        mockService.shouldThrowOnInitializeWorkspaceFiles = false
        mockService.shouldThrowOnLoadConfig = false

        let viewModel = HieroglyphsVM(workspaceService: mockService)

        XCTAssertNil(viewModel.workspacePath)

        viewModel.initializeWorkspace(at: "/new/workspace")

        XCTAssertEqual(viewModel.workspacePath, "/mock/workspace")
        XCTAssertFalse(viewModel.projects.isEmpty)
    }

    @MainActor
    func testInitializeWorkspaceCreateFailure() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnCreateWorkspace = true

        let viewModel = HieroglyphsVM(workspaceService: mockService)

        viewModel.initializeWorkspace(at: "/new/workspace")

        XCTAssertNil(viewModel.workspacePath)
        XCTAssertTrue(viewModel.projects.isEmpty)
    }

    @MainActor
    func testInitializeWorkspaceFilesFailure() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnCreateWorkspace = false
        mockService.shouldThrowOnInitializeWorkspaceFiles = true

        let viewModel = HieroglyphsVM(workspaceService: mockService)

        viewModel.initializeWorkspace(at: "/new/workspace")

        XCTAssertNil(viewModel.workspacePath)
        XCTAssertTrue(viewModel.projects.isEmpty)
    }

    // MARK: - Sheet Presentation Tests

    @MainActor
    func testShowNewProjectSheet() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)

        XCTAssertFalse(viewModel.showingNewProjectSheet)

        viewModel.showNewProjectSheet()

        XCTAssertTrue(viewModel.showingNewProjectSheet)
    }

    @MainActor
    func testShowNewCardSheet() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)

        XCTAssertFalse(viewModel.showingNewCardSheet)

        viewModel.showNewCardSheet()

        XCTAssertTrue(viewModel.showingNewCardSheet)
    }

    // MARK: - deleteSelectedItem() Tests

    @MainActor
    func testDeleteSelectedCard() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadCards = false

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        viewModel.selectProject(viewModel.projects.first)
        viewModel.loadCards()

        let cardToDelete = viewModel.cards.first
        viewModel.selectedCard = cardToDelete

        XCTAssertNotNil(viewModel.selectedCard)

        viewModel.deleteSelectedItem()

        XCTAssertNil(viewModel.selectedCard)
        XCTAssertTrue(mockService.deleteCardWasCalled)
    }

    @MainActor
    func testDeleteSelectedProject() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        viewModel.selectProject(viewModel.projects.first)

        XCTAssertNotNil(viewModel.selectedProject)
        XCTAssertNil(viewModel.selectedCard)

        viewModel.deleteSelectedItem()

        XCTAssertNil(viewModel.selectedProject)
        XCTAssertTrue(mockService.deleteProjectWasCalled)
    }

    @MainActor
    func testDeleteSelectedItemWithNilWorkspacePath() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)

        XCTAssertNil(viewModel.workspacePath)

        viewModel.deleteSelectedItem()

        XCTAssertFalse(mockService.deleteCardWasCalled)
        XCTAssertFalse(mockService.deleteProjectWasCalled)
    }

    @MainActor
    func testDeleteSelectedItemWithNothingSelected() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        XCTAssertNil(viewModel.selectedProject)
        XCTAssertNil(viewModel.selectedCard)

        viewModel.deleteSelectedItem()

        XCTAssertFalse(mockService.deleteCardWasCalled)
        XCTAssertFalse(mockService.deleteProjectWasCalled)
    }

    // MARK: - requestSearchFocus() Tests

    @MainActor
    func testRequestSearchFocus() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)

        XCTAssertFalse(viewModel.focusSearch)

        viewModel.requestSearchFocus()

        XCTAssertTrue(viewModel.focusSearch)
    }
}

// MARK: - Mock Workspace Service

final class MockSearchService: SearchProviding {
    var shouldReturnResults = true
    var mockResults: [SearchResult] = []

    func performSearch(
        query: String,
        scope: String,
        completion: @escaping @Sendable ([SearchResult]) -> Void
    ) {
        if shouldReturnResults {
            completion(mockResults)
        } else {
            completion([])
        }
    }
}

final class MockWorkspaceService: WorkspaceProviding {
    var shouldThrowOnLoadConfig = false
    var shouldThrowOnLoadProjects = false
    var shouldThrowOnLoadCards = false
    var shouldThrowOnCreateProject = false
    var shouldThrowOnCreateCard = false
    var shouldThrowOnUpdateCard = false
    var shouldThrowOnCreateWorkspace = false
    var shouldThrowOnInitializeWorkspaceFiles = false

    var updateCardWasCalled = false
    var lastUpdatedCard: Card?
    var deleteCardWasCalled = false
    var deleteProjectWasCalled = false

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
        if shouldThrowOnCreateWorkspace {
            throw WorkspaceService.WorkspaceError.directoryCreationFailed(
                NSError(domain: "MockWorkspaceService", code: 1)
            )
        }
    }

    func initializeWorkspaceFiles(at workspacePath: String) throws {
        if shouldThrowOnInitializeWorkspaceFiles {
            throw WorkspaceService.WorkspaceError.fileWriteFailed(
                NSError(domain: "MockWorkspaceService", code: 2)
            )
        }
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
        deleteProjectWasCalled = true
    }

    func deleteCard(slug: String, projectPath: String) throws {
        deleteCardWasCalled = true
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
