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
    let docsDirectory: String?
    let buildCommand: String?
    let runCommand: String?
    let publishCommand: String?

    var hasDocsDirectory: Bool {
        docsDirectory != nil
    }
}
