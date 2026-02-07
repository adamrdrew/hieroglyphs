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
}
