# Implementation Steps

## Step 1: Extend ViewModel with card state

**Intent:** Add card state properties and methods to HieroglyphsVM to support card loading and selection.

**Work:**
- Add `cards: [Card]` property to ViewModel
- Add `selectedCard: Card?` property to ViewModel
- Add `searchText: String` property for search filter
- Add `filterStatus: Set<CardStatus>` property for status filter (empty = show all)
- Add `filterType: Set<CardType>` property for type filter (empty = show all)
- Add `filterPriority: Set<Priority>` property for priority filter (empty = show all)
- Add `sortBy: CardSortOption` enum and property (date, priority, status, title)
- Add `sortOrder: SortOrder` property (ascending, descending)
- Add `loadCards()` method that calls `workspaceService.loadCards()` for selected project
- Add `createCard(title:type:status:priority:tags:body:)` method that calls service and reloads cards

**Done when:**
- ViewModel has all new properties and methods defined
- `loadCards()` updates `self.cards` from service (or sets empty array on error)
- `createCard()` calls service, reloads cards, and logs errors
- Code compiles

## Step 2: Create CardSortOption enum

**Intent:** Define sort options as type-safe enum for card sorting.

**Work:**
- Create `Sources/Hieroglyphs/Models/CardSortOption.swift`
- Define enum `CardSortOption: String, CaseIterable` with cases: `created`, `updated`, `priority`, `status`, `title`
- Add `SortOrder` enum if not already defined: `ascending`, `descending`

**Done when:**
- `CardSortOption.swift` exists with all cases
- Enum is `CaseIterable` for UI picker population
- Code compiles

## Step 3: Create CardListEntry view

**Intent:** Build individual card row component showing title, type badge, priority indicator, and status.

**Work:**
- Create `Sources/Hieroglyphs/Views/CardList/CardListEntry.swift`
- Define `CardListEntry` struct view taking `card: Card` parameter
- Layout: HStack with type icon, VStack(title + metadata row), priority indicator
- Type badge: SF Symbol for card type (e.g., `checkmark.circle` for task, `ladybug` for bug, `star` for feature, `note.text` for note) + type label
- Priority indicator: Color or SF Symbol based on priority (e.g., `exclamationmark.circle.fill` for critical/high, subtle for low/medium)
- Status: Show status as text label (e.g., "backlog", "in progress", "done")
- Use `.font(.body)` for title, `.font(.caption)` for metadata
- Use `.foregroundStyle(.secondary)` for supporting elements

**Done when:**
- `CardListEntry.swift` exists
- Entry displays card title, type badge, priority indicator, and status
- Visual layout follows TakeNote's NoteListEntry pattern
- Code compiles and renders correctly in preview

## Step 4: Create CardList view

**Intent:** Build middle column view displaying filtered, sorted, searchable card list.

**Work:**
- Create `Sources/Hieroglyphs/Views/CardList/CardList.swift`
- Define `CardList` struct view
- Access ViewModel via `@Environment(HieroglyphsVM.self)`
- Use `@Bindable` to create bindings for `selectedCard`
- Computed property `filteredAndSortedCards` that:
  - Filters by search text (title contains substring, case-insensitive)
  - Filters by status (if `filterStatus` is not empty, include only cards matching set)
  - Filters by type (if `filterType` is not empty, include only cards matching set)
  - Filters by priority (if `filterPriority` is not empty, include only cards matching set)
  - Sorts by `sortBy` and `sortOrder`
- `List(selection: $bindableViewModel.selectedCard)` rendering `CardListEntry` for each card
- `.searchable(text: $bindableViewModel.searchText)` modifier for search
- `.listStyle(.plain)` or `.listStyle(.inset)` for macOS style
- `.onChange(of: viewModel.selectedProject)` trigger to call `viewModel.loadCards()`
- Toolbar with New Card button (SF Symbol `plus`)
- Show empty state if `viewModel.selectedProject == nil` or `viewModel.cards.isEmpty`

**Done when:**
- `CardList.swift` exists
- List displays cards with selection binding
- Search filters cards by title
- Toolbar has New Card button
- Empty states handled
- Code compiles

## Step 5: Create filter UI component

**Intent:** Provide UI for filtering cards by status, type, and priority.

**Work:**
- Create `Sources/Hieroglyphs/Views/CardList/CardFilterBar.swift`
- Define `CardFilterBar` view
- Access ViewModel via `@Environment(HieroglyphsVM.self)`
- Use `@Bindable` for filter state bindings
- Layout: HStack with filter controls
- Status filter: Menu or Picker for multi-select status values (use `Set` binding)
- Type filter: Menu or Picker for multi-select type values
- Priority filter: Menu or Picker for multi-select priority values
- Use SF Symbols for filter icons (e.g., `line.horizontal.3.decrease.circle` for filter)
- Display active filter count badge if filters applied

**Done when:**
- `CardFilterBar.swift` exists
- Filter controls allow multi-select for status, type, priority
- Filters bind to ViewModel state
- UI is visually consistent with TakeNote patterns
- Code compiles

## Step 6: Create sort UI component

**Intent:** Provide UI for sorting cards by date, priority, status, or title.

**Work:**
- Create `Sources/Hieroglyphs/Views/CardList/CardSortPopover.swift`
- Define `CardSortPopover` view (or inline in CardList toolbar)
- Access ViewModel via `@Environment(HieroglyphsVM.self)`
- Use `@Bindable` for sort state bindings
- Picker for `sortBy` (CardSortOption cases)
- Picker for `sortOrder` (ascending/descending)
- Use SF Symbol `arrow.up.arrow.down` or similar for sort icon
- Follow TakeNote's NoteSortPopover pattern (compact popover or menu)

**Done when:**
- Sort UI exists (as separate file or inline in CardList)
- Sort controls bind to ViewModel state
- Visual design matches TakeNote
- Code compiles

## Step 7: Create NewCardSheet view

**Intent:** Build modal form for creating new cards.

**Work:**
- Create `Sources/Hieroglyphs/Views/CardList/NewCardSheet.swift`
- Define `NewCardSheet` struct view
- Access ViewModel via `@Environment(HieroglyphsVM.self)`
- Access dismiss via `@Environment(\.dismiss)`
- State properties: `title`, `body`, `tags` (string), `type` (CardType), `status` (CardStatus), `priority` (Priority)
- NavigationStack with Form containing:
  - Section for title (TextField, required)
  - Section for type (Picker with all CardType cases)
  - Section for status (Picker with all CardStatus cases)
  - Section for priority (Picker with all Priority cases)
  - Section for tags (TextField, comma-separated)
  - Section for body (TextEditor for markdown content)
- Toolbar with Cancel and Save buttons
- Save button disabled if title is empty
- `saveCard()` method: parse tags, call `viewModel.createCard()`, dismiss

**Done when:**
- `NewCardSheet.swift` exists
- Form has all required fields with sensible defaults
- Save creates card and dismisses sheet
- Cancel dismisses without saving
- Code compiles

## Step 8: Wire CardList into MainWindow

**Intent:** Replace middle column placeholder with CardList view.

**Work:**
- Open `Sources/Hieroglyphs/Views/MainWindow.swift`
- Replace `Text("List")` placeholder with `CardList()`
- Ensure CardList is in scope (import if needed)

**Done when:**
- MainWindow renders CardList in middle column
- App compiles and runs
- Selecting a project triggers card loading and display

## Step 9: Test ViewModel card methods

**Intent:** Verify ViewModel card loading and creation logic with mock service.

**Work:**
- Open or create `Tests/HieroglyphsTests/HieroglyphsVMTests.swift`
- Extend `MockWorkspaceService` to support `loadCards()` and `createCard()` (if not already present)
- Add test: `testLoadCardsSuccess` — verify `loadCards()` updates `cards` property
- Add test: `testLoadCardsWithNilSelectedProject` — verify graceful handling when no project selected
- Add test: `testLoadCardsError` — verify error handling logs and leaves cards empty
- Add test: `testCreateCardSuccess` — verify `createCard()` calls service and reloads cards
- Add test: `testCreateCardError` — verify error handling logs error
- Run tests via `swift test`

**Done when:**
- All new tests exist and cover success and error cases
- Tests pass (`swift test` succeeds)
- ViewModel card methods are verified correct

## Step 10: Manual testing and refinement

**Intent:** Verify UI behavior, visual design, and edge cases through manual testing.

**Work:**
- Run app via `swift run` or build script
- Select a project and verify cards load
- Test search: type in search box, verify cards filter by title
- Test filters: apply status/type/priority filters, verify cards filter correctly
- Test sort: change sort options, verify cards reorder
- Test New Card: open sheet, fill form, save, verify card appears in list
- Test empty states: select project with no cards, verify empty state message
- Test no selection: verify middle column shows appropriate empty state when no project selected
- Verify visual consistency with TakeNote (fonts, colors, spacing, icons)
- Check for any layout issues or visual glitches

**Done when:**
- All UI features work as expected
- Visual design matches TakeNote patterns
- No obvious bugs or visual issues
- Empty states render correctly

## Step 11: Update documentation

**Intent:** Reconcile documentation with new card list UI and ViewModel changes.

**Work:**
- Update `.ushabti/docs/viewmodel.md`:
  - Add new properties: `cards`, `selectedCard`, search/filter/sort state
  - Document `loadCards()` and `createCard()` methods
  - Update state flow diagrams to include card loading
- Update `.ushabti/docs/views-ui.md`:
  - Add CardList, CardListEntry, NewCardSheet, filter/sort UI sections
  - Document layout, behavior, and TakeNote pattern alignment
- Update `.ushabti/docs/architecture.md`:
  - Add CardList components to View Layer section
  - Note CardSortOption in Models Layer
- Mark architecture.md future extensions as partially complete (Card List implemented)

**Done when:**
- All three documentation files updated with card list details
- Docs accurately reflect implemented code
- Future enhancements updated to reflect current state
