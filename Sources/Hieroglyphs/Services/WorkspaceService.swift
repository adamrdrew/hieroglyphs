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
        case directoryCreationFailed(Error)
        case fileWriteFailed(Error)
        case projectNotFound
        case cardNotFound
    }

    private let fileManager: FileManager
    private let dateFormatter = ISO8601DateFormatter()

    /// Initialize with optional FileManager dependency.
    ///
    /// - Parameter fileManager: FileManager instance (defaults to .default)
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    // MARK: - Date Formatting Helpers

    private func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    private func parseDate(_ string: String) -> Date? {
        return dateFormatter.date(from: string)
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

        let sourceDirectory = frontmatter["source_directory"] as? String
        let buildCommand = frontmatter["build_command"] as? String
        let runCommand = frontmatter["run_command"] as? String
        let publishCommand = frontmatter["publish_command"] as? String

        return Project(
            id: id,
            title: title,
            description: description,
            tags: tags,
            created: created,
            updated: updated,
            slug: slug,
            sourceDirectory: sourceDirectory,
            buildCommand: buildCommand,
            runCommand: runCommand,
            publishCommand: publishCommand
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

    // MARK: - Write Operations

    func createWorkspace(at path: String, configDirectory: String? = nil) throws {
        let workspaceURL = URL(fileURLWithPath: path)

        do {
            try fileManager.createDirectory(
                at: workspaceURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw WorkspaceError.directoryCreationFailed(error)
        }

        let hieroglyphsDirectory: URL
        if let configDirectory = configDirectory {
            hieroglyphsDirectory = URL(fileURLWithPath: configDirectory)
        } else {
            hieroglyphsDirectory = fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent(".hieroglyphs")
        }

        do {
            try fileManager.createDirectory(
                at: hieroglyphsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw WorkspaceError.directoryCreationFailed(error)
        }

        let configURL = hieroglyphsDirectory.appendingPathComponent("config.yaml")
        let config = WorkspaceConfig(workspacePath: path)

        do {
            let encoder = YAMLEncoder()
            let yamlString = try encoder.encode(config)
            try yamlString.write(to: configURL, atomically: true, encoding: .utf8)
        } catch {
            throw WorkspaceError.fileWriteFailed(error)
        }
    }

    func initializeWorkspaceFiles(at workspacePath: String) throws {
        let workspaceURL = URL(fileURLWithPath: workspacePath)

        let claudeContent = """
# CLAUDE.md

This workspace is managed by Hieroglyphs, a markdown-based project management tool.

## For AI Assistants

- All project data lives in plain text markdown files with YAML frontmatter
- Projects are in top-level directories with `project.md` files
- Cards are in `cards/` subdirectories with `card.md` files
- Edit files directly — changes are detected automatically
- Preserve unknown frontmatter fields when updating files

## Workspace Structure

```
workspace/
  project-name/
    project.md        # Project metadata with frontmatter
    cards/
      card-slug/
        card.md       # Card metadata and content
```
"""

        let agentContent = """
# AGENT.md

This workspace contains Hieroglyphs projects and cards.

## Agent Instructions

When working with this workspace:

1. Read project.md files to understand project structure
2. Read card.md files to understand tasks and content
3. Update frontmatter fields to change metadata
4. Add markdown content below frontmatter for card bodies
5. Always preserve unknown frontmatter fields
6. Use ISO8601 format for dates (YYYY-MM-DDTHH:MM:SSZ)

## Frontmatter Fields

**Projects:** id, title, description, tags, created, updated, slug

**Cards:** id, title, type, status, priority, tags, created, updated, slug
"""

        let claudeURL = workspaceURL.appendingPathComponent("CLAUDE.md")
        let agentURL = workspaceURL.appendingPathComponent("AGENT.md")

        do {
            try claudeContent.write(to: claudeURL, atomically: true, encoding: .utf8)
            try agentContent.write(to: agentURL, atomically: true, encoding: .utf8)
        } catch {
            throw WorkspaceError.fileWriteFailed(error)
        }
    }

    func createProject(
        title: String,
        description: String,
        tags: [String],
        sourceDirectory: String?,
        buildCommand: String? = nil,
        runCommand: String? = nil,
        publishCommand: String? = nil,
        at workspacePath: String
    ) throws -> Project {
        let slug = SlugGenerator.generateSlug(from: title)
        let workspaceURL = URL(fileURLWithPath: workspacePath)
        let projectURL = workspaceURL.appendingPathComponent(slug)

        do {
            try fileManager.createDirectory(
                at: projectURL,
                withIntermediateDirectories: false,
                attributes: nil
            )
        } catch {
            throw WorkspaceError.directoryCreationFailed(error)
        }

        let id = UUID()
        let now = Date()
        let created = now
        let updated = now

        var frontmatter: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "description": description,
            "tags": tags,
            "created": formatDate(created),
            "updated": formatDate(updated),
            "slug": slug
        ]

        if let sourceDirectory = sourceDirectory {
            frontmatter["source_directory"] = sourceDirectory
        }

        if let buildCommand = buildCommand {
            frontmatter["build_command"] = buildCommand
        }

        if let runCommand = runCommand {
            frontmatter["run_command"] = runCommand
        }

        if let publishCommand = publishCommand {
            frontmatter["publish_command"] = publishCommand
        }

        let markdown = try FrontmatterParser.serialize(
            frontmatter: frontmatter,
            body: ""
        )

        let projectFileURL = projectURL.appendingPathComponent("project.md")

        do {
            try markdown.write(to: projectFileURL, atomically: true, encoding: .utf8)
        } catch {
            throw WorkspaceError.fileWriteFailed(error)
        }

        return Project(
            id: id,
            title: title,
            description: description,
            tags: tags,
            created: created,
            updated: updated,
            slug: slug,
            sourceDirectory: sourceDirectory,
            buildCommand: buildCommand,
            runCommand: runCommand,
            publishCommand: publishCommand
        )
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
        let slug = SlugGenerator.generateSlug(from: title)
        let projectURL = URL(fileURLWithPath: projectPath)
        let cardsURL = projectURL.appendingPathComponent("cards")

        if !fileManager.fileExists(atPath: cardsURL.path) {
            do {
                try fileManager.createDirectory(
                    at: cardsURL,
                    withIntermediateDirectories: false,
                    attributes: nil
                )
            } catch {
                throw WorkspaceError.directoryCreationFailed(error)
            }
        }

        let cardURL = cardsURL.appendingPathComponent(slug)

        do {
            try fileManager.createDirectory(
                at: cardURL,
                withIntermediateDirectories: false,
                attributes: nil
            )
        } catch {
            throw WorkspaceError.directoryCreationFailed(error)
        }

        let id = UUID()
        let now = Date()
        let created = now
        let updated = now

        let frontmatter: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "type": type.rawValue,
            "status": status.rawValue,
            "priority": priority.rawValue,
            "tags": tags,
            "created": formatDate(created),
            "updated": formatDate(updated),
            "slug": slug
        ]

        let markdown = try FrontmatterParser.serialize(
            frontmatter: frontmatter,
            body: body
        )

        let cardFileURL = cardURL.appendingPathComponent("card.md")

        do {
            try markdown.write(to: cardFileURL, atomically: true, encoding: .utf8)
        } catch {
            throw WorkspaceError.fileWriteFailed(error)
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

    func updateProject(_ project: Project, at workspacePath: String) throws {
        let workspaceURL = URL(fileURLWithPath: workspacePath)
        let projectURL = workspaceURL.appendingPathComponent(project.slug)
        let projectFileURL = projectURL.appendingPathComponent("project.md")

        guard fileManager.fileExists(atPath: projectFileURL.path) else {
            throw WorkspaceError.projectNotFound
        }

        let existingMarkdown = try String(contentsOf: projectFileURL, encoding: .utf8)
        let parsed = try FrontmatterParser.parse(existingMarkdown)
        var frontmatter = parsed.frontmatter

        frontmatter["id"] = project.id.uuidString
        frontmatter["title"] = project.title
        frontmatter["description"] = project.description
        frontmatter["tags"] = project.tags
        frontmatter["created"] = formatDate(project.created)
        frontmatter["updated"] = formatDate(Date())
        frontmatter["slug"] = project.slug

        if let sourceDirectory = project.sourceDirectory {
            frontmatter["source_directory"] = sourceDirectory
        } else {
            frontmatter.removeValue(forKey: "source_directory")
        }

        if let buildCommand = project.buildCommand {
            frontmatter["build_command"] = buildCommand
        } else {
            frontmatter.removeValue(forKey: "build_command")
        }

        if let runCommand = project.runCommand {
            frontmatter["run_command"] = runCommand
        } else {
            frontmatter.removeValue(forKey: "run_command")
        }

        if let publishCommand = project.publishCommand {
            frontmatter["publish_command"] = publishCommand
        } else {
            frontmatter.removeValue(forKey: "publish_command")
        }

        let markdown = try FrontmatterParser.serialize(
            frontmatter: frontmatter,
            body: parsed.body
        )

        do {
            try markdown.write(to: projectFileURL, atomically: true, encoding: .utf8)
        } catch {
            throw WorkspaceError.fileWriteFailed(error)
        }
    }

    func updateCard(_ card: Card, projectPath: String) throws {
        let projectURL = URL(fileURLWithPath: projectPath)
        let cardsURL = projectURL.appendingPathComponent("cards")
        let cardURL = cardsURL.appendingPathComponent(card.slug)
        let cardFileURL = cardURL.appendingPathComponent("card.md")

        guard fileManager.fileExists(atPath: cardFileURL.path) else {
            throw WorkspaceError.cardNotFound
        }

        let existingMarkdown = try String(contentsOf: cardFileURL, encoding: .utf8)
        let parsed = try FrontmatterParser.parse(existingMarkdown)
        var frontmatter = parsed.frontmatter

        frontmatter["id"] = card.id.uuidString
        frontmatter["title"] = card.title
        frontmatter["type"] = card.type.rawValue
        frontmatter["status"] = card.status.rawValue
        frontmatter["priority"] = card.priority.rawValue
        frontmatter["tags"] = card.tags
        frontmatter["created"] = formatDate(card.created)
        frontmatter["updated"] = formatDate(Date())
        frontmatter["slug"] = card.slug

        let markdown = try FrontmatterParser.serialize(
            frontmatter: frontmatter,
            body: card.body
        )

        do {
            try markdown.write(to: cardFileURL, atomically: true, encoding: .utf8)
        } catch {
            throw WorkspaceError.fileWriteFailed(error)
        }
    }

    func deleteProject(at projectPath: String) throws {
        let projectURL = URL(fileURLWithPath: projectPath)

        guard fileManager.fileExists(atPath: projectURL.path) else {
            throw WorkspaceError.projectNotFound
        }

        var resultingURL: NSURL?
        try fileManager.trashItem(at: projectURL, resultingItemURL: &resultingURL)
    }

    func deleteCard(slug: String, projectPath: String) throws {
        let projectURL = URL(fileURLWithPath: projectPath)
        let cardsURL = projectURL.appendingPathComponent("cards")
        let cardURL = cardsURL.appendingPathComponent(slug)

        guard fileManager.fileExists(atPath: cardURL.path) else {
            throw WorkspaceError.cardNotFound
        }

        var resultingURL: NSURL?
        try fileManager.trashItem(at: cardURL, resultingItemURL: &resultingURL)
    }

    // MARK: - Card Ingestion

    func ingestCardsFromUshabti(
        projectPath: String,
        sourceDirectory: String?
    ) throws -> Int {
        guard let sourceDirectory else { return 0 }

        let ushabtiCardsPath = "\(sourceDirectory)/.ushabti/cards"
        let ushabtiCardsURL = URL(fileURLWithPath: ushabtiCardsPath)

        guard fileManager.fileExists(atPath: ushabtiCardsURL.path) else {
            return 0
        }

        return try ingestCardsFromDirectory(
            ushabtiCardsURL,
            projectPath: projectPath
        )
    }

    private func ingestCardsFromDirectory(
        _ sourceURL: URL,
        projectPath: String
    ) throws -> Int {
        let projectURL = URL(fileURLWithPath: projectPath)
        let targetCardsURL = projectURL.appendingPathComponent("cards")

        let cardDirectories = try discoverCardDirectories(in: sourceURL)
        var ingestedCount = 0

        for cardURL in cardDirectories {
            let slug = cardURL.lastPathComponent
            let targetCardURL = targetCardsURL.appendingPathComponent(slug)

            if fileManager.fileExists(atPath: targetCardURL.path) {
                continue
            }

            if try ingestCard(from: cardURL, to: targetCardURL) {
                ingestedCount += 1
            }
        }

        return ingestedCount
    }

    private func ingestCard(from sourceURL: URL, to targetURL: URL) throws -> Bool {
        let cardFileURL = sourceURL.appendingPathComponent("card.md")

        do {
            let markdown = try String(contentsOf: cardFileURL, encoding: .utf8)
            let parsed = try FrontmatterParser.parse(markdown)
            var frontmatter = parsed.frontmatter

            frontmatter["status"] = "triage"
            frontmatter["updated"] = formatDate(Date())

            let updatedMarkdown = try FrontmatterParser.serialize(
                frontmatter: frontmatter,
                body: parsed.body
            )

            try createCardDirectoryAndWrite(
                markdown: updatedMarkdown,
                at: targetURL
            )

            try fileManager.removeItem(at: sourceURL)
            return true
        } catch {
            print("Warning: Failed to ingest card at \(sourceURL.path): \(error)")
            return false
        }
    }

    private func createCardDirectoryAndWrite(
        markdown: String,
        at targetURL: URL
    ) throws {
        try fileManager.createDirectory(
            at: targetURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let cardFileURL = targetURL.appendingPathComponent("card.md")
        try markdown.write(to: cardFileURL, atomically: true, encoding: .utf8)
    }
}
