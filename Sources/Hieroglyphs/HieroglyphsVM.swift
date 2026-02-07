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
}
