# Implementation Steps

## Step 1: Create SearchResult model

**Intent:** Define a model representing a single search result (card or project).

**Work:**
- Create `Sources/Hieroglyphs/Models/SearchResult.swift`
- Define `SearchResult` struct with fields:
  - `id: UUID` (unique identifier)
  - `title: String` (display title)
  - `path: String` (absolute file path)
  - `resultType: SearchResultType` (enum: project or card)
  - `projectSlug: String?` (parent project slug if card)
  - `cardSlug: String?` (card slug if card result)
- Conform to `Identifiable`, `Equatable`, `Hashable`
- Define `SearchResultType` enum with cases `.project` and `.card`

**Done when:** Model file exists, compiles, and conforms to required protocols.

---

## Step 2: Create SearchProviding protocol

**Intent:** Define the contract for search services.

**Work:**
- Create `Sources/Hieroglyphs/Services/SearchProviding.swift`
- Define `SearchProviding` protocol with method:
  - `func performSearch(query: String, scope: String, completion: @escaping ([SearchResult]) -> Void)`
- Document parameters (query string, scope path, completion handler)
- Mark protocol as `@MainActor` to ensure thread safety

**Done when:** Protocol file exists, compiles, and defines the search method signature.

---

## Step 3: Create SpotlightService implementation

**Intent:** Implement Spotlight search using NSMetadataQuery.

**Work:**
- Create `Sources/Hieroglyphs/Services/SpotlightService.swift`
- Define `SpotlightService` class conforming to `SearchProviding`
- Implement `performSearch(query:scope:completion:)`:
  - Create NSMetadataQuery instance
  - Configure search scopes to limit to workspace directory
  - Build NSPredicate combining content search and metadata search:
    - Content: `kMDItemTextContent CONTAINS[cd] query`
    - Metadata: `kMDItemDisplayName CONTAINS[cd] query OR kMDItemUserTags CONTAINS[cd] query`
  - Start query with notification observer for `NSMetadataQueryDidFinishGathering`
  - In notification handler, extract results and map to `SearchResult` objects
  - Call completion handler with results on main thread
  - Stop query after results are delivered
- Add property to track active query (stop previous query if new search starts)

**Done when:** Service file exists, compiles, implements protocol, and uses NSMetadataQuery.

---

## Step 4: Create SpotlightServiceEnvironmentKey

**Intent:** Enable dependency injection via SwiftUI environment.

**Work:**
- Create `Sources/Hieroglyphs/Services/SpotlightServiceEnvironmentKey.swift`
- Define `EnvironmentKey` for `SearchProviding`
- Extend `EnvironmentValues` with computed property for `.searchService`
- Set default value to `SpotlightService()` instance

**Done when:** Environment key file exists, compiles, and follows pattern of `WorkspaceServiceEnvironmentKey`.

---

## Step 5: Integrate SearchProviding into HieroglyphsVM

**Intent:** Add search coordination to ViewModel.

**Work:**
- Open `Sources/Hieroglyphs/HieroglyphsVM.swift`
- Add `searchService: SearchProviding?` parameter to initializer
- Add stored property `private let searchService: SearchProviding?`
- Add `@Published var searchResults: [SearchResult] = []` property
- Add `performSearch(query:)` method:
  - Guard for non-empty query and workspace path
  - Call `searchService?.performSearch(query:scope:completion:)`
  - In completion handler, update `searchResults` property
  - Clear `searchResults` if query is empty
- Add `navigateToSearchResult(_:)` method:
  - Parse result type
  - If project: set `selectedProject`
  - If card: set `selectedProject` and `selectedCard`, load cards if needed

**Done when:** ViewModel has search methods, compiles, and updates `searchResults` property.

---

## Step 6: Update App.swift to inject SearchProviding

**Intent:** Wire up SpotlightService dependency at app entry point.

**Work:**
- Open `Sources/Hieroglyphs/App.swift`
- Create `SpotlightService()` instance
- Inject via `.environment(\.searchService, spotlightService)`
- Pass `searchService` to `HieroglyphsVM` initializer

**Done when:** App.swift creates and injects SpotlightService, compiles successfully.

---

## Step 7: Write tests for SearchResult model

**Intent:** Verify model correctness.

**Work:**
- Create `Tests/HieroglyphsTests/Models/SearchResultTests.swift`
- Test initialization with all fields
- Test `Identifiable` conformance (unique IDs)
- Test `Equatable` conformance (equality by ID)
- Test `Hashable` conformance (hash by ID)
- Test both project and card result types

**Done when:** Tests exist, pass, and cover all public properties and conformances.

---

## Step 8: Write tests for SpotlightService

**Intent:** Verify search service behavior.

**Work:**
- Create `Tests/HieroglyphsTests/Services/SpotlightServiceTests.swift`
- Use temporary workspace directory with fixture files
- Test search by content (create card with body text, search for text, verify result)
- Test search by title (create card with title, search for title, verify result)
- Test search by tag (create card with tag, reconcile tag to xattr, search for tag, verify result)
- Test empty query returns empty results
- Test query with no matches returns empty results
- Test scope limiting (create file outside workspace, verify it's not in results)
- Allow for Spotlight indexing delay (add short sleep or retry logic in tests)

**Done when:** Tests exist, pass, and cover all primary search behaviors.

---

## Step 9: Write tests for ViewModel search integration

**Intent:** Verify ViewModel search coordination.

**Work:**
- Open `Tests/HieroglyphsTests/HieroglyphsVMTests.swift`
- Create mock `SearchProviding` implementation for testing
- Test `performSearch(query:)` calls service and updates `searchResults`
- Test `navigateToSearchResult(_:)` sets correct selection for project results
- Test `navigateToSearchResult(_:)` sets correct selection for card results
- Test empty query clears `searchResults`

**Done when:** Tests exist, pass, and cover all ViewModel search methods.

---

## Step 10: Update documentation

**Intent:** Document search system for future phases.

**Work:**
- Create `.ushabti/docs/spotlight-search.md`
- Document `SearchProviding` protocol and `SpotlightService` implementation
- Document `SearchResult` model structure
- Document NSMetadataQuery configuration (scopes, predicates)
- Document ViewModel search methods and navigation logic
- Document known limitations (indexing delay, no snippets)
- Note integration points for future UI enhancements

**Done when:** Documentation file exists and accurately describes search system.

---

## Step 11: Manual verification

**Intent:** Verify end-to-end search behavior in running app.

**Work:**
- Run app (`swift run`)
- Create a project "Search Testing"
- Create a card with:
  - Title: "Spotlight Integration"
  - Body: "Use NSMetadataQuery for fast search across workspace"
  - Tags: ["search", "platform"]
- Wait 5-10 seconds for Spotlight indexing
- Call `viewModel.performSearch(query: "NSMetadataQuery")` (via debug console or temporary UI)
- Verify `searchResults` contains the card
- Call `viewModel.performSearch(query: "platform")`
- Verify `searchResults` contains the card (matched by tag)
- Call `viewModel.performSearch(query: "nonexistent")`
- Verify `searchResults` is empty
- Call `viewModel.navigateToSearchResult(result)` for a card result
- Verify `selectedProject` and `selectedCard` are set correctly

**Done when:** All manual tests pass and search returns expected results.
