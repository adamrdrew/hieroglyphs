import Foundation

/// Represents a Ushabti phase with its metadata, steps, and review state.
///
/// Phases are read from {sourceDirectory}/.ushabti/phases/NNNN-slug/
/// directory structure. This is a read-only model for displaying phase
/// data in the Hieroglyphs UI.
struct Phase: Codable, Equatable, Identifiable, Hashable {
    let number: Int
    let slug: String
    let title: String
    let status: PhaseStatus
    let intent: String
    let steps: [PhaseStep]
    let reviewNotes: String

    var id: String {
        slug
    }
}
