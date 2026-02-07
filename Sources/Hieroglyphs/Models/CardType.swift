import Foundation

/// Represents the category of a card.
enum CardType: String, Codable, CaseIterable {
    case task = "task"
    case bug = "bug"
    case feature = "feature"
    case note = "note"
}
