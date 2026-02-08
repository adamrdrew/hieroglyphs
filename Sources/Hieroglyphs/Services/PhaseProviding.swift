import Foundation

/// Protocol defining the interface for reading Ushabti phase data from disk.
///
/// Implementations discover phase directories in `.ushabti/phases/` and parse
/// phase metadata, steps, and review notes. This is a read-only service—phases
/// are managed by Ushabti agents (Scribe, Builder, Overseer) outside of
/// Hieroglyphs.
protocol PhaseProviding {

    /// Loads all phases from a source directory's `.ushabti/phases/` folder.
    ///
    /// Scans for directories matching the pattern `NNNN-slug`, parses
    /// phase.md for intent, progress.yaml for title/status/steps, and
    /// review.md for review notes. Returns phases sorted by number ascending.
    ///
    /// - Parameter sourceDirectory: Absolute path to the project source directory
    /// - Returns: An array of discovered phases (may be empty)
    /// - Throws: If the source directory is inaccessible
    func loadPhases(from sourceDirectory: String) throws -> [Phase]
}
