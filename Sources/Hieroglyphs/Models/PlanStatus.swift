import Foundation

/// Represents the current status of a plan in the workflow.
enum PlanStatus: String, Codable, CaseIterable {
    case planning = "planning"
    case ready = "ready"
    case done = "done"
}
