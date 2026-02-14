# Review: Phase 0031 — Fix Plan Reactivity

**Reviewed by Overseer on 2026-02-14**

## Summary

Phase implements the `refreshSelectedPlan()` helper method and calls it after all three plan mutation methods (`addCardToPlan()`, `removeCardFromPlan()`, `updatePlanStatus()`). The implementation follows the same pattern already proven in `updateProject()`. All tests pass. Documentation updated. Phase is GREEN.

## Verified

**Acceptance Criteria:**
1. ✓ `refreshSelectedPlan()` helper method exists in HieroglyphsVM (lines 543-558)
2. ✓ `addCardToPlan()` calls `refreshSelectedPlan()` after `loadPlans()` (line 474)
3. ✓ `removeCardFromPlan()` calls `refreshSelectedPlan()` after `loadPlans()` (line 505)
4. ✓ `updatePlanStatus()` calls `refreshSelectedPlan()` after `loadPlans()` (line 537)
5. ✓ Tests verify that `selectedPlan` is refreshed to point to updated Plan object after each mutation (lines 2169-2364 of HieroglyphsVMTests.swift)
6. ✓ All existing tests pass (260 tests, 0 failures)
7. ✓ Lint passes (no swiftlint installed, compiler warnings checked via build)

**Code Quality (L09, L11, L12):**
- `refreshSelectedPlan()` is small, focused, private helper with single responsibility (L09)
- All three new tests follow established patterns and verify correct behavior (L11)
- No dead code introduced (L12)
- Method follows pattern from `updateProject()` exactly (lines 200-212 of HieroglyphsVM.swift)

**Documentation (L14, L15, L16):**
- `viewmodel.md` updated with complete documentation of `refreshSelectedPlan()` method (lines 1014-1063)
- Rationale, usage, examples, and notes clearly documented
- References L17 as the underlying law driving this fix

**UI State Correctness (L17):**
- Implementation ensures views always reflect current application state
- `selectedPlan` now points to fresh Plan object after mutations
- Fixes stale data bug where PlanDetail showed outdated linkedCardSlugs and status

## Issues

None found.

## Required Follow-Ups

None.

## Decision

**Phase status: COMPLETE**

All acceptance criteria met. Implementation is correct, well-tested, and properly documented. The fix addresses the root cause identified in the card: Plan is a value type, and after reloading plans from disk, `selectedPlan` must be updated to point to the fresh object. The pattern is proven (already used in `updateProject()`), and the three new tests verify the fix works for all three mutation methods.

The phase is GREEN. Recommend proceeding to next phase.
