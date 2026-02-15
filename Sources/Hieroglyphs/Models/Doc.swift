import Foundation

/// Represents a documentation file from the Ushabti docs directory.
struct Doc: Identifiable, Equatable, Hashable {
    let id: UUID
    let title: String
    let slug: String
    let filename: String
    let content: String

    var displayTitle: String {
        slug
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}
