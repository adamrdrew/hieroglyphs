import Foundation

/// Represents the workflow state of a card.
enum CardStatus: String, Codable, CaseIterable {
    case backlog = "backlog"
    case triage = "triage"
    case todo = "todo"
    case inProgress = "in-progress"
    case done = "done"
    case archived = "archived"
}
