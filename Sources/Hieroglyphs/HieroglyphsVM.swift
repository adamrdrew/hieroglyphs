import SwiftUI
import Observation

/// Represents a selectable section in the sidebar.
///
/// Each section corresponds to a project and a specific view type
/// (cards, plans, or phases). This enables hierarchical navigation where
/// selecting a section determines both the project context and which
/// middle-column view to display.
enum SidebarSection: Hashable {
    case cards(Project)
    case plans(Project)
    case phases(Project)
}

/// ViewModel coordinating workspace state and UI selection.
///
/// Acts as the central coordinator between WorkspaceService and UI views.
/// Manages workspace path, project list, and selected project state.
/// Injected via @Environment for view access.
@Observable
@MainActor
final class HieroglyphsVM {
    var workspacePath: String?
    var projects: [Project] = []
    var selectedSection: SidebarSection?

    /// Computed property that extracts the project from any section variant.
    ///
    /// Returns the associated project for cards, plans, or phases sections.
    /// Returns nil if no section is selected.
    var selectedProject: Project? {
        switch selectedSection {
        case .cards(let project):
            return project
        case .plans(let project):
            return project
        case .phases(let project):
            return project
        case .none:
            return nil
        }
    }

    var cards: [Card] = []
    var selectedCard: Card?

    var searchText: String = ""
    var filterStatus: Set<CardStatus> = []
    var filterType: Set<CardType> = []
    var filterPriority: Set<Priority> = []
    var sortBy: CardSortOption = .updated
    var sortOrder: SortOrder = .forward

    var searchResults: [SearchResult] = []

    var showingNewProjectSheet: Bool = false
    var showingNewCardSheet: Bool = false
    var focusSearch: Bool = false

    private let workspaceService: WorkspaceProviding
    private let fileWatcher: FileWatching?
    private let tagReconciler: TagReconciling?
    private let searchService: SearchProviding?

    private let cardUpdateDebouncer = Debouncer(delay: 1.5)
    private var pendingCardUpdate: Card?
    private var lastDebouncedWritePath: String?

    init(
        workspaceService: WorkspaceProviding,
        fileWatcher: FileWatching? = nil,
        tagReconciler: TagReconciling? = nil,
        searchService: SearchProviding? = nil
    ) {
        self.workspaceService = workspaceService
        self.fileWatcher = fileWatcher
        self.tagReconciler = tagReconciler
        self.searchService = searchService
    }

    /// Initializes a new workspace at the specified path.
    ///
    /// Creates workspace directory, writes config, generates instructional files
    /// (CLAUDE.md and AGENT.md), and loads the workspace.
    ///
    /// - Parameter path: Absolute path to workspace directory
    func initializeWorkspace(at path: String) {
        do {
            try workspaceService.createWorkspace(at: path, configDirectory: nil)
            try workspaceService.initializeWorkspaceFiles(at: path)
            loadWorkspace()
        } catch {
            print("Failed to initialize workspace: \(error)")
        }
    }

    /// Loads workspace configuration and projects.
    ///
    /// Reads config from ~/.hieroglyphs/config.yaml, extracts workspace path,
    /// and loads all projects from the workspace directory. On error, logs to
    /// console and leaves workspacePath nil and projects empty.
    func loadWorkspace() {
        do {
            let config = try workspaceService.loadWorkspaceConfig(from: nil)
            self.workspacePath = config.workspacePath

            let loadedProjects = try workspaceService.loadProjects(
                from: config.workspacePath
            )
            self.projects = loadedProjects

            startWatching()
        } catch {
            print("Failed to load workspace: \(error)")
            self.workspacePath = nil
            self.projects = []
        }
    }

    /// Creates a new project and reloads the project list.
    ///
    /// - Parameters:
    ///   - title: Project title
    ///   - description: Project description
    ///   - tags: Project tags
    ///   - sourceDirectory: Optional path to source directory
    func createProject(
        title: String,
        description: String,
        tags: [String],
        sourceDirectory: String? = nil
    ) {
        guard let workspacePath else {
            print("Cannot create project: workspace path is nil")
            return
        }

        do {
            _ = try workspaceService.createProject(
                title: title,
                description: description,
                tags: tags,
                sourceDirectory: sourceDirectory,
                at: workspacePath
            )

            let reloadedProjects = try workspaceService.loadProjects(
                from: workspacePath
            )
            self.projects = reloadedProjects
        } catch {
            print("Failed to create project: \(error)")
        }
    }

    /// Updates an existing project and reloads the project list.
    ///
    /// - Parameter project: The updated project model
    func updateProject(_ project: Project) {
        guard let workspacePath else {
            print("Cannot update project: workspace path is nil")
            return
        }

        do {
            try workspaceService.updateProject(project, at: workspacePath)
            let reloadedProjects = try workspaceService.loadProjects(
                from: workspacePath
            )
            self.projects = reloadedProjects

            if let updatedProject = reloadedProjects.first(where: { $0.id == project.id }),
               let currentSection = selectedSection {
                switch currentSection {
                case .cards:
                    self.selectedSection = .cards(updatedProject)
                case .plans:
                    self.selectedSection = .plans(updatedProject)
                case .phases:
                    self.selectedSection = .phases(updatedProject)
                }
            }
        } catch {
            print("Failed to update project: \(error)")
        }
    }

    /// Updates the selected section.
    ///
    /// - Parameter section: The section to select
    func selectSection(_ section: SidebarSection?) {
        self.selectedSection = section
    }

    /// Loads cards for the currently selected project.
    ///
    /// Reads all cards from the selected project's cards/ directory and updates
    /// the cards property. On error, logs to console and leaves cards empty.
    func loadCards() {
        guard let selectedProject else {
            self.cards = []
            return
        }

        guard let workspacePath else {
            print("Cannot load cards: workspace path is nil")
            self.cards = []
            return
        }

        do {
            let projectPath = "\(workspacePath)/\(selectedProject.slug)"
            let loadedCards = try workspaceService.loadCards(
                from: projectPath,
                for: selectedProject
            )
            self.cards = loadedCards
        } catch {
            print("Failed to load cards: \(error)")
            self.cards = []
        }
    }

    /// Creates a new card and reloads the card list.
    ///
    /// - Parameters:
    ///   - title: Card title
    ///   - type: Card type
    ///   - status: Card status
    ///   - priority: Card priority
    ///   - tags: Card tags
    ///   - body: Markdown body content
    func createCard(
        title: String,
        type: CardType,
        status: CardStatus,
        priority: Priority,
        tags: [String],
        body: String
    ) {
        guard let selectedProject else {
            print("Cannot create card: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot create card: workspace path is nil")
            return
        }

        do {
            let projectPath = "\(workspacePath)/\(selectedProject.slug)"
            _ = try workspaceService.createCard(
                title: title,
                type: type,
                status: status,
                priority: priority,
                tags: tags,
                body: body,
                projectPath: projectPath
            )

            loadCards()
        } catch {
            print("Failed to create card: \(error)")
        }
    }

    /// Updates an existing card and reloads the card list.
    ///
    /// Writes immediately to disk. Use for discrete actions (picker changes,
    /// tag operations) that should persist immediately.
    ///
    /// - Parameter card: The card to update
    func updateCard(_ card: Card) {
        guard let selectedProject else {
            print("Cannot update card: no project selected")
            return
        }

        guard let workspacePath else {
            print("Cannot update card: workspace path is nil")
            return
        }

        do {
            let projectPath = "\(workspacePath)/\(selectedProject.slug)"
            try workspaceService.updateCard(card, projectPath: projectPath)
            lastDebouncedWritePath = nil
            loadCards()
        } catch {
            print("Failed to update card: \(error)")
        }
    }

    /// Updates an existing card with debouncing for continuous edits.
    ///
    /// Schedules write to occur after delay. Repeated calls coalesce into single
    /// write. Use for continuous typing (title, body) to avoid lag.
    ///
    /// - Parameter card: The card to update
    func updateCardDebounced(_ card: Card) {
        pendingCardUpdate = card

        cardUpdateDebouncer.schedule { [weak self] in
            guard let self else { return }
            guard let card = self.pendingCardUpdate else { return }
            guard let selectedProject = self.selectedProject else { return }
            guard let workspacePath = self.workspacePath else { return }

            let cardPath = "\(workspacePath)/\(selectedProject.slug)/cards/\(card.slug)/card.md"
            self.lastDebouncedWritePath = cardPath

            self.updateCard(card)
            self.pendingCardUpdate = nil
        }
    }

    /// Flushes pending debounced card updates immediately.
    ///
    /// Call before card deselection or app termination to ensure all edits
    /// are persisted to disk.
    func flushPendingCardUpdates() {
        cardUpdateDebouncer.flush()
    }

    /// Starts watching workspace for external file changes.
    ///
    /// Called automatically after successful workspace load. Monitors
    /// workspace directory for changes and triggers appropriate reloads.
    func startWatching() {
        guard let workspacePath else { return }

        fileWatcher?.startWatching(path: workspacePath) { [weak self] url in
            self?.handleFileChange(url: url)
        }
    }

    /// Stops watching workspace for external file changes.
    ///
    /// Called on deinit to clean up file monitoring resources.
    func stopWatching() {
        fileWatcher?.stopWatching()
    }

    private func handleFileChange(url: URL) {
        guard workspacePath != nil else { return }

        let path = url.path

        if path.contains("/project.md") {
            loadProjects()
            reconcileProjectTags(at: path)
        } else if path.contains("/cards/") || path.contains("/card.md") {
            if let selectedProject,
               path.contains("/\(selectedProject.slug)/") {
                if let lastWritePath = lastDebouncedWritePath,
                   path == lastWritePath {
                    lastDebouncedWritePath = nil
                    reconcileCardTags(at: path)
                    return
                }
                loadCards()
            }
            reconcileCardTags(at: path)
        }
    }

    private func loadProjects() {
        guard let workspacePath else { return }

        do {
            let loadedProjects = try workspaceService.loadProjects(
                from: workspacePath
            )
            self.projects = loadedProjects
        } catch {
            print("Failed to reload projects: \(error)")
        }
    }

    private func reconcileProjectTags(at path: String) {
        guard let tagReconciler else { return }

        do {
            let project = try extractProjectFromPath(path)
            tagReconciler.reconcileTags(for: project.tags, at: path)
        } catch {
            print("Failed to reconcile project tags: \(error)")
        }
    }

    private func reconcileCardTags(at path: String) {
        guard let tagReconciler else { return }

        do {
            let card = try extractCardFromPath(path)
            tagReconciler.reconcileTags(for: card.tags, at: path)
        } catch {
            print("Failed to reconcile card tags: \(error)")
        }
    }

    private func extractProjectFromPath(_ path: String) throws -> Project {
        guard let workspacePath else {
            throw NSError(
                domain: "HieroglyphsVM",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Workspace path is nil"]
            )
        }

        let allProjects = try workspaceService.loadProjects(from: workspacePath)
        guard let project = allProjects.first(where: { path.contains("/\($0.slug)/") }) else {
            throw NSError(
                domain: "HieroglyphsVM",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Project not found for path"]
            )
        }

        return project
    }

    private func extractCardFromPath(_ path: String) throws -> Card {
        guard let workspacePath else {
            throw NSError(
                domain: "HieroglyphsVM",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Workspace path is nil"]
            )
        }

        let project = try extractProjectFromPath(path)
        let projectPath = "\(workspacePath)/\(project.slug)"
        let allCards = try workspaceService.loadCards(from: projectPath, for: project)

        guard let card = allCards.first(where: { path.contains("/\($0.slug)/") }) else {
            throw NSError(
                domain: "HieroglyphsVM",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Card not found for path"]
            )
        }

        return card
    }

    /// Performs a Spotlight search across workspace files.
    ///
    /// Searches file content, titles, and tags for matches. Updates
    /// searchResults property with results. Clears results if query is empty.
    ///
    /// - Parameter query: Search query string
    func performSearch(query: String) {
        guard let searchService else {
            print("Cannot perform search: search service is nil")
            return
        }

        guard !query.isEmpty else {
            self.searchResults = []
            return
        }

        guard let workspacePath else {
            print("Cannot perform search: workspace path is nil")
            self.searchResults = []
            return
        }

        searchService.performSearch(
            query: query,
            scope: workspacePath
        ) { [weak self] results in
            Task { @MainActor in
                self?.searchResults = results
            }
        }
    }

    /// Navigates to a search result by setting selection state.
    ///
    /// For project results, sets selectedProject. For card results,
    /// sets selectedProject and selectedCard, loading cards if needed.
    ///
    /// - Parameter result: The search result to navigate to
    func navigateToSearchResult(_ result: SearchResult) {
        switch result.resultType {
        case .project:
            navigateToProject(slug: result.projectSlug)

        case .card:
            navigateToCard(
                projectSlug: result.projectSlug,
                cardSlug: result.cardSlug
            )
        }
    }

    private func navigateToProject(slug: String?) {
        guard let slug else { return }

        if let project = projects.first(where: { $0.slug == slug }) {
            self.selectedSection = .cards(project)
        }
    }

    private func navigateToCard(projectSlug: String?, cardSlug: String?) {
        guard let projectSlug, let cardSlug else { return }

        if let project = projects.first(where: { $0.slug == projectSlug }) {
            self.selectedSection = .cards(project)
            loadCards()

            if let card = cards.first(where: { $0.slug == cardSlug }) {
                self.selectedCard = card
            }
        }
    }

    /// Shows the New Project sheet.
    func showNewProjectSheet() {
        self.showingNewProjectSheet = true
    }

    /// Shows the New Card sheet.
    func showNewCardSheet() {
        self.showingNewCardSheet = true
    }

    /// Deletes the currently selected item (card or project).
    ///
    /// If a card is selected, deletes the card. If only a project is selected,
    /// deletes the project. Reloads appropriate list after deletion.
    func deleteSelectedItem() {
        guard let workspacePath else {
            print("Cannot delete: workspace path is nil")
            return
        }

        do {
            if let selectedCard, let selectedProject {
                let projectPath = "\(workspacePath)/\(selectedProject.slug)"
                try workspaceService.deleteCard(
                    slug: selectedCard.slug,
                    projectPath: projectPath
                )
                self.selectedCard = nil
                loadCards()
            } else if let selectedProject {
                let projectPath = "\(workspacePath)/\(selectedProject.slug)"
                try workspaceService.deleteProject(at: projectPath)
                self.selectedSection = nil
                loadProjects()
            }
        } catch {
            print("Failed to delete: \(error)")
        }
    }

    /// Requests focus on the search field.
    func requestSearchFocus() {
        self.focusSearch = true
    }
}
