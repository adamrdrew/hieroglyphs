import Foundation

/// Represents a single search result from Spotlight search.
///
/// Contains metadata about a matched item (project or card) including
/// file path, title, type, and parent context.
struct SearchResult: Identifiable, Equatable, Hashable {
    /// Unique identifier for the search result.
    let id: UUID

    /// Display title of the matched item.
    let title: String

    /// Absolute file path to the matched markdown file.
    let path: String

    /// Type of search result (project or card).
    let resultType: SearchResultType

    /// Parent project slug if result is a card.
    let projectSlug: String?

    /// Card slug if result is a card.
    let cardSlug: String?

    init(
        id: UUID = UUID(),
        title: String,
        path: String,
        resultType: SearchResultType,
        projectSlug: String? = nil,
        cardSlug: String? = nil
    ) {
        self.id = id
        self.title = title
        self.path = path
        self.resultType = resultType
        self.projectSlug = projectSlug
        self.cardSlug = cardSlug
    }
}

/// Type of search result.
enum SearchResultType: String, Codable {
    case project
    case card
}
