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

    // MARK: - selectSection() and selectedProject Tests

    @MainActor
    func testSelectSectionCards() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        XCTAssertNil(viewModel.selectedSection)
        XCTAssertNil(viewModel.selectedProject)

        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }

        viewModel.selectSection(.cards(firstProject))

        XCTAssertNotNil(viewModel.selectedSection)
        XCTAssertEqual(viewModel.selectedProject, firstProject)
    }

    @MainActor
    func testSelectSectionPlans() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }

        viewModel.selectSection(.plans(firstProject))

        XCTAssertNotNil(viewModel.selectedSection)
        XCTAssertEqual(viewModel.selectedProject, firstProject)
    }

    @MainActor
    func testSelectSectionPhases() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }

        viewModel.selectSection(.phases(firstProject))

        XCTAssertNotNil(viewModel.selectedSection)
        XCTAssertEqual(viewModel.selectedProject, firstProject)
    }

    @MainActor
    func testSelectSectionNil() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }

        viewModel.selectSection(.cards(firstProject))
        XCTAssertNotNil(viewModel.selectedSection)
        XCTAssertNotNil(viewModel.selectedProject)

        viewModel.selectSection(nil)
        XCTAssertNil(viewModel.selectedSection)
        XCTAssertNil(viewModel.selectedProject)
    }

    @MainActor
    func testComputedSelectedProjectExtractsFromAllSectionTypes() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()

        guard let project1 = viewModel.projects.first,
              let project2 = viewModel.projects.last else {
            XCTFail("Not enough projects available")
            return
        }

        viewModel.selectSection(.cards(project1))
        XCTAssertEqual(viewModel.selectedProject?.id, project1.id)

        viewModel.selectSection(.plans(project2))
        XCTAssertEqual(viewModel.selectedProject?.id, project2.id)

        viewModel.selectSection(.phases(project1))
        XCTAssertEqual(viewModel.selectedProject?.id, project1.id)
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
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))

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
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))

        viewModel.loadCards()

        XCTAssertTrue(viewModel.cards.isEmpty)
    }

    @MainActor
    func testLoadCardsLoadingStateTransitions() {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadProjects = false
        mockService.shouldThrowOnLoadCards = false

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))

        // Verify initial state
        XCTAssertFalse(viewModel.isLoadingCards)

        // Load cards successfully
        viewModel.loadCards()

        // Verify state is false after successful load
        XCTAssertFalse(viewModel.isLoadingCards)
        XCTAssertEqual(viewModel.cards.count, 2)

        // Test error path
        mockService.shouldThrowOnLoadCards = true
        viewModel.loadCards()

        // Verify state is false after error
        XCTAssertFalse(viewModel.isLoadingCards)
        XCTAssertTrue(viewModel.cards.isEmpty)

        // Test guard failure with nil project
        viewModel.selectSection(nil)
        viewModel.loadCards()

        // Verify state is false after guard failure
        XCTAssertFalse(viewModel.isLoadingCards)
        XCTAssertTrue(viewModel.cards.isEmpty)
    }

    @MainActor
    func testLoadCardsIngestsFromUshabtiWhenSourceDirectoryIsSet() {
        let mockService = MockWorkspaceService()
        mockService.ingestCardsReturnCount = 2

        let projectWithSource = Project(
            id: UUID(),
            title: "Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "project",
            sourceDirectory: "/source"
        )

        mockService.mockProjects = [projectWithSource]

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        viewModel.selectSection(.cards(projectWithSource))

        mockService.ingestCardsWasCalled = false

        viewModel.loadCards()

        XCTAssertTrue(mockService.ingestCardsWasCalled)
    }

    @MainActor
    func testLoadCardsDoesNotIngestWhenSourceDirectoryIsNil() {
        let mockService = MockWorkspaceService()

        let projectWithoutSource = Project(
            id: UUID(),
            title: "Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "project",
            sourceDirectory: nil
        )

        mockService.mockProjects = [projectWithoutSource]

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        viewModel.selectSection(.cards(projectWithoutSource))

        mockService.ingestCardsWasCalled = false

        viewModel.loadCards()

        XCTAssertFalse(mockService.ingestCardsWasCalled)
    }

    @MainActor
    func testLoadCardsLoadsCardsAfterIngestion() {
        let mockService = MockWorkspaceService()
        mockService.ingestCardsReturnCount = 1

        let projectWithSource = Project(
            id: UUID(),
            title: "Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "project",
            sourceDirectory: "/source"
        )

        mockService.mockProjects = [projectWithSource]

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        viewModel.selectSection(.cards(projectWithSource))

        viewModel.loadCards()

        XCTAssertTrue(mockService.ingestCardsWasCalled)
        XCTAssertEqual(viewModel.cards.count, 2)
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
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))

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
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))

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
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))

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

    // MARK: - updateCardDebounced() Tests

    @MainActor
    func testUpdateCardDebouncedCoalescesMultipleCalls() async throws {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadProjects = false
        mockService.shouldThrowOnLoadCards = false
        mockService.shouldThrowOnUpdateCard = false

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))
        viewModel.loadCards()

        let cardToUpdate = viewModel.cards[0]

        mockService.updateCardWasCalled = false

        viewModel.updateCardDebounced(cardToUpdate)
        viewModel.updateCardDebounced(cardToUpdate)
        viewModel.updateCardDebounced(cardToUpdate)

        XCTAssertFalse(
            mockService.updateCardWasCalled,
            "Service should not be called immediately"
        )

        try await Task.sleep(for: .seconds(2.0))

        XCTAssertTrue(
            mockService.updateCardWasCalled,
            "Service should be called after delay"
        )
        XCTAssertEqual(
            mockService.lastUpdatedCard?.id,
            cardToUpdate.id,
            "Most recent card should be updated"
        )
    }

    @MainActor
    func testFlushPendingCardUpdatesExecutesImmediately() async throws {
        let mockService = MockWorkspaceService()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadProjects = false
        mockService.shouldThrowOnLoadCards = false
        mockService.shouldThrowOnUpdateCard = false

        let viewModel = HieroglyphsVM(workspaceService: mockService)
        viewModel.loadWorkspace()
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))
        viewModel.loadCards()

        let cardToUpdate = viewModel.cards[0]

        mockService.updateCardWasCalled = false

        viewModel.updateCardDebounced(cardToUpdate)

        XCTAssertFalse(
            mockService.updateCardWasCalled,
            "Service should not be called before flush"
        )

        viewModel.flushPendingCardUpdates()

        XCTAssertTrue(
            mockService.updateCardWasCalled,
            "Service should be called immediately on flush"
        )

        try await Task.sleep(for: .seconds(2.0))

        XCTAssertTrue(
            mockService.updateCardWasCalled,
            "Service should remain called after delay"
        )
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
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))
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
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))
        viewModel.loadCards()

        let initialCardCount = viewModel.cards.count

        let cardURL = URL(
            fileURLWithPath: "/mock/workspace/different-project/cards/test-card/card.md"
        )
        mockWatcher.simulateChange(url: cardURL)

        XCTAssertEqual(viewModel.cards.count, initialCardCount)
    }

    // MARK: - Phases Watching Tests

    @MainActor
    func testStartWatchingStartsPhasesWatchingWhenSourceDirectorySet() throws {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()
        mockService.shouldThrowOnLoadConfig = false
        mockService.shouldThrowOnLoadProjects = false

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let phasesDir = tempDir.appendingPathComponent(".ushabti/phases")
        try FileManager.default.createDirectory(
            at: phasesDir,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let projectWithSource = Project(
            id: UUID(),
            title: "Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "project",
            sourceDirectory: tempDir.path
        )
        mockService.mockProjects = [projectWithSource]

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher
        )
        viewModel.loadWorkspace()

        // Select project with source directory
        if let project = viewModel.projects.first(where: { $0.sourceDirectory != nil }) {
            viewModel.selectedSection = .phases(project)
            viewModel.startWatching()

            XCTAssertTrue(mockWatcher.startWatchingPhasesCalled)
            XCTAssertNotNil(mockWatcher.watchedPhasesPath)
        } else {
            XCTFail("No project with source directory found")
        }
    }

    @MainActor
    func testStartWatchingDoesNotStartPhasesWatchingWhenNoSourceDirectory() {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()
        mockService.shouldThrowOnLoadConfig = false

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher
        )
        viewModel.loadWorkspace()

        // Select project without source directory (first mock project has no source directory)
        if let project = viewModel.projects.first(where: { $0.sourceDirectory == nil }) {
            viewModel.selectedSection = .cards(project)
            viewModel.startWatching()

            XCTAssertFalse(mockWatcher.startWatchingPhasesCalled)
        } else {
            XCTFail("Expected project without source directory")
        }
    }

    @MainActor
    func testStopWatchingStopsPhasesWatching() {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()
        mockService.shouldThrowOnLoadConfig = false

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher
        )
        viewModel.loadWorkspace()

        viewModel.stopWatching()

        XCTAssertTrue(mockWatcher.stopWatchingCalled)
        XCTAssertTrue(mockWatcher.stopWatchingPhasesCalled)
    }

    @MainActor
    func testRestartPhasesWatchingRestartsCorrectly() throws {
        let mockService = MockWorkspaceService()
        let mockWatcher = MockFileWatcher()
        mockService.shouldThrowOnLoadConfig = false

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let phasesDir = tempDir.appendingPathComponent(".ushabti/phases")
        try FileManager.default.createDirectory(
            at: phasesDir,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let projectWithSource = Project(
            id: UUID(),
            title: "Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "project",
            sourceDirectory: tempDir.path
        )
        mockService.mockProjects = [projectWithSource]

        let viewModel = HieroglyphsVM(
            workspaceService: mockService,
            fileWatcher: mockWatcher
        )
        viewModel.loadWorkspace()

        // Select project with source directory
        if let project = viewModel.projects.first(where: { $0.sourceDirectory != nil }) {
            viewModel.selectedSection = .phases(project)
            viewModel.restartPhasesWatching()

            XCTAssertTrue(mockWatcher.stopWatchingPhasesCalled)
            XCTAssertTrue(mockWatcher.startWatchingPhasesCalled)
        } else {
            XCTFail("No project with source directory found")
        }
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
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))
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
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))
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
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))

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

    @MainActor
    func testDeleteSelectedCardCleansUpPlanSymlinks() {
        let mockWorkspace = MockWorkspaceService()
        let mockPlan = MockPlanService()
        mockWorkspace.shouldThrowOnLoadConfig = false
        mockWorkspace.shouldThrowOnLoadCards = false

        let viewModel = HieroglyphsVM(
            workspaceService: mockWorkspace,
            planService: mockPlan
        )
        viewModel.loadWorkspace()
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))
        viewModel.loadCards()

        let cardToDelete = viewModel.cards.first
        viewModel.selectedCard = cardToDelete

        XCTAssertNotNil(viewModel.selectedCard)
        XCTAssertFalse(mockPlan.removeCardWasCalled)

        viewModel.deleteSelectedItem()

        XCTAssertTrue(mockPlan.removeCardWasCalled)
        XCTAssertEqual(mockPlan.lastRemovedCardSlug, cardToDelete?.slug)
        XCTAssertTrue(mockWorkspace.deleteCardWasCalled)
        XCTAssertNil(viewModel.selectedCard)
    }

    @MainActor
    func testDeleteSelectedCardWorksWhenPlanServiceIsNil() {
        let mockWorkspace = MockWorkspaceService()
        mockWorkspace.shouldThrowOnLoadConfig = false
        mockWorkspace.shouldThrowOnLoadCards = false

        let viewModel = HieroglyphsVM(
            workspaceService: mockWorkspace,
            planService: nil
        )
        viewModel.loadWorkspace()
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))
        viewModel.loadCards()

        let cardToDelete = viewModel.cards.first
        viewModel.selectedCard = cardToDelete

        XCTAssertNotNil(viewModel.selectedCard)

        viewModel.deleteSelectedItem()

        XCTAssertTrue(mockWorkspace.deleteCardWasCalled)
        XCTAssertNil(viewModel.selectedCard)
    }

    @MainActor
    func testDeleteSelectedCardContinuesWhenSymlinkCleanupFails() {
        let mockWorkspace = MockWorkspaceService()
        let mockPlan = MockPlanService()
        mockWorkspace.shouldThrowOnLoadConfig = false
        mockWorkspace.shouldThrowOnLoadCards = false
        mockPlan.shouldThrowOnRemoveCardSymlinks = true

        let viewModel = HieroglyphsVM(
            workspaceService: mockWorkspace,
            planService: mockPlan
        )
        viewModel.loadWorkspace()
        guard let firstProject = viewModel.projects.first else {
            XCTFail("No projects available")
            return
        }
        viewModel.selectSection(.cards(firstProject))
        viewModel.loadCards()

        let cardToDelete = viewModel.cards.first
        viewModel.selectedCard = cardToDelete

        XCTAssertNotNil(viewModel.selectedCard)

        viewModel.deleteSelectedItem()

        XCTAssertTrue(mockPlan.removeCardWasCalled)
        XCTAssertTrue(mockWorkspace.deleteCardWasCalled)
        XCTAssertNil(viewModel.selectedCard)
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

    var mockProjects: [Project] = []
    var mockCards: [Card] = []
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
                slug: "mock-project-1",
                sourceDirectory: nil
            ),
            Project(
                id: UUID(),
                title: "Mock Project 2",
                description: "Description 2",
                tags: [],
                created: Date(),
                updated: Date(),
                slug: "mock-project-2",
                sourceDirectory: nil
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
        sourceDirectory: String?,
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
            slug: title.lowercased().replacingOccurrences(of: " ", with: "-"),
            sourceDirectory: sourceDirectory
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

    var ingestCardsWasCalled = false
    var ingestCardsReturnCount = 0

    func ingestCardsFromUshabti(
        projectPath: String,
        sourceDirectory: String?
    ) throws -> Int {
        ingestCardsWasCalled = true
        return ingestCardsReturnCount
    }
}

// MARK: - Mock File Watcher

final class MockFileWatcher: FileWatching {
    var startWatchingCalled = false
    var stopWatchingCalled = false
    var watchedPath: String?
    var onChange: ((URL) -> Void)?
    var startWatchingPhasesCalled = false
    var stopWatchingPhasesCalled = false
    var watchedPhasesPath: String?
    var onPhasesChange: ((URL) -> Void)?

    func startWatching(path: String, onChange: @escaping (URL) -> Void) {
        startWatchingCalled = true
        watchedPath = path
        self.onChange = onChange
    }

    func stopWatching() {
        stopWatchingCalled = true
        onChange = nil
    }

    func startWatchingPhases(path: String, onChange: @escaping (URL) -> Void) {
        startWatchingPhasesCalled = true
        watchedPhasesPath = path
        self.onPhasesChange = onChange
    }

    func stopWatchingPhases() {
        stopWatchingPhasesCalled = true
        onPhasesChange = nil
    }

    func simulateChange(url: URL) {
        onChange?(url)
    }

    func simulatePhasesChange(url: URL) {
        onPhasesChange?(url)
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

// MARK: - Mock Phase Service

final class MockPhaseService: PhaseProviding {
    var shouldThrowOnLoadPhases = false
    var mockPhases: [Phase] = []

    func loadPhases(from sourceDirectory: String) throws -> [Phase] {
        if shouldThrowOnLoadPhases {
            throw NSError(
                domain: "MockPhaseService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Mock error"]
            )
        }
        return mockPhases
    }
}

// MARK: - Mock Plan Service

final class MockPlanService: PlanProviding {
    var shouldThrowOnLoadPlans = false
    var shouldThrowOnCreatePlan = false
    var shouldThrowOnUpdatePlan = false
    var shouldThrowOnAddCardToPlan = false
    var shouldThrowOnRemoveCardFromPlan = false
    var shouldThrowOnUpdatePlanStatus = false
    var shouldThrowOnWritePhasePrompt = false
    var shouldThrowOnRemoveCardSymlinks = false

    var mockPlans: [Plan] = []
    var removedCardSlugs: [String] = []
    var removeCardWasCalled = false
    var lastRemovedCardSlug: String?
    var lastRemovedCardProjectPath: String?

    func loadPlans(projectPath: String) throws -> [Plan] {
        if shouldThrowOnLoadPlans {
            throw NSError(
                domain: "MockPlanService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Mock error"]
            )
        }
        return mockPlans
    }

    func createPlan(title: String, number: Int, projectPath: String) throws -> Plan {
        if shouldThrowOnCreatePlan {
            throw NSError(
                domain: "MockPlanService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Mock error"]
            )
        }
        let plan = Plan(
            id: UUID(),
            title: title,
            number: number,
            slug: "\(String(format: "%04d", number))-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))",
            status: .planning,
            created: Date(),
            updated: Date(),
            linkedCardSlugs: [],
            phasePrompt: ""
        )
        mockPlans.append(plan)
        return plan
    }

    func updatePlan(_ plan: Plan, projectPath: String) throws {
        if shouldThrowOnUpdatePlan {
            throw NSError(
                domain: "MockPlanService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Mock error"]
            )
        }
    }

    func addCardToPlan(cardSlug: String, planSlug: String, projectPath: String) throws {
        if shouldThrowOnAddCardToPlan {
            throw NSError(
                domain: "MockPlanService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Mock error"]
            )
        }
    }

    func removeCardFromPlan(cardSlug: String, planSlug: String, projectPath: String) throws {
        if shouldThrowOnRemoveCardFromPlan {
            throw NSError(
                domain: "MockPlanService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Mock error"]
            )
        }
    }

    func updatePlanStatus(plan: Plan, status: PlanStatus, projectPath: String) throws {
        if shouldThrowOnUpdatePlanStatus {
            throw NSError(
                domain: "MockPlanService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Mock error"]
            )
        }
    }

    func writePhasePrompt(planSlug: String, content: String, projectPath: String) throws {
        if shouldThrowOnWritePhasePrompt {
            throw NSError(
                domain: "MockPlanService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Mock error"]
            )
        }
    }

    func removeCardFromPlans(cardSlug: String, projectPath: String) throws {
        removeCardWasCalled = true
        lastRemovedCardSlug = cardSlug
        lastRemovedCardProjectPath = projectPath
        removedCardSlugs.append(cardSlug)

        if shouldThrowOnRemoveCardSymlinks {
            throw NSError(
                domain: "MockPlanService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Mock error"]
            )
        }
    }

    func findNextPlanNumber(projectPath: String) throws -> Int {
        if mockPlans.isEmpty {
            return 1
        }
        let maxNumber = mockPlans.map { $0.number }.max() ?? 0
        return maxNumber + 1
    }
}

// MARK: - loadPhases() Tests

extension HieroglyphsVMTests {

    @MainActor
    func testLoadPhasesWithValidSourceDirectory() {
        let mockWorkspace = MockWorkspaceService()
        let mockPhases = MockPhaseService()

        let testProject = Project(
            id: UUID(),
            title: "Test Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test-project",
            sourceDirectory: "/test/source"
        )

        mockPhases.mockPhases = [
            Phase(
                number: 1,
                slug: "0001-test",
                title: "Test Phase",
                status: .planned,
                intent: "Intent",
                steps: [],
                reviewNotes: ""
            )
        ]

        let viewModel = HieroglyphsVM(
            workspaceService: mockWorkspace,
            phaseService: mockPhases
        )
        viewModel.loadWorkspace()

        mockWorkspace.mockProjects = [testProject]
        viewModel.selectedSection = .phases(testProject)
        viewModel.loadPhases()

        XCTAssertEqual(viewModel.phases.count, 1)
        XCTAssertEqual(viewModel.phases.first?.title, "Test Phase")
    }

    @MainActor
    func testLoadPhasesWithNilSourceDirectory() {
        let mockWorkspace = MockWorkspaceService()
        let mockPhases = MockPhaseService()

        let testProject = Project(
            id: UUID(),
            title: "Test Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test-project",
            sourceDirectory: nil
        )

        let viewModel = HieroglyphsVM(
            workspaceService: mockWorkspace,
            phaseService: mockPhases
        )
        viewModel.loadWorkspace()

        mockWorkspace.mockProjects = [testProject]
        viewModel.selectedSection = .phases(testProject)
        viewModel.loadPhases()

        XCTAssertTrue(viewModel.phases.isEmpty)
    }

    @MainActor
    func testLoadPhasesWithNoSelectedProject() {
        let mockWorkspace = MockWorkspaceService()
        let mockPhases = MockPhaseService()

        let viewModel = HieroglyphsVM(
            workspaceService: mockWorkspace,
            phaseService: mockPhases
        )

        viewModel.loadPhases()

        XCTAssertTrue(viewModel.phases.isEmpty)
    }

    @MainActor
    func testLoadPhasesHandlesServiceError() {
        let mockWorkspace = MockWorkspaceService()
        let mockPhases = MockPhaseService()

        let testProject = Project(
            id: UUID(),
            title: "Test Project",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "test-project",
            sourceDirectory: "/test/source"
        )

        mockPhases.shouldThrowOnLoadPhases = true

        let viewModel = HieroglyphsVM(
            workspaceService: mockWorkspace,
            phaseService: mockPhases
        )
        viewModel.loadWorkspace()

        mockWorkspace.mockProjects = [testProject]
        viewModel.selectedSection = .phases(testProject)
        viewModel.loadPhases()

        XCTAssertTrue(viewModel.phases.isEmpty)
    }

    // MARK: - showDoneAndArchived Toggle Tests

    @MainActor
    func testShowDoneAndArchivedDefaultValue() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)

        XCTAssertFalse(viewModel.showDoneAndArchived, "showDoneAndArchived should default to false")
    }

    @MainActor
    func testShowDoneAndArchivedToggle() {
        let mockService = MockWorkspaceService()
        let viewModel = HieroglyphsVM(workspaceService: mockService)

        viewModel.showDoneAndArchived = true
        XCTAssertTrue(viewModel.showDoneAndArchived, "showDoneAndArchived should be true after setting")

        viewModel.showDoneAndArchived = false
        XCTAssertFalse(viewModel.showDoneAndArchived, "showDoneAndArchived should be false after toggling back")
    }
}
