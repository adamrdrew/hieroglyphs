import Foundation

/// Spotlight-powered search service using NSMetadataQuery.
///
/// Searches workspace files for content and metadata matches.
/// Scopes queries to workspace directory and delivers results
/// on main thread via completion handler.
final class SpotlightService: SearchProviding {
    private var activeQuery: NSMetadataQuery?

    func performSearch(
        query: String,
        scope: String,
        completion: @escaping @Sendable ([SearchResult]) -> Void
    ) {
        stopActiveQuery()

        guard !query.isEmpty else {
            completion([])
            return
        }

        let metadataQuery = createQuery(query: query, scope: scope)
        self.activeQuery = metadataQuery

        observeQueryCompletion(
            query: metadataQuery,
            completion: completion
        )

        metadataQuery.start()
    }

    private func stopActiveQuery() {
        activeQuery?.stop()
        activeQuery = nil
    }

    private func createQuery(query: String, scope: String) -> NSMetadataQuery {
        let metadataQuery = NSMetadataQuery()
        metadataQuery.searchScopes = [URL(fileURLWithPath: scope)]
        metadataQuery.predicate = buildPredicate(query: query)
        return metadataQuery
    }

    private func buildPredicate(query: String) -> NSPredicate {
        let contentPredicate = NSPredicate(
            format: "kMDItemTextContent CONTAINS[cd] %@",
            query
        )

        let titlePredicate = NSPredicate(
            format: "kMDItemDisplayName CONTAINS[cd] %@",
            query
        )

        let tagsPredicate = NSPredicate(
            format: "kMDItemUserTags CONTAINS[cd] %@",
            query
        )

        return NSCompoundPredicate(
            orPredicateWithSubpredicates: [
                contentPredicate,
                titlePredicate,
                tagsPredicate
            ]
        )
    }

    private func observeQueryCompletion(
        query: NSMetadataQuery,
        completion: @escaping @Sendable ([SearchResult]) -> Void
    ) {
        NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidFinishGathering,
            object: query,
            queue: .main
        ) { [weak self] _ in
            self?.handleQueryResults(query: query, completion: completion)
        }
    }

    private func handleQueryResults(
        query: NSMetadataQuery,
        completion: @escaping @Sendable ([SearchResult]) -> Void
    ) {
        query.stop()

        let results = extractResults(from: query)
        completion(results)

        NotificationCenter.default.removeObserver(
            self as Any,
            name: .NSMetadataQueryDidFinishGathering,
            object: query
        )

        if activeQuery === query {
            activeQuery = nil
        }
    }

    private func extractResults(from query: NSMetadataQuery) -> [SearchResult] {
        var searchResults: [SearchResult] = []

        for index in 0..<query.resultCount {
            guard let item = query.result(at: index) as? NSMetadataItem else {
                continue
            }

            if let result = buildSearchResult(from: item) {
                searchResults.append(result)
            }
        }

        return searchResults
    }

    private func buildSearchResult(from item: NSMetadataItem) -> SearchResult? {
        guard let path = item.value(
            forAttribute: NSMetadataItemPathKey
        ) as? String else {
            return nil
        }

        guard let title = item.value(
            forAttribute: NSMetadataItemDisplayNameKey
        ) as? String else {
            return nil
        }

        guard let resultType = determineResultType(path: path) else {
            return nil
        }

        let (projectSlug, cardSlug) = extractSlugs(path: path, type: resultType)

        return SearchResult(
            title: title,
            path: path,
            resultType: resultType,
            projectSlug: projectSlug,
            cardSlug: cardSlug
        )
    }

    func determineResultType(path: String) -> SearchResultType? {
        if path.hasSuffix("/project.md") {
            return .project
        } else if path.hasSuffix("/card.md") {
            return .card
        }
        return nil
    }

    func extractSlugs(
        path: String,
        type: SearchResultType
    ) -> (projectSlug: String?, cardSlug: String?) {
        let components = path.split(separator: "/")

        switch type {
        case .project:
            guard components.count >= 2 else { return (nil, nil) }
            let projectSlug = String(components[components.count - 2])
            return (projectSlug, nil)

        case .card:
            guard components.count >= 4 else { return (nil, nil) }
            let cardSlug = String(components[components.count - 2])
            let projectSlug = String(components[components.count - 4])
            return (projectSlug, cardSlug)
        }
    }
}
