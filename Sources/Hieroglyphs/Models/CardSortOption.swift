import Foundation

/// Defines available sort criteria for card lists.
enum CardSortOption: String, CaseIterable {
    case created = "created"
    case updated = "updated"
    case priority = "priority"
    case status = "status"
    case title = "title"
}
