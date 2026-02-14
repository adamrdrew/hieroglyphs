# Review: Phase 0032 — Multi-Select Add Cards to Plan

## Summary

Phase 0032 is COMPLETE. All acceptance criteria verified. Implementation is correct, tests pass, and the feature works as specified.

## Verified

### Acceptance Criteria

1. **Set-based selection binding** — Verified. `AddCardToPlanSheet` declares `@State private var selectedCards: Set<Card.ID> = []` (line 10) and binds it to the List (line 18). Selection type changed from `Card?` to `Set<Card.ID>` as required.

2. **Count-aware button label** — Verified. `addButtonLabel` computed property (lines 170-179) returns:
   - "Add" when count is 0
   - "Add Card" when count is 1
   - "Add \(count) Cards" when count > 1

3. **Disabled when empty** — Verified. Button `.disabled(selectedCards.isEmpty)` at line 120.

4. **Batch method called on click** — Verified. `addCard()` method (lines 181-187) builds `cardSlugs` array from `selectedCards` Set by filtering `filteredCards` and extracting `.slug`, then calls `viewModel.addCardsToPlan(cardSlugs:planSlug:)`.

5. **Batch addition method exists** — Verified. `HieroglyphsVM.addCardsToPlan(cardSlugs:planSlug:)` at lines 480-512. Iterates cardSlugs, calls `planService.addCardToPlan()` for each, then calls `loadPlans()` once and `refreshSelectedPlan()` once. Method is 33 lines (including guards and error handling) — focused and clear.

6. **Tests verify service call count** — Verified. `test_addCardsToPlanCallsServiceForEachCard` at lines 2238-2286 creates 3 card slugs, calls batch method, asserts `mockPlan.addCardCallCount == 3`. Test passes.

7. **Already-linked cards filtered** — Verified. Existing `availableCards` computed property (lines 130-134) filters out cards already in `plan.linkedCardSlugs`. No changes needed — filtering logic remains correct.

### Code Quality

- **L09 (Sandi Metz):** Methods are small and focused. `addButtonLabel` is 9 lines, `addCard()` is 6 lines, `addCardsToPlan()` is focused on looping and reloading.
- **L11 (Test Coverage):** New batch method has test coverage. All 265 tests pass.
- **L18 (Design Is How It Works):** Button label clearly communicates action count. Disabled state prevents empty submission.
- **No dead code:** No unused symbols or commented-out code.
- **Composition over inheritance:** Uses Set binding and maps to slugs via functional composition.

### Tests

Ran `swift test` — all 265 tests pass, including new test `testAddCardsToPlanCallsServiceForEachCard`.

## Issues

None.

## Required Follow-Ups

None.

## Decision

**Status: COMPLETE**

All acceptance criteria met. Implementation follows laws and style. Tests pass. Card status updated to done.

---

Stone set true. The scales balance. This Phase is GREEN.
