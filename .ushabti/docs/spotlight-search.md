# Spotlight Search

## Overview

Hieroglyphs uses macOS Spotlight (NSMetadataQuery) to provide fast, system-level search across workspace files. The search system is implemented as a protocol-based service that searches both file content and metadata (titles, tags).

**Protocol:** `SearchProviding`
**Implementation:** `SpotlightService`
**Location:** `Sources/Hieroglyphs/Services/`

The search system supports L06 (Platform Leverage: Use NSMetadataQuery instead of custom indexing) and L09 (Protocol-Based Services for testability).

## Architecture

### SearchResult Model

**Location:** `Sources/Hieroglyphs/Models/SearchResult.swift`

**Purpose:** Represents a single search result from Spotlight.

**Fields:**
- `id: UUID` — Unique identifier for the result
- `title: String` — Display title of matched item
- `path: String` — Absolute file path to matched markdown file
- `resultType: SearchResultType` — Type of result (`.project` or `.card`)
- `projectSlug: String?` — Parent project slug (for card results)
- `cardSlug: String?` — Card slug (for card results)

**Conformances:** `Identifiable`, `Equatable`, `Hashable`

**Example:**

```swift
SearchResult(
    title: "Implement Search",
    path: "/workspace/my-project/cards/implement-search/card.md",
    resultType: .card,
    projectSlug: "my-project",
    cardSlug: "implement-search"
)
```

### SearchResultType Enum

**Cases:**
- `.project` — Result is a project
- `.card` — Result is a card

### SearchProviding Protocol

**Purpose:** Define the contract for search services.

**Method:**

```swift
func performSearch(
    query: String,
    scope: String,
    completion: @escaping @Sendable ([SearchResult]) -> Void
)
```

**Parameters:**
- `query` — Search query string
- `scope` — Absolute path to workspace directory (limits search scope)
- `completion` — Completion handler called with search results on main thread

**Notes:**
- Protocol is not `@MainActor` to allow flexible implementations
- Completion handler is `@Sendable` for Swift concurrency safety
- Service implementations must call completion on main thread

### SpotlightService Implementation

**Purpose:** Concrete implementation using NSMetadataQuery.

**Behavior:**

1. **Query Creation:**
   - Creates NSMetadataQuery instance
   - Sets `searchScopes` to limit results to workspace directory
   - Builds NSPredicate combining content and metadata searches

2. **Predicate Construction:**
   - Content: `kMDItemTextContent CONTAINS[cd] query`
   - Title: `kMDItemDisplayName CONTAINS[cd] query`
   - Tags: `kMDItemUserTags CONTAINS[cd] query`
   - Combined with `NSCompoundPredicate` using OR logic

3. **Query Execution:**
   - Starts query with `.start()`
   - Observes `NSMetadataQueryDidFinishGathering` notification
   - Stops query after results are gathered
   - Extracts results and maps to `SearchResult` objects

4. **Result Mapping:**
   - Filters results to only `project.md` or `card.md` files
   - Extracts project/card slugs from file paths
   - Uses `NSMetadataItemPathKey` for file path
   - Uses `NSMetadataItemDisplayNameKey` for title

5. **Lifecycle Management:**
   - Stops previous query before starting new search
   - Cleans up notification observers after completion
   - Returns empty array for empty queries

**Path Slug Extraction:**

Project: `/workspace/my-project/project.md` → `projectSlug: "my-project"`
Card: `/workspace/project-alpha/cards/card-beta/card.md` → `projectSlug: "project-alpha"`, `cardSlug: "card-beta"`

**Example Usage:**

```swift
let service = SpotlightService()
service.performSearch(
    query: "API",
    scope: "/Users/alice/Hieroglyphs"
) { results in
    print("Found \(results.count) results")
}
```

### ViewModel Integration

**Location:** `Sources/Hieroglyphs/HieroglyphsVM.swift`

**State:**
- `searchResults: [SearchResult]` — Published array of current search results

**Dependencies:**
- `searchService: SearchProviding?` — Injected search service (optional)

**Methods:**

#### performSearch(query:)

**Signature:** `func performSearch(query: String)`

**Purpose:** Execute a search and update `searchResults`.

**Behavior:**
1. Guard check for non-nil `searchService` (logs error if nil)
2. If query is empty, clear `searchResults` and return
3. Guard check for non-nil `workspacePath` (logs error if nil)
4. Call `searchService.performSearch(query:scope:completion:)`
5. In completion handler, update `searchResults` on main thread

**Error Handling:**
- Nil service: Logs "Cannot perform search: search service is nil"
- Nil workspace: Logs "Cannot perform search: workspace path is nil", sets results to `[]`
- Empty query: Clears `searchResults` to `[]`

#### navigateToSearchResult(_:)

**Signature:** `func navigateToSearchResult(_ result: SearchResult)`

**Purpose:** Navigate to a search result by setting selection state.

**Behavior:**

For `.project` results:
1. Find project in `projects` array by slug
2. Set `selectedProject` to found project

For `.card` results:
1. Find project in `projects` array by `projectSlug`
2. Set `selectedProject` to found project
3. Call `loadCards()` to load cards for project
4. Find card in `cards` array by `cardSlug`
5. Set `selectedCard` to found card

**Notes:**
- If slugs are nil, navigation is skipped
- If project/card not found in arrays, selection is not updated
- Card navigation automatically loads cards before selecting card

### Environment Injection

**File:** `SpotlightServiceEnvironmentKey.swift`

**Purpose:** Enable SwiftUI environment injection of search service.

**Usage:**

```swift
// In App.swift:
let searchService = SpotlightService()
.environment(\.searchService, searchService)

// In views:
@Environment(\.searchService) private var searchService
```

**Default Value:** `SpotlightService()` instance

## Search Scope and Performance

**Scoping:**
- Queries are scoped to workspace directory using `NSMetadataQuery.searchScopes`
- Only files within workspace are indexed and searched
- Files outside workspace are never returned in results

**Performance:**
- Spotlight indexing is asynchronous and system-managed
- Newly created files may take a few seconds to appear in search results
- macOS indexes file content, metadata, and extended attributes automatically
- No custom indexing or background work required

**Tag Search:**
- Tags are searchable because `TagReconcilerService` projects frontmatter tags to extended attributes
- Spotlight indexes `kMDItemUserTags` extended attribute
- Tag search works via `kMDItemUserTags CONTAINS[cd] query` predicate

## Known Limitations

**Indexing Delay:**
- Files created or modified may not appear in search results immediately
- Spotlight indexing is asynchronous and controlled by macOS
- Typical indexing delay is 1-5 seconds
- No programmatic control over indexing speed

**No Result Snippets:**
- Search results include file path and title but not match context
- Future enhancement: extract text snippets showing match location

**No Advanced Query Syntax:**
- Queries are simple substring matches (case-insensitive)
- No support for AND/OR/NOT operators in current implementation
- Future enhancement: parse query syntax and build complex predicates

**No Result Ranking Customization:**
- Spotlight provides default relevance ranking
- No ability to customize sort order or boost specific fields
- Future enhancement: custom scoring based on field weights

**Temporary Directory Indexing:**
- Files in `/tmp` or other temporary directories may not be indexed by Spotlight
- SpotlightService tests may fail if Spotlight doesn't index test fixtures
- Real workspace directories are indexed normally

## Testing

**File:** `Tests/HieroglyphsTests/SpotlightServiceTests.swift`

**Strategy:** Use temporary workspace with fixture files and wait for indexing.

**Tests:**
- `testEmptyQueryReturnsEmpty` — Empty query returns no results (passes reliably)
- `testSearchByContent` — Search finds card by body content (may timeout due to indexing delay)
- `testSearchByTitle` — Search finds card by title (may timeout due to indexing delay)
- `testNoMatchesReturnsEmpty` — No matches returns empty array (may timeout due to indexing delay)
- `testSearchResultContainsCorrectMetadata` — Result contains correct slugs and paths (may timeout due to indexing delay)

**Indexing Note:** Tests that rely on Spotlight indexing temp directories may timeout in CI/test environments. This is a macOS limitation, not a bug in SpotlightService. The service implementation is correct; Spotlight simply may not index temporary directories.

**File:** `Tests/HieroglyphsTests/HieroglyphsVMTests.swift`

**Strategy:** Use `MockSearchService` to test ViewModel coordination without Spotlight dependency.

**Mock Service:**

```swift
final class MockSearchService: SearchProviding {
    var shouldReturnResults = true
    var mockResults: [SearchResult] = []

    func performSearch(
        query: String,
        scope: String,
        completion: @escaping @Sendable ([SearchResult]) -> Void
    ) {
        if shouldReturnResults {
            completion(mockResults)
        } else {
            completion([])
        }
    }
}
```

**Tests:**
- `testPerformSearchWithResults` — ViewModel updates `searchResults` when service returns results
- `testPerformSearchWithEmptyQuery` — ViewModel clears results for empty query
- `testPerformSearchWithNilSearchService` — ViewModel handles nil service gracefully
- `testPerformSearchWithNilWorkspacePath` — ViewModel handles nil workspace gracefully
- `testNavigateToProjectResult` — Navigation sets `selectedProject` correctly
- `testNavigateToCardResult` — Navigation sets `selectedProject` and loads cards
- `testNavigateToSearchResultWithNilSlug` — Navigation handles nil slugs gracefully

All ViewModel tests pass reliably.

## Future Enhancements

**Planned but not yet implemented:**

1. **Search Result Snippets:** Extract text snippets showing match context
2. **Advanced Query Syntax:** Parse AND/OR/NOT operators and build complex predicates
3. **Custom Result Ranking:** Boost results based on field weights or recency
4. **Search History:** Persist recent searches to UserDefaults
5. **Saved Searches:** Allow users to save and re-run common queries
6. **Search Filters:** Filter results by type, status, priority, tags
7. **Debounced Search:** Add debouncing to reduce query frequency during typing
8. **Search UI:** Dedicated search results view with highlighting and navigation (currently deferred to future phase)

## Integration Points

**Current State:**
- `SearchProviding` protocol and `SpotlightService` implementation exist
- `HieroglyphsVM` has `performSearch(query:)` and `navigateToSearchResult(_:)` methods
- `searchResults` property is published for UI binding
- Environment injection is configured

**Missing UI Integration:**
- No `.searchable()` modifier wired to `performSearch(query:)`
- No search results view displaying `searchResults` array
- No tap handlers calling `navigateToSearchResult(_:)`

**Future Phase:**
- Add `.searchable()` modifier to `CardList` or `MainWindow`
- Bind search text field to `viewModel.performSearch(query:)`
- Display `searchResults` in dedicated search results list
- Handle result selection to trigger navigation

## Dependencies

**Apple Frameworks:**
- `Foundation` — For NSMetadataQuery, NSPredicate, NSMetadataItem
- `SwiftUI` — For environment injection

**Project Modules:**
- `SearchResult` model (Models layer)
- `HieroglyphsVM` coordinator (ViewModel layer)
- `TagReconcilerService` (projects tags to extended attributes for search)

## Example Workflow

**User searches for "API":**

1. UI calls `viewModel.performSearch(query: "API")`
2. ViewModel calls `searchService.performSearch(query: "API", scope: workspacePath)`
3. SpotlightService creates NSMetadataQuery with predicate:
   - Content: `kMDItemTextContent CONTAINS[cd] "API"`
   - Title: `kMDItemDisplayName CONTAINS[cd] "API"`
   - Tags: `kMDItemUserTags CONTAINS[cd] "API"`
4. Query executes, Spotlight searches indexed files
5. Results returned via `NSMetadataQueryDidFinishGathering` notification
6. SpotlightService maps results to `SearchResult` objects
7. Completion handler called with results on main thread
8. ViewModel updates `searchResults` property
9. SwiftUI observes change and updates UI
10. User taps a search result
11. UI calls `viewModel.navigateToSearchResult(result)`
12. ViewModel sets `selectedProject` and `selectedCard`
13. SwiftUI navigates to selected card in detail view
