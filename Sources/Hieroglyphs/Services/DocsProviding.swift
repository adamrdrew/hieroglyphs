import Foundation

/// Protocol for loading documentation files from the filesystem.
protocol DocsProviding {
    /// Loads all documentation files from the specified directory.
    ///
    /// - Parameter docsDirectory: Path to the docs directory
    /// - Returns: Array of Doc instances sorted alphabetically by slug
    func loadDocs(from docsDirectory: String) -> [Doc]

    /// Loads the content of a documentation file.
    ///
    /// - Parameter path: Full path to the documentation file
    /// - Returns: File content as string, or nil if file doesn't exist or read fails
    func loadDocContent(path: String) -> String?
}
