import Foundation

/// Represents a card with type, status, priority, and markdown body.
struct Card: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let type: CardType
    let status: CardStatus
    let priority: Priority
    let tags: [String]
    let created: Date
    let updated: Date
    let slug: String
    let body: String
}
