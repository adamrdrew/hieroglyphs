import SwiftUI
import Observation

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
    var selectedProject: Project?

    var cards: [Card] = []
    var selectedCard: Card?

    var searchText: String = ""
    var filterStatus: Set<CardStatus> = []
    var filterType: Set<CardType> = []
    var filterPriority: Set<Priority> = []
    var sortBy: CardSortOption = .updated
    var sortOrder: SortOrder = .forward

    private let workspaceService: WorkspaceProviding
    private let fileWatcher: FileWatching?
    private let tagReconciler: TagReconciling?

    init(
        workspaceService: WorkspaceProviding,
        fileWatcher: FileWatching? = nil,
        tagReconciler: TagReconciling? = nil
    ) {
        self.workspaceService = workspaceService
        self.fileWatcher = fileWatcher
        self.tagReconciler = tagReconciler
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
    func createProject(title: String, description: String, tags: [String]) {
        guard let workspacePath else {
            print("Cannot create project: workspace path is nil")
            return
        }

        do {
            _ = try workspaceService.createProject(
                title: title,
                description: description,
                tags: tags,
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

    /// Updates the selected project.
    ///
    /// - Parameter project: The project to select
    func selectProject(_ project: Project?) {
        self.selectedProject = project
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
            loadCards()
        } catch {
            print("Failed to update card: \(error)")
        }
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
}
