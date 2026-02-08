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

    // MARK: - Write Operations

    /// Creates a new workspace directory and configuration file.
    ///
    /// Creates the workspace directory at the specified path and writes
    /// config.yaml to `~/.hieroglyphs/config.yaml` with the workspace path.
    ///
    /// - Parameters:
    ///   - path: Absolute path where the workspace directory should be created
    ///   - configDirectory: Optional custom config directory (defaults to ~/.hieroglyphs)
    /// - Throws: If directory creation or config writing fails
    func createWorkspace(at path: String, configDirectory: String?) throws

    /// Initializes workspace with stub instruction files.
    ///
    /// Creates CLAUDE.md and AGENT.md in the workspace root with instructional
    /// content for users and AI assistants.
    ///
    /// - Parameter workspacePath: Absolute path to the workspace directory
    /// - Throws: If file writing fails
    func initializeWorkspaceFiles(at workspacePath: String) throws

    /// Creates a new project with slugified directory and frontmatter.
    ///
    /// Generates a slug from the title, creates the project directory, and
    /// writes project.md with YAML frontmatter. Sets created and updated
    /// timestamps to the current date.
    ///
    /// - Parameters:
    ///   - title: Project title
    ///   - description: Project description
    ///   - tags: Project tags
    ///   - sourceDirectory: Optional path to source directory
    ///   - workspacePath: Absolute path to the workspace directory
    /// - Returns: The created Project model
    /// - Throws: If directory creation or file writing fails
    func createProject(
        title: String,
        description: String,
        tags: [String],
        sourceDirectory: String?,
        at workspacePath: String
    ) throws -> Project

    /// Creates a new card with slugified directory and frontmatter.
    ///
    /// Generates a slug from the title, creates the card directory under
    /// the project's cards/ folder, and writes card.md with YAML frontmatter
    /// and body content. Sets created and updated timestamps to current date.
    ///
    /// - Parameters:
    ///   - title: Card title
    ///   - type: Card type
    ///   - status: Card status
    ///   - priority: Card priority
    ///   - tags: Card tags
    ///   - body: Markdown body content
    ///   - projectPath: Absolute path to the parent project directory
    /// - Returns: The created Card model
    /// - Throws: If directory creation or file writing fails
    func createCard(
        title: String,
        type: CardType,
        status: CardStatus,
        priority: Priority,
        tags: [String],
        body: String,
        projectPath: String
    ) throws -> Card

    /// Updates an existing project, preserving unknown frontmatter fields.
    ///
    /// Reads the existing project.md, merges updated fields while preserving
    /// unknown frontmatter fields, updates the 'updated' timestamp, and writes
    /// the file atomically.
    ///
    /// - Parameters:
    ///   - project: The updated project model
    ///   - workspacePath: Absolute path to the workspace directory
    /// - Throws: If the project is not found or file writing fails
    func updateProject(_ project: Project, at workspacePath: String) throws

    /// Updates an existing card, preserving unknown frontmatter fields.
    ///
    /// Reads the existing card.md, merges updated fields while preserving
    /// unknown frontmatter fields, updates the 'updated' timestamp, and writes
    /// the file atomically.
    ///
    /// - Parameters:
    ///   - card: The updated card model
    ///   - projectPath: Absolute path to the parent project directory
    /// - Throws: If the card is not found or file writing fails
    func updateCard(_ card: Card, projectPath: String) throws

    /// Deletes a project by moving it to the Trash.
    ///
    /// Uses NSFileManager.trashItem to move the project directory to the
    /// system Trash, providing user safety and undo capability.
    ///
    /// - Parameter projectPath: Absolute path to the project directory
    /// - Throws: If the project is not found or trash operation fails
    func deleteProject(at projectPath: String) throws

    /// Deletes a card by moving it to the Trash.
    ///
    /// Uses NSFileManager.trashItem to move the card directory to the
    /// system Trash, providing user safety and undo capability.
    ///
    /// - Parameters:
    ///   - slug: The card's slug identifier
    ///   - projectPath: Absolute path to the parent project directory
    /// - Throws: If the card is not found or trash operation fails
    func deleteCard(slug: String, projectPath: String) throws

    /// Ingests cards from Ushabti agent directory into Hieroglyphs library.
    ///
    /// Discovers cards in `{sourceDirectory}/.ushabti/cards/`, copies them to the
    /// Hieroglyphs library at `{projectPath}/cards/`, overrides status to triage,
    /// and deletes source cards after successful import. Skips duplicate slugs and
    /// malformed cards. Handles missing directories and permission errors gracefully.
    ///
    /// - Parameters:
    ///   - projectPath: Absolute path to the project directory
    ///   - sourceDirectory: Optional path to source directory containing .ushabti/cards/
    /// - Returns: Count of successfully ingested cards
    /// - Throws: Rarely throws (handles errors gracefully with warnings)
    func ingestCardsFromUshabti(projectPath: String, sourceDirectory: String?) throws -> Int
}
