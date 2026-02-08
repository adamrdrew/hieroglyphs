# Implementation Steps

## S001: Wire Filter Bar into CardList Toolbar

**Intent:** Enable users to filter cards by status, type, and priority via visible UI controls.

**Work:**

1. Add `@State private var showFilterBar = false` to `CardList`
2. Add toolbar button (SF Symbol: `line.horizontal.3.decrease.circle`) that toggles `showFilterBar`
3. Conditionally render `CardFilterBar` below toolbar when `showFilterBar` is true
4. Update toolbar button visual state when filters are active (use `.fill` variant or apply accent color)

**Done when:**

- User can click toolbar button to show/hide filter bar
- Filter bar appears inline below toolbar (not as popover or sheet)
- Toolbar button visually indicates when filters are active
- Filters function correctly (existing `CardFilterBar` logic unchanged)

## S002: Wire Sort Popover into CardList Toolbar

**Intent:** Enable users to sort cards by various criteria via toolbar popover.

**Work:**

1. Add toolbar button (SF Symbol: `arrow.up.arrow.down`)
2. Use `.popover()` modifier to present `CardSortPopover` anchored to button
3. Pass `@Bindable` ViewModel to popover for sort state binding

**Done when:**

- User can click toolbar button to show sort popover
- Popover anchors to toolbar button
- Sort options update `viewModel.sortBy` and `viewModel.sortOrder`
- Card list reflects sort changes immediately

## S003: Add Card Management Buttons to Plan Detail

**Intent:** Provide discoverable actions for viewing and removing linked cards in plan detail view.

**Work:**

1. Modify linked card rows in `PlanDetail` to include two icon buttons:
   - View Card button (SF Symbol: `eye` or `doc.text`) — calls method to navigate to card
   - Remove from Plan button (SF Symbol: `minus.circle` or `trash`, destructive styling) — calls `viewModel.removeCardFromPlan()`
2. Add `.help()` tooltips to both buttons
3. Implement navigation logic: set `viewModel.selectedSection` to `.cards(project)` and `viewModel.selectedCard` to target card
4. Keep existing context menu as secondary interaction path

**Done when:**

- Each linked card row shows visible action buttons
- View Card button navigates to card in card list (selects card in middle column, updates detail)
- Remove from Plan button calls existing removal method
- Tooltips explain button actions
- Existing context menu still works

## S004: Add Filtering to Card Selection Sheet

**Intent:** Help users narrow card list when adding cards to plans.

**Work:**

1. Add `@State` variables to `AddCardToPlanSheet` for search text and filter sets (status, type, priority)
2. Add `.searchable(text:)` modifier for title search
3. Add filter menus (status, type, priority) using Menu/Toggle pattern from `CardFilterBar`
4. Filter `availableCards` computed property through search and active filters before rendering
5. Filter state is local to sheet (not shared with main card list filters)

**Done when:**

- User can search cards by title (case-insensitive substring match)
- User can filter by status, type, and priority via menu toggles
- Available cards list updates immediately when filters change
- Filter state is independent from main card list filters

## S005: Generalize Plan Status Cascade to All Statuses

**Intent:** Ensure plan status changes consistently update linked card statuses across all plan status transitions.

**Work:**

1. Define status mapping in `PlanService`:
   - `.planning` → `CardStatus.backlog`
   - `.ready` → `CardStatus.todo`
   - `.done` → `CardStatus.done`
2. Rename `markLinkedCardsAsDone` to `updateLinkedCardStatuses(plan:status:projectPath:)`
3. Update method to accept target card status as parameter
4. Update `updatePlanStatus` to call generalized method on every status change (not just `.done`)
5. Apply mapped card status to all linked cards

**Done when:**

- Changing plan status to `.planning` sets linked cards to `backlog`
- Changing plan status to `.ready` sets linked cards to `todo`
- Changing plan status to `.done` sets linked cards to `done`
- Card files are written to disk with updated status and timestamp
- Existing `markLinkedCardsAsDone` logic is preserved in generalized method

## S006: Add Tests for New Public Methods

**Intent:** Ensure test coverage for newly exposed or modified public APIs.

**Work:**

1. Add test for filter bar visibility toggle in `CardList` (if testable via SwiftUI patterns)
2. Add test for sort popover presentation (if testable via SwiftUI patterns)
3. Add tests for `updateLinkedCardStatuses` in `PlanServiceTests`:
   - Test each status mapping (planning→backlog, ready→todo, done→done)
   - Test that card files are written with correct status
   - Test that card updated timestamp changes
4. Verify existing tests still pass

**Done when:**

- New service method has test coverage for all status mappings
- All existing tests pass
- No new test failures introduced

## S007: Update Documentation

**Intent:** Reconcile docs with code changes per L14, L15, L16.

**Work:**

1. Review `.ushabti/docs/plans-system.md` for status cascade behavior
2. Update method signature documentation for renamed/new methods
3. Review `.ushabti/docs/views-ui.md` for `CardList` toolbar additions and `AddCardToPlanSheet` filtering
4. Add notes on filter/sort state ephemerality (not persisted)

**Done when:**

- Plans system docs reflect generalized status cascade
- Views docs describe new toolbar buttons and filter capabilities
- Ephemeral nature of filter/sort state is documented
- No stale method references remain
