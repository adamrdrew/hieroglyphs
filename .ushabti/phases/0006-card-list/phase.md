# Phase 6: Card List

## Intent

Implement the middle column of the three-column NavigationSplitView to display cards for the selected project. The CardList shows filterable, sortable card entries with visual indicators for type, status, and priority. Users can search cards, filter by metadata, sort by multiple criteria, and create new cards. This completes the second column of the UI, enabling users to view and navigate their project's cards.

## Scope

**In scope:**
- `CardList` view displaying cards from selected project
- `CardListEntry` view showing card title, type badge, priority indicator, and status
- Filter UI for status, type, priority, and tags
- Sort UI for date, priority, status, and title
- `.searchable()` modifier for card search
- New Card button in toolbar
- `NewCardSheet` form for creating cards
- ViewModel extensions for card state: `cards`, `selectedCard`, `loadCards()`, `createCard()`
- Integration with `WorkspaceService.loadCards()` and `WorkspaceService.createCard()`
- Empty state UI when no project selected or no cards exist
- Tests for ViewModel card methods

**Out of scope:**
- Card detail editor (Phase 7)
- Card editing/updating (Phase 7)
- Card deletion (future)
- Spotlight search integration (future)
- File watching and external change detection (future)
- Tag reconciliation to extended attributes (future)
- Drag and drop reordering (future)
- Multi-selection (future)

## Constraints

**Laws:**
- L01 (Filesystem as Source of Truth): Cards loaded from disk via WorkspaceService on every `loadCards()` call
- L02 (Opinionated on Write, Laissez-Faire on Read): New cards use UI-provided values; display shows raw frontmatter values
- L09 (Sandi Metz): Small, focused views; ViewModel coordinates, service performs I/O
- L10 (Design Consistency with TakeNote): Follow NoteList/NoteListEntry patterns, `.searchable()`, toolbar buttons, SF Symbols
- L11 (Test Coverage): ViewModel `loadCards()` and `createCard()` must have tests

**Style:**
- Small views (each component in own file: CardList, CardListEntry, NewCardSheet, filter/sort UI)
- Views observe ViewModel via `@Environment(HieroglyphsVM.self)`
- Filter and sort state held in ViewModel (UI binds to it)
- TakeNote patterns: `.searchable()`, toolbar with New button, sectioned list by status

## Acceptance Criteria

1. **CardList renders for selected project**: When a project is selected in Sidebar, CardList displays all cards loaded from `{workspacePath}/{projectSlug}/cards/`
2. **CardListEntry shows metadata**: Each entry displays card title, type badge (SF Symbol + label), priority indicator (color/icon), and status
3. **Filter UI works**: Filter bar allows filtering by status (multi-select), type (multi-select), priority (multi-select), and tag (text input or picker)
4. **Sort UI works**: Sort options include date (created/updated), priority, status, and title (ascending/descending)
5. **Search works**: `.searchable()` modifier filters cards by title match (case-insensitive substring)
6. **New Card button creates cards**: Toolbar button opens NewCardSheet; form creates card via ViewModel; list refreshes to show new card
7. **Empty states handled**: Show appropriate message when no project selected, or when selected project has no cards
8. **ViewModel card state works**: `cards`, `selectedCard`, `loadCards()`, and `createCard()` methods function correctly
9. **Tests pass**: ViewModel tests for `loadCards()` and `createCard()` with mock service
10. **UI matches TakeNote patterns**: Uses `.searchable()`, toolbar buttons, SF Symbols, and visual layout consistent with TakeNote's NoteList

## Risks / Notes

- **Filter/sort complexity**: Filter and sort UI may require careful state management. If complexity grows, consider extracting filter/sort logic to separate helper types.
- **Performance with many cards**: Loading all cards on project selection is simple but may be slow for large projects (100+ cards). Acceptable for v1; future optimization may add lazy loading or caching.
- **Search scope**: Current search is in-memory string matching. Spotlight integration deferred to future phase.
- **Card selection state**: `selectedCard` binding enables future detail editor (Phase 7) but is not used in this phase beyond selection tracking.
