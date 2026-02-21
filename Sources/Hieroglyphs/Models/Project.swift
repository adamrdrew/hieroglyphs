import Foundation

/// Represents a project with metadata and timestamps.
struct Project: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let tags: [String]
    let created: Date
    let updated: Date
    let slug: String
    let sourceDirectory: String?
    let buildCommand: String?
    let runCommand: String?
    let publishCommand: String?

    func hasDocsDirectory(docsService: DocsProviding) -> Bool {
        guard let sourceDirectory = sourceDirectory else {
            return false
        }
        return docsService.hasDocsDirectory(sourceDirectory: sourceDirectory)
    }
}
