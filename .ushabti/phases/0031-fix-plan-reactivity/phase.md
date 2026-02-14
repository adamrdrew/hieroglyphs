# Phase 0031: Fix Plan Reactivity

card: selectedplan-not-refreshed-after-plan-mutations

## Intent

Fix plan mutation methods in HieroglyphsVM to refresh `selectedPlan` after reloading plans from disk. Currently, `addCardToPlan()`, `removeCardFromPlan()`, and `updatePlanStatus()` call `loadPlans()` but do not update `selectedPlan` to point to the fresh Plan object in the reloaded array. Since Plan is a value type, the old and new are separate copies, causing views to read stale data.

This phase implements the same pattern already used successfully in `updateProject()`.

## Scope

**In scope:**
- Add `refreshSelectedPlan()` helper method to HieroglyphsVM
- Call `refreshSelectedPlan()` after `loadPlans()` in all three mutation methods:
  - `addCardToPlan()`
  - `removeCardFromPlan()`
  - `updatePlanStatus()`
- Tests verifying selectedPlan is refreshed after each mutation

**Out of scope:**
- PlanDetail.swift changes (no changes needed — views already read from `viewModel.selectedPlan`)
- PlanList.swift changes
- AddCardToPlanSheet.swift changes
- Any Pharaoh views or services
- Any card or project views

## Constraints

- **L17 (UI State Correctness):** Views must always reflect current application state. This fix ensures `selectedPlan` stays synchronized with the reloaded plans array.
- **L09 (Sandi Metz):** Extract refresh into a small, focused helper method with single responsibility.
- **L11 (Test Coverage):** Test that selectedPlan is updated after each mutation method.
- **L12 (No Dead Code):** Remove any workarounds if they exist.

## Acceptance Criteria

1. `refreshSelectedPlan()` helper method exists in HieroglyphsVM
2. `addCardToPlan()` calls `refreshSelectedPlan()` after `loadPlans()`
3. `removeCardFromPlan()` calls `refreshSelectedPlan()` after `loadPlans()`
4. `updatePlanStatus()` calls `refreshSelectedPlan()` after `loadPlans()`
5. Tests verify that `selectedPlan` is refreshed to point to updated Plan object after each mutation
6. All existing tests pass
7. Lint passes

## Risks / Notes

None identified. The pattern is already proven in `updateProject()`.
