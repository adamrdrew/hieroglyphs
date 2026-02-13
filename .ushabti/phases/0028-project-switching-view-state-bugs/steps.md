# Steps

## S001: Clear selections on project change in HieroglyphsVM

**Intent:** Detect when the project changes (not just the section type) and clear all detail selections.

**Work:**
- Modify `selectSection(_:)` in HieroglyphsVM.swift to detect project changes
- Compare the project extracted from the old and new `selectedSection`
- If the project changed, set `selectedCard`, `selectedPhase`, and `selectedPlan` to nil
- If only the section type changed within the same project, preserve existing cross-section clearing logic

**Done when:**
- `selectSection(_:)` clears all detail selections when the project changes
- Switching from Project A's cards to Project B's cards clears `selectedCard`
- Switching from Project A's phases to Project B's phases clears `selectedPhase`
- Switching from Project A's plans to Project B's plans clears `selectedPlan`
- Manual testing confirms selections cleared on project switch

## S002: Apply `.id()` to middle column view in MainWindow

**Intent:** Force SwiftUI to destroy and recreate middle column views when the project changes.

**Work:**
- In MainWindow.swift, apply `.id(viewModel.selectedProject?.id)` modifier to the middle column content view
- This ensures CardList, PlanList, PhaseList, and PharaohView are recreated when the project changes
- Position the modifier on the switch expression result, not individual cases

**Done when:**
- `.id()` modifier applied to middle column content view
- Switching projects destroys and recreates the middle column view
- Manual testing confirms CardList, PlanList, PhaseList, and PharaohView reset correctly

## S003: Apply `.id()` to detail column view in MainWindow

**Intent:** Force SwiftUI to destroy and recreate detail column views when the project changes.

**Work:**
- In MainWindow.swift, apply `.id(viewModel.selectedProject?.id)` modifier to the detail column content view
- This ensures CardDetail, PlanDetail, PhaseDetail, and PharaohActivityStreamView are recreated when the project changes
- Position the modifier on the switch expression result, not individual cases

**Done when:**
- `.id()` modifier applied to detail column content view
- Switching projects destroys and recreates the detail column view
- Manual testing confirms CardDetail, PlanDetail, PhaseDetail, and PharaohActivityStreamView reset correctly

## S004: Remove selection preservation logic from loadCards()

**Intent:** Remove stale-selection preservation logic that attempts to restore selectedCard by slug after reloading.

**Work:**
- In HieroglyphsVM.swift, examine `loadCards()` method
- Remove any logic that captures `selectedCard?.slug` before loading and attempts to restore it after loading
- When cards are reloaded, `selectedCard` should remain as set by Step S001 (nil after project change, preserved within same project)

**Done when:**
- `loadCards()` no longer attempts to preserve selection by slug
- Manual testing confirms selectedCard clears on project switch
- Manual testing confirms selectedCard preserved when reloading cards within the same project (via file watching)

## S005: Remove selection preservation logic from loadPlans()

**Intent:** Remove stale-selection preservation logic that attempts to restore selectedPlan by slug after reloading.

**Work:**
- In HieroglyphsVM.swift, examine `loadPlans()` method (currently implements slug-based selection preservation per viewmodel.md lines 283-323)
- Remove the slug capture and restoration logic
- When plans are reloaded, `selectedPlan` should remain as set by Step S001 (nil after project change, preserved within same project)

**Done when:**
- `loadPlans()` no longer attempts to preserve selection by slug
- Manual testing confirms selectedPlan clears on project switch
- Manual testing confirms selectedPlan preserved when reloading plans within the same project (via file watching)

## S006: Remove selection preservation logic from loadPhases()

**Intent:** Remove stale-selection preservation logic that attempts to restore selectedPhase by slug after reloading.

**Work:**
- In HieroglyphsVM.swift, examine `loadPhases()` method (currently implements slug-based selection preservation per viewmodel.md lines 362-420)
- Remove the slug capture and restoration logic
- When phases are reloaded, `selectedPhase` should remain as set by Step S001 (nil after project change, preserved within same project)

**Done when:**
- `loadPhases()` no longer attempts to preserve selection by slug
- Manual testing confirms selectedPhase clears on project switch
- Manual testing confirms selectedPhase preserved when reloading phases within the same project (via file watching)

## S007: Add onChange guards for CardList local state

**Intent:** Reset CardList local @State properties when the project changes.

**Work:**
- In CardList.swift, add `.onChange(of: viewModel.selectedProject)` modifier
- In the onChange closure, reset:
  - `showFilterBar` to false
  - `showSortPopover` to false
  - `cardPendingDeletion` to nil
- This ensures filter and sort UI state does not persist across project switches

**Done when:**
- CardList resets local state on project change
- Manual testing confirms filter bar and sort popover close when switching projects
- Manual testing confirms pending deletion state cleared on project switch

## S008: Add onChange guards for PlanDetail local state

**Intent:** Reset PlanDetail local @State properties when the project changes.

**Work:**
- In PlanDetail.swift, add `.onChange(of: viewModel.selectedProject)` modifier
- In the onChange closure, reset:
  - `showingAddCardSheet` to false
  - `showingDispatchConfirmation` to false
- This ensures sheet state does not persist across project switches

**Done when:**
- PlanDetail resets local state on project change
- Manual testing confirms Add Card sheet and Dispatch confirmation dismiss when switching projects

## S009: Verify empty states in all detail views

**Intent:** Ensure all detail views handle nil selections gracefully with appropriate empty states.

**Work:**
- Review CardDetail.swift — verify it shows ContentUnavailableView when selectedCard is nil
- Review PlanDetail.swift — verify it shows ContentUnavailableView when selectedPlan is nil
- Review PhaseDetail.swift — verify it shows ContentUnavailableView when selectedPhase is nil
- Review PharaohActivityStreamView.swift — verify it shows ContentUnavailableView when events are empty
- If any view shows a blank area instead of an empty state, add ContentUnavailableView

**Done when:**
- All detail views show appropriate empty states when selections are nil or data is empty
- Manual testing confirms no blank areas appear when switching projects

## S010: Manual testing across all section types

**Intent:** Verify the fix works correctly for all combinations of projects and sections.

**Work:**
- Create at least two test projects with different data
- For each section type (cards, plans, phases, pharaoh):
  - Select section in Project A
  - Observe data for Project A
  - Switch to same section in Project B
  - Verify Project B's data displayed immediately
  - Verify no stale content from Project A
  - Verify detail pane shows empty state (not stale selection)
  - Switch back to Project A
  - Verify Project A's data displayed correctly (no cached stale state)
- Test all section transitions within same project (cards → plans → phases → pharaoh)
- Verify selections cleared appropriately when changing sections

**Done when:**
- All section types display correct data after project switch
- No stale content observed in any view
- Detail panes show empty states when selections cleared
- Switching back to original project works correctly

## S011: Run tests and verify no regressions

**Intent:** Ensure all existing tests pass and no functionality was broken.

**Work:**
- Run `swift test` to execute all tests
- Verify all tests pass
- If any tests fail, investigate and fix regressions
- Pay special attention to HieroglyphsVMTests and any view-related tests

**Done when:**
- All tests pass
- No regressions in existing functionality

## S012: Update documentation

**Intent:** Document the project switching behavior in the relevant documentation files.

**Work:**
- Update `.ushabti/docs/viewmodel.md` to reflect the removal of selection preservation logic from loadCards(), loadPlans(), and loadPhases()
- Update `.ushabti/docs/views-ui.md` to document the `.id()` modifiers in MainWindow and their purpose
- Add a note explaining that selections are cleared on project change, not preserved across projects
- Clarify that selection preservation within the same project (during file watching reloads) is handled by SwiftUI's identity system via `.id()`, not manual slug matching

**Done when:**
- Documentation updated to reflect new behavior
- Future developers understand why selections are cleared on project change
- Documentation explains the role of `.id()` modifiers in view lifecycle management
