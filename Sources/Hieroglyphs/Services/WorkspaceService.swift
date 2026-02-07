import Foundation
import Yams

/// Concrete implementation of workspace data loading from filesystem.
///
/// This service reads configuration, discovers projects, and loads cards
/// by scanning directories and parsing markdown files with YAML frontmatter.
/// All methods read directly from disk with no caching.
final class WorkspaceService: WorkspaceProviding {

    enum WorkspaceError: Error {
        case configNotFound
        case configInvalid
        case invalidDirectory
        case yamlParsingFailed(Error)
    }

    private let fileManager: FileManager

    /// Initialize with optional FileManager dependency.
    ///
    /// - Parameter fileManager: FileManager instance (defaults to .default)
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func loadWorkspaceConfig(from configPath: String? = nil) throws -> WorkspaceConfig {
        let resolvedPath: String
        if let configPath = configPath {
            resolvedPath = configPath
        } else {
            let homeDirectory = fileManager.homeDirectoryForCurrentUser.path
            resolvedPath = "\(homeDirectory)/.hieroglyphs/config.yaml"
        }
        let configURL = URL(fileURLWithPath: resolvedPath)

        guard fileManager.fileExists(atPath: resolvedPath) else {
            throw WorkspaceError.configNotFound
        }

        let yamlContent = try String(contentsOf: configURL, encoding: .utf8)

        do {
            let decoder = YAMLDecoder()
            return try decoder.decode(WorkspaceConfig.self, from: yamlContent)
        } catch {
            throw WorkspaceError.yamlParsingFailed(error)
        }
    }

    func loadProjects(from workspacePath: String) throws -> [Project] {
        let workspaceURL = URL(fileURLWithPath: workspacePath)

        guard fileManager.fileExists(atPath: workspacePath) else {
            throw WorkspaceError.invalidDirectory
        }

        let projectURLs = try discoverProjectDirectories(in: workspaceURL)
        return try parseProjects(from: projectURLs)
    }

    private func discoverProjectDirectories(in workspaceURL: URL) throws -> [URL] {
        let contents = try fileManager.contentsOfDirectory(
            at: workspaceURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        return contents.filter { url in
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                return false
            }

            let projectFile = url.appendingPathComponent("project.md")
            return fileManager.fileExists(atPath: projectFile.path)
        }
    }

    private func parseProjects(from urls: [URL]) throws -> [Project] {
        var projects: [Project] = []

        for url in urls {
            do {
                if let project = try parseProject(from: url) {
                    projects.append(project)
                }
            } catch {
                print("Warning: Failed to parse project at \(url.path): \(error)")
            }
        }

        return projects
    }

    private func parseProject(from url: URL) throws -> Project? {
        let projectFile = url.appendingPathComponent("project.md")
        let markdown = try String(contentsOf: projectFile, encoding: .utf8)

        let parsed = try FrontmatterParser.parse(markdown)
        let frontmatter = parsed.frontmatter

        guard let idString = frontmatter["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = frontmatter["title"] as? String else {
            print("Warning: Missing required fields in project at \(url.path)")
            return nil
        }

        let description = frontmatter["description"] as? String ?? ""
        let tags = frontmatter["tags"] as? [String] ?? []
        let slug = url.lastPathComponent

        let dateFormatter = ISO8601DateFormatter()
        let created: Date
        let updated: Date

        if let createdDate = frontmatter["created"] as? Date {
            created = createdDate
        } else if let createdString = frontmatter["created"] as? String,
                  let parsedCreated = dateFormatter.date(from: createdString) {
            created = parsedCreated
        } else {
            created = Date()
        }

        if let updatedDate = frontmatter["updated"] as? Date {
            updated = updatedDate
        } else if let updatedString = frontmatter["updated"] as? String,
                  let parsedUpdated = dateFormatter.date(from: updatedString) {
            updated = parsedUpdated
        } else {
            updated = Date()
        }

        return Project(
            id: id,
            title: title,
            description: description,
            tags: tags,
            created: created,
            updated: updated,
            slug: slug
        )
    }

    func loadCards(from projectPath: String, for project: Project) throws -> [Card] {
        let projectURL = URL(fileURLWithPath: projectPath)
        let cardsURL = projectURL.appendingPathComponent("cards")

        guard fileManager.fileExists(atPath: cardsURL.path) else {
            return []
        }

        let cardURLs = try discoverCardDirectories(in: cardsURL)
        return try parseCards(from: cardURLs)
    }

    private func discoverCardDirectories(in cardsURL: URL) throws -> [URL] {
        let contents = try fileManager.contentsOfDirectory(
            at: cardsURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        return contents.filter { url in
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                return false
            }

            let cardFile = url.appendingPathComponent("card.md")
            return fileManager.fileExists(atPath: cardFile.path)
        }
    }

    private func parseCards(from urls: [URL]) throws -> [Card] {
        var cards: [Card] = []

        for url in urls {
            do {
                if let card = try parseCard(from: url) {
                    cards.append(card)
                }
            } catch {
                print("Warning: Failed to parse card at \(url.path): \(error)")
            }
        }

        return cards
    }

    private func parseCard(from url: URL) throws -> Card? {
        let cardFile = url.appendingPathComponent("card.md")
        let markdown = try String(contentsOf: cardFile, encoding: .utf8)

        let parsed = try FrontmatterParser.parse(markdown)
        let frontmatter = parsed.frontmatter
        let body = parsed.body.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let idString = frontmatter["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = frontmatter["title"] as? String else {
            print("Warning: Missing required fields in card at \(url.path)")
            return nil
        }

        let typeString = frontmatter["type"] as? String ?? "task"
        let statusString = frontmatter["status"] as? String ?? "backlog"
        let priorityString = frontmatter["priority"] as? String ?? "medium"

        let type = CardType(rawValue: typeString) ?? .task
        let status = CardStatus(rawValue: statusString) ?? .backlog
        let priority = Priority(rawValue: priorityString) ?? .medium

        let tags = frontmatter["tags"] as? [String] ?? []
        let slug = url.lastPathComponent

        let dateFormatter = ISO8601DateFormatter()
        let created: Date
        let updated: Date

        if let createdDate = frontmatter["created"] as? Date {
            created = createdDate
        } else if let createdString = frontmatter["created"] as? String,
                  let parsedCreated = dateFormatter.date(from: createdString) {
            created = parsedCreated
        } else {
            created = Date()
        }

        if let updatedDate = frontmatter["updated"] as? Date {
            updated = updatedDate
        } else if let updatedString = frontmatter["updated"] as? String,
                  let parsedUpdated = dateFormatter.date(from: updatedString) {
            updated = parsedUpdated
        } else {
            updated = Date()
        }

        return Card(
            id: id,
            title: title,
            type: type,
            status: status,
            priority: priority,
            tags: tags,
            created: created,
            updated: updated,
            slug: slug,
            body: body
        )
    }
}
