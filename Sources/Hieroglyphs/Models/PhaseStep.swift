import Foundation

/// Represents a single implementation step within a phase.
///
/// Steps are defined in steps.md and tracked in progress.yaml.
/// Builder marks steps implemented, Overseer marks them reviewed.
struct PhaseStep: Codable, Equatable, Identifiable, Hashable {
    let id: String
    let summary: String
    let implemented: Bool
    let reviewed: Bool
}
