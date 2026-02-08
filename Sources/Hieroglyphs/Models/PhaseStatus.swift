import Foundation

/// Represents the current status of a phase in the Ushabti workflow.
///
/// Status values match those defined in progress.yaml and represent
/// progression through the plan-build-review cycle.
enum PhaseStatus: String, Codable, Equatable, Hashable {
    case planned
    case active
    case green
    case yellow
    case red
}
