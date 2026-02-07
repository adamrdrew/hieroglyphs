import Foundation

/// Protocol defining the interface for loading workspace data from disk.
///
/// Implementations read configuration, discover projects, and load cards
/// from the filesystem. The service is stateless and reads on demand.
protocol WorkspaceProviding {

    /// Loads workspace configuration from `~/.hieroglyphs/config.yaml`.
    ///
    /// - Parameter configPath: Optional custom config path (for testing)
    /// - Returns: A `WorkspaceConfig` containing the workspace path
    /// - Throws: If the config file is missing, unreadable, or invalid
    func loadWorkspaceConfig(from configPath: String?) throws -> WorkspaceConfig

    /// Loads all projects from the specified workspace directory.
    ///
    /// Scans for subdirectories containing `project.md`, parses frontmatter,
    /// and constructs `Project` model instances. Skips unparseable files.
    ///
    /// - Parameter workspacePath: Absolute path to the workspace directory
    /// - Returns: An array of discovered projects (may be empty)
    /// - Throws: If the workspace directory is inaccessible
    func loadProjects(from workspacePath: String) throws -> [Project]

    /// Loads all cards for a given project.
    ///
    /// Scans the project's `cards/` subdirectory for card folders containing
    /// `card.md`, parses frontmatter, and constructs `Card` model instances.
    /// Skips unparseable files.
    ///
    /// - Parameters:
    ///   - projectPath: Absolute path to the project directory
    ///   - project: The project these cards belong to
    /// - Returns: An array of discovered cards (may be empty)
    /// - Throws: If the project directory is inaccessible
    func loadCards(from projectPath: String, for project: Project) throws -> [Card]
}
