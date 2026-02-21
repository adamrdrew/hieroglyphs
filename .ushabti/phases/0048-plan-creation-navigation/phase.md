# Phase 0048: Plan Creation Navigation

## Intent

Ensure that creating a plan from a card automatically switches to the plan view, eliminating the need for manual navigation. The current behavior leaves the user in the card view with no visual feedback after clicking "Create Plan", causing confusion. The modal appears in the plan view hierarchy but the user never sees it because they remain in the cards view.

## Scope

**In scope:**
- Modify `createPlan()` in HieroglyphsVM to switch `selectedSection` to `.plans(project)` after successful plan creation
- Navigation happens immediately after plan creation completes
- Works for both plan creation from card and from plan list new button
- Preserves auto-selection of newly created plan

**Out of scope:**
- Changes to NewPlanSheet UI
- Changes to plan creation logic beyond navigation
- Changes to modal presentation mechanism
- Changes to card-to-plan linking logic

## Constraints

- L09: Sandi Metz principles — small focused changes
- L17: UI State Correctness — view must reflect current state immediately
- L18: Design Is How It Works — operations must provide visible feedback

## Acceptance Criteria

1. When user creates a plan from a card (via context menu or toolbar button), the app switches to the plan view for that project
2. NewPlanSheet modal appears immediately in the plan view (no longer hidden in unvisited view)
3. After user saves the plan, the app remains in the plan view with the new plan selected
4. Existing plan creation from plan list continues to work correctly
5. All plan creation code paths result in plan view navigation
6. Tests verify that `selectedSection` is set to `.plans(project)` after plan creation
7. Build passes via `./Scripts/build-app.sh`

## Risks / Notes

This is a simple navigation fix. The modal presentation is already correct — it lives in PlanList which is bound to `showingNewPlanSheetFromCard`. The missing piece is switching to the plan view so the user actually sees the PlanList and its modal.

The fix happens in `createPlan()` after successful plan creation but before auto-selecting the new plan. Set `selectedSection = .plans(selectedProject)` to trigger navigation.
