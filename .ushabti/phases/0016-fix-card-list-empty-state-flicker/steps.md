# Implementation Steps

## S001: Add loading state to HieroglyphsVM

**Intent:** Introduce state property to track whether cards are currently being loaded from disk.

**Work:**
- Add `var isLoadingCards: Bool = false` property to `HieroglyphsVM` class
- Property should be `@Observable` (part of the class marked with `@Observable`)
- Initialize to `false` (default state is not loading)
- Add comment explaining the property's purpose (tracks card loading state to prevent empty state flicker)

**Done when:**
- Property exists in `HieroglyphsVM.swift`
- Property is observable (SwiftUI views can bind to it)
- Default value is `false`

## S002: Update loadCards() to manage loading state

**Intent:** Set loading state to true before loading begins and false after completion or error.

**Work:**
- At the start of `loadCards()` (before guard checks), set `isLoadingCards = true`
- Before each `return` statement (guard failures), set `isLoadingCards = false`
- After successfully setting `self.cards = loadedCards`, set `isLoadingCards = false`
- In the `catch` block, set `isLoadingCards = false` before setting `cards = []`
- Ensure all code paths reset loading state (no path can leave it permanently true)

**Done when:**
- `isLoadingCards = true` appears at method start
- `isLoadingCards = false` appears in all exit paths (guard returns, success, error)
- No code path can leave `isLoadingCards` stuck as `true`

## S003: Update CardList to check loading state before showing empty state

**Intent:** Prevent "No Cards" empty state from showing while cards are loading.

**Work:**
- In `CardList.swift`, update the main `Group` conditional logic
- Change from `if viewModel.cards.isEmpty` to check both loading state and cards
- Show ProgressView when `isLoadingCards && cards.isEmpty`
- Show "No Cards" empty state when `!isLoadingCards && cards.isEmpty`
- Show card list when `!cards.isEmpty` (loading state doesn't matter if cards exist)
- Order: check selectedProject nil first, then loading state, then empty state, finally card list

**Done when:**
- `CardList` checks `viewModel.isLoadingCards` in conditional logic
- Loading indicator appears when loading and no cards cached
- Empty state only appears when not loading and no cards exist
- Card list shows immediately when cards are available

## S004: Implement loading indicator view

**Intent:** Display a native macOS loading indicator while cards are being loaded.

**Work:**
- In `CardList.swift`, create a computed property or private view for loading state
- Use `ProgressView()` with a label explaining what's loading
- Keep it simple: vertical stack with progress view and "Loading cards..." text
- Follow macOS native patterns (no custom styling needed)
- Should look similar to other `ContentUnavailableView` uses for consistency

**Done when:**
- Loading view exists and displays ProgressView
- Loading view appears when `isLoadingCards && cards.isEmpty`
- Visual appearance is consistent with app design language
- Loading view is centered in the available space

## S005: Test loading state transitions in HieroglyphsVM

**Intent:** Verify that loading state correctly transitions through all code paths.

**Work:**
- In `HieroglyphsVMTests.swift`, add test case `testLoadCardsLoadingStateTransitions`
- Verify `isLoadingCards` is `false` initially
- Mock service to return cards successfully
- Call `loadCards()` and verify state was `true` during load (check via mock callback)
- Verify state is `false` after successful load
- Test error path: mock throws error, verify state is `false` after error
- Test guard failure: call with nil workspace, verify state is `false`

**Done when:**
- Test verifies loading state is false initially
- Test verifies loading state transitions to true during load
- Test verifies loading state returns to false on success
- Test verifies loading state returns to false on error
- Test verifies loading state returns to false on guard failure

## S006: Test empty state logic in CardList rendering

**Intent:** Verify that CardList shows correct view based on loading and cards state.

**Work:**
- This is a view test, which we typically don't unit test per style guide
- Manual testing will verify the behavior
- Document test scenarios in progress notes:
  - Project with cards: should show loading briefly, then cards (no empty state flicker)
  - Project with no cards: should show loading briefly, then "No Cards" empty state
  - Switching between projects: loading indicator appears on each switch
  - Error loading cards: should show "No Cards" empty state (loading resets to false)

**Done when:**
- Manual test scenarios documented in progress notes
- Manual testing confirms no flicker when switching to projects with cards
- Manual testing confirms empty state appears correctly for empty projects
- Manual testing confirms loading indicator appears briefly during loads

## S007: Verify no visual flicker regression

**Intent:** Confirm the bug is fixed and no regressions were introduced.

**Work:**
- Run the app and test card list behavior across multiple scenarios
- Create a test workspace with mix of projects (some with cards, some without)
- Switch between project Cards sections rapidly
- Verify "No Cards" does not flash when switching to projects with cards
- Verify loading indicator appears briefly (acceptable)
- Verify empty state still appears for truly empty projects
- Verify existing card functionality works (create, edit, filter, sort, search)

**Done when:**
- No "No Cards" flicker when switching to projects with cards
- Loading indicator appears briefly during card loads (acceptable UX)
- Empty state shows correctly for projects with no cards
- All existing card functionality works without regression
- Manual testing confirms bug is fixed
