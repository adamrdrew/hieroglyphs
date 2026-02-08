import Foundation

/// Protocol defining the contract for search services.
///
/// Implementations use platform-specific search capabilities to find
/// projects and cards matching query strings. Results are delivered
/// asynchronously via completion handler on the main thread.
protocol SearchProviding {
    /// Performs a search for projects and cards matching the query.
    ///
    /// Searches both file content (markdown bodies) and metadata (title, tags).
    /// Results are scoped to the specified directory path.
    ///
    /// - Parameters:
    ///   - query: Search query string
    ///   - scope: Absolute path to workspace directory to search within
    ///   - completion: Completion handler receiving array of search results
    func performSearch(
        query: String,
        scope: String,
        completion: @escaping @Sendable ([SearchResult]) -> Void
    )
}
