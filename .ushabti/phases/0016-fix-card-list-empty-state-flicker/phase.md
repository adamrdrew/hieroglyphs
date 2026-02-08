# Phase 0016: Fix Card List Empty State Flicker

## Intent

Eliminate the visual flicker where the "No Cards" empty state appears briefly when selecting a project that has cards. Currently, when a user clicks on a project's Cards section in the sidebar, the card list momentarily shows the "No Cards" placeholder before the actual cards load from disk, creating a jarring user experience.

The root cause is a race condition in the card loading logic. When `selectedProject` changes, `loadCards()` immediately sets `cards = []` before beginning the async disk read. This causes the CardList view to render the empty state before cards are available. The flicker is most noticeable when switching between projects with cards, but does not occur when switching between sections within the same project.

This Phase introduces a loading state to distinguish between "cards are loading" and "no cards exist", ensuring the empty state only appears when truly appropriate.

## Scope

**In Scope:**
- Add `isLoadingCards: Bool` state property to `HieroglyphsVM` to track card loading state
- Update `loadCards()` to set `isLoadingCards = true` before loading and `false` after completion
- Update `CardList` view logic to check `isLoadingCards` before showing empty state
- Show a loading indicator (ProgressView) when `isLoadingCards` is true and `cards.isEmpty`
- Only show "No Cards" empty state when `!isLoadingCards && cards.isEmpty`
- Ensure loading state resets correctly on error conditions
- Update ViewModel tests to verify loading state transitions

**Out of Scope:**
- Changes to file watching or debouncing behavior
- Optimization of card loading performance (performance is acceptable, this is purely a UX fix)
- Changes to WorkspaceService I/O operations
- Loading indicators for projects list or other views
- Skeleton loaders or progressive rendering (simple ProgressView is sufficient)

## Constraints

**Laws:**
- **L09 (Sandi Metz Principles):** Keep methods small and focused. Loading state management must be clear and explicit.
- **L11 (Test Coverage):** All public methods have tests. Loading state transitions must be tested.
- **L12 (No Dead Code):** No unused state properties or commented-out logic.

**Style:**
- State management should be simple and obvious (avoid complex state machines)
- Loading indicator should follow macOS native patterns (ProgressView with label)
- Minimize disruption to existing card workflow
- Error handling follows "do your best" philosophy (loading state resets on error)

## Acceptance Criteria

- [ ] `HieroglyphsVM` has `isLoadingCards: Bool` property (default false)
- [ ] `loadCards()` sets `isLoadingCards = true` at start of method (before guard checks)
- [ ] `loadCards()` sets `isLoadingCards = false` after successfully loading cards
- [ ] `loadCards()` sets `isLoadingCards = false` in error catch block
- [ ] `loadCards()` sets `isLoadingCards = false` when guard checks fail (nil workspace/project)
- [ ] `CardList` shows ProgressView when `isLoadingCards && cards.isEmpty`
- [ ] `CardList` shows "No Cards" empty state only when `!isLoadingCards && cards.isEmpty`
- [ ] `CardList` shows card list when `!cards.isEmpty` (regardless of loading state)
- [ ] No visual flicker when switching between projects that have cards
- [ ] Empty state still appears correctly for projects that truly have no cards
- [ ] Loading indicator appears briefly when switching projects (acceptable UX)
- [ ] Tests verify `isLoadingCards` transitions through load cycle (start, success, error)
- [ ] Tests verify empty state logic (loading true/false x cards empty/not empty)

## Risks / Notes

**Risks:**
- Loading state must be managed correctly in all code paths (success, error, early return). Missing a reset could cause UI to permanently show loading state.
- `onChange` monitoring of `selectedProject` triggers `loadCards()` on every project change. Ensure loading state does not interfere with rapid switching.

**Notes:**
- This is a focused bug fix affecting only card list loading UX.
- Loading indicator should be simple (ProgressView + text), not elaborate.
- The actual load time is fast (tens of milliseconds). The flicker is the problem, not the duration.
- This pattern may be reusable for future loading states (projects, plans, phases) but we implement only what's needed now.
- Loading state is transient (not persisted across app launches).
