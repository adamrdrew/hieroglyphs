# Phase 0038: UI Bug Fix Sprint

## Intent

Fix three independent UI bugs that degrade user experience: (1) "Create Plan from Card" silently creates a plan when it should open a modal for user input, (2) newly created items (cards, plans, projects) do not auto-select in the UI, requiring manual searching, and (3) Pharaoh view flickers between "not running" and "running" states on navigation due to stale initial state.

Each fix is small, independent, and improves functional correctness per L17 (UI State Correctness) and L18 (Design Is How It Works).

## Scope

**In scope:**
- Change "Create Plan from Card" toolbar button and context menu action to open NewPlanSheet with source card pre-linked
- Auto-select newly created cards, plans, and projects in their respective lists and display in detail view
- Read Pharaoh status synchronously on PharaohView appear before polling loop starts

**Out of scope:**
- Refactoring existing plan creation logic beyond what's needed for the modal fix
- Changing NewPlanSheet UI beyond adding card pre-population logic
- Generalizing selection patterns (each fix handles its specific case)
- Performance optimization of status reads

## Constraints

**Laws:**
- L17 (UI State Correctness): Views must always reflect current state; selection must update when context changes; no stale content from previous selections; async operations must provide visual feedback
- L18 (Design Is How It Works): Controls must communicate their state; if an operation changes state, the user must see it; views must reset when context changes

**Style:**
- Follow existing modal/sheet patterns (NewCardSheet, NewProjectSheet for modal structure)
- Follow existing selection management patterns (ViewModel methods for updating selectedCard, selectedPlan, selectedProject)
- Follow existing Pharaoh status reading patterns (PharaohService.readStatus)
- Small, focused changes per Sandi Metz principles

**Relevant Docs:**
- `.ushabti/docs/views-ui.md` — View structure, sheet patterns, toolbar button patterns
- `.ushabti/docs/viewmodel.md` — Selection state management, plan creation methods
- `.ushabti/docs/plans-system.md` — Plan creation workflow, createPlanFromCard method

## Acceptance Criteria

1. **Create Plan from Card opens modal:**
   - Toolbar button in CardDetail calls `viewModel.showNewPlanSheetFromCard(card)` instead of `createPlanFromCard(card)`
   - Context menu in CardListEntry calls `viewModel.showNewPlanSheetFromCard(card)` instead of `createPlanFromCard(card)`
   - NewPlanSheet accepts optional `sourceCard: Card?` parameter
   - When sourceCard is provided, plan is created with card already linked
   - User can edit plan title before saving
   - Modal follows standard sheet patterns (constrained dimensions, Cancel/Save toolbar)

2. **Auto-select newly created items:**
   - After creating card: `selectedCard` is set to new card, CardDetail displays new card
   - After creating plan: `selectedPlan` is set to new plan, PlanDetail displays new plan
   - After creating project: `selectedSection` is set to new project's Cards section, Sidebar expands to show new project
   - Selection updates happen after create operation completes and list reloads

3. **Pharaoh view no flicker:**
   - PharaohView reads status synchronously in `.onAppear` before `.task` polling starts
   - Initial render shows correct status (idle/busy/blocked/done, not notRunning)
   - No flash of "not running" screen when navigating to running Pharaoh
   - Polling continues to update status every 2 seconds as before

4. **Tests pass:**
   - All existing tests continue to pass
   - Build succeeds with no warnings
   - swift test completes successfully

5. **Docs reconciled:**
   - `.ushabti/docs/views-ui.md` updated to reflect NewPlanSheet sourceCard parameter
   - `.ushabti/docs/viewmodel.md` updated to reflect showNewPlanSheetFromCard method and auto-selection behavior
   - `.ushabti/docs/plans-system.md` updated to reflect modal-based plan creation from card

## Risks / Notes

- **Independent fixes:** Each of the three bugs is isolated from the others. They can be implemented in any order and each should compile and pass tests independently.
- **Minimal refactoring:** Changes should be surgical — modify existing methods and add small helper methods. Avoid large-scale refactoring of plan creation or selection management.
- **Status read timing:** The synchronous status read in PharaohView.onAppear should be fast (local filesystem read), but if it blocks UI rendering noticeably, consider adding a brief ProgressView during initial load.
- **Selection timing:** Auto-selection must happen after list reload completes to ensure the new item exists in the array. Use completion callbacks or await reload if using async methods.
