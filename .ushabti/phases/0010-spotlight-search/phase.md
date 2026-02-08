# Phase 10: Spotlight Search

## Intent

Implement Spotlight-powered search using NSMetadataQuery to search workspace content and metadata. The `SpotlightService` (conforming to `SearchProviding` protocol) scopes queries to the workspace directory and searches both file contents (markdown bodies) and metadata (including tags projected to extended attributes). This replaces the current in-memory substring matching with macOS's battle-tested search indexing system.

Search results include both cards and projects. When a user executes a search, results are displayed in a dedicated search results view. Selecting a result navigates to the matching card or project, setting the appropriate selection state in the ViewModel.

## Scope

**In scope:**
- `SearchProviding` protocol defining the service contract
- `SpotlightService` concrete implementation using NSMetadataQuery
- Search scoping to workspace directory only
- Search across file content (markdown text) and metadata (title, tags)
- Result model (`SearchResult`) representing matched cards and projects
- Integration with ViewModel to trigger searches
- Navigation to search results (setting `selectedProject` and `selectedCard`)
- Environment key for dependency injection

**Out of scope:**
- Search result highlighting or snippet preview (future enhancement)
- Search history or saved searches (future enhancement)
- Advanced query syntax (AND/OR/NOT operators) (future enhancement)
- Search result ranking customization (rely on Spotlight's default ranking)
- Indexing control or status UI (Spotlight handles indexing automatically)
- Searching archived cards or deleted items

## Constraints

**Laws:**
- **L06 (Platform Leverage):** Use NSMetadataQuery for search. Do not build custom indexing or search logic.
- **L08 (Frontmatter Is Tag Source):** Tags are searchable because they are projected to extended attributes by TagReconcilerService. Search uses extended attributes, not frontmatter parsing.
- **L09 (Sandi Metz Principles):** Protocol-based service, dependency injection, single responsibility
- **L11 (Test Coverage):** All public methods must have tests (note: NSMetadataQuery tests use mocks or temporary workspace fixtures)

**Style:**
- Protocol-based service design (SearchProviding protocol + SpotlightService implementation)
- Small, focused methods (5 lines or fewer where possible)
- No regex (use NSPredicate for query construction)
- Environment key for SwiftUI injection
- Error handling follows "do your best" philosophy (return empty results on error, log to console)

## Acceptance Criteria

1. **Protocol exists:** `SearchProviding` protocol defines search method with query string parameter and completion handler
2. **Service implementation:** `SpotlightService` implements protocol using NSMetadataQuery
3. **Workspace scoping:** Queries use `NSMetadataQueryScope` to limit results to workspace directory
4. **Content search:** Searches find cards by markdown body content (e.g., search for "API" finds cards with "API" in body)
5. **Metadata search:** Searches find cards by title and tags (e.g., search for "urgent" finds cards with "urgent" tag)
6. **Result model:** `SearchResult` includes file path, title, type (project/card), and matched item reference
7. **ViewModel integration:** `HieroglyphsVM` has `performSearch(_:)` method that uses `SearchProviding` service
8. **Navigation works:** Selecting a search result navigates to the project or card (sets selection state)
9. **Verification test:** Create card with title "Spotlight Integration", body "Use NSMetadataQuery for search", and tags ["search", "platform"]. Search for "NSMetadataQuery" returns the card. Search for "platform" returns the card.
10. **Tests pass:** All new tests and existing tests pass
11. **Lint passes:** No lint violations

## Risks / Notes

- **Spotlight indexing delay:** Newly created files may not appear in search results immediately (Spotlight indexes asynchronously). This is expected behavior and acceptable for v1. Users can wait a few seconds and search again.
- **NSMetadataQuery threading:** NSMetadataQuery delivers results on its own thread. Service must marshal results to main thread for ViewModel consumption.
- **Query complexity:** NSPredicate syntax for combining content and metadata queries may require careful construction. Test thoroughly with various query types.
- **No result snippets:** This phase returns only matched file paths and titles, not text snippets showing match context. Future phases may add snippet extraction.
- **Search UI scope:** This phase focuses on backend search infrastructure. UI improvements (dedicated search results view, result highlighting) are deferred to future phases. Initial integration reuses `.searchable()` modifier and filters in-memory results as a stepping stone toward dedicated search UI.
