import Foundation

/// Protocol defining tag reconciliation operations.
///
/// Implementations project tags from frontmatter to macOS extended attributes.
/// This is a one-way projection: frontmatter is the source of truth, and tags
/// are written to the `com.apple.metadata:_kMDItemUserTags` extended attribute
/// to enable native macOS Finder and Spotlight tag support.
///
/// The reconciler does not throw errors—it logs failures internally and
/// continues operation, following the "do your best" philosophy.
protocol TagReconciling {
    /// Reconciles tags for a file by writing them to extended attributes.
    ///
    /// Writes the provided tags to the file's extended attributes in plist format.
    /// If the tag array is empty, removes the extended attribute entirely.
    /// Errors are logged internally but not thrown.
    ///
    /// - Parameters:
    ///   - tags: Array of tag strings to write (empty array removes tags)
    ///   - path: Absolute file path to reconcile tags for
    func reconcileTags(for tags: [String], at path: String)
}
