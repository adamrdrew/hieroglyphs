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

    init(workspaceService: WorkspaceProviding) {
        self.workspaceService = workspaceService
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
}
