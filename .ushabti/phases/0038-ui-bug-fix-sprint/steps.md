# Implementation Steps

## S001: Change "Create Plan from Card" to open modal

**Intent:** Replace immediate plan creation with modal presentation that pre-populates the source card.

**Work:**
- Add `showingNewPlanSheetFromCard: Bool` state property to HieroglyphsVM
- Add `sourceCardForNewPlan: Card?` state property to HieroglyphsVM to track the card being linked
- Add `showNewPlanSheetFromCard(_ card: Card)` method to HieroglyphsVM that sets sourceCardForNewPlan and showingNewPlanSheetFromCard
- Update CardDetail toolbar button to call `viewModel.showNewPlanSheetFromCard(card)` instead of `createPlanFromCard(card)`
- Update CardListEntry context menu to call `viewModel.showNewPlanSheetFromCard(card)` instead of `createPlanFromCard(card)`
- Update NewPlanSheet to accept `@Binding var sourceCard: Card?` parameter (optional, nil for normal plan creation)
- Update NewPlanSheet save logic to link sourceCard after creating plan if sourceCard is not nil
- Update PlanList .sheet modifier to pass `$viewModel.sourceCardForNewPlan` binding
- Test: Click toolbar button or context menu, verify modal opens, enter title, save, verify plan created with card linked

**Done when:** Toolbar button and context menu both open NewPlanSheet modal with source card pre-linked. Plan creation requires user input (title) and confirmation. Plan is created with card already linked when user saves.

## S002: Auto-select newly created card

**Intent:** Newly created cards are automatically selected and displayed in CardDetail.

**Work:**
- Update `HieroglyphsVM.createCard()` method to set `selectedCard` after `loadCards()` completes
- Find newly created card in `cards` array by comparing card properties (title, created timestamp) since slug may be slugified differently
- Alternative: Return created card from `workspaceService.createCard()` and use returned instance for selection
- Test: Create new card, verify CardList selection updates to new card, verify CardDetail displays new card

**Done when:** After clicking Save in NewCardSheet, the new card is automatically selected in CardList and displayed in CardDetail without manual clicking.

## S003: Auto-select newly created plan

**Intent:** Newly created plans are automatically selected and displayed in PlanDetail.

**Work:**
- Update `HieroglyphsVM.createPlan()` method to set `selectedPlan` after `loadPlans()` completes
- Find newly created plan in `plans` array by slug or number (most recent plan will have highest number)
- Test: Create new plan, verify PlanList selection updates to new plan, verify PlanDetail displays new plan

**Done when:** After clicking Save in NewPlanSheet, the new plan is automatically selected in PlanList and displayed in PlanDetail without manual clicking.

## S004: Auto-select newly created project

**Intent:** Newly created projects are automatically selected with Cards section expanded in Sidebar.

**Work:**
- Update `HieroglyphsVM.createProject()` method to set `selectedSection` to `.cards(newProject)` after `loadProjects()` completes
- Find newly created project in `projects` array by slug or title
- Setting selectedSection to .cards(newProject) will trigger MainWindow to load Cards section in middle column
- Test: Create new project, verify Sidebar selection updates to new project's Cards section, verify middle column shows CardList

**Done when:** After clicking Save in NewProjectSheet, the new project is automatically selected with Cards section visible, and the Sidebar disclosure group is expanded.

## S005: Fix Pharaoh view initial status flicker

**Intent:** Read Pharaoh status synchronously on view appear before polling task starts.

**Work:**
- Add `@State private var initialStatusRead = false` flag to PharaohView
- Add `.onAppear` modifier that calls synchronous status read before `.task` modifier runs
- In onAppear: read status via `pharaohService.readStatus(from: sourceDirectory)` and update `status` state
- Set `initialStatusRead = true` after reading
- Ensure `.task` polling modifier only starts after initialStatusRead is true
- Alternative: Perform synchronous read directly in `.task` before starting loop
- Test: Navigate to Pharaoh tab with running process, verify no flash of "not running" state

**Done when:** When navigating to PharaohView with a running Pharaoh process, the initial render shows the correct status (idle/busy/done/blocked) without a flash of "not running" state.

## S006: Update tests for new behavior

**Intent:** Verify existing tests still pass and add coverage for new auto-selection behavior.

**Work:**
- Run swift test to verify existing tests pass
- Add test for `showNewPlanSheetFromCard()` method (sets state correctly)
- Add test for auto-selection in `createCard()` (selectedCard is set)
- Add test for auto-selection in `createPlan()` (selectedPlan is set)
- Add test for auto-selection in `createProject()` (selectedSection is set)
- No view tests needed (SwiftUI views not unit tested per project conventions)

**Done when:** swift test passes with no failures. New tests verify auto-selection state updates.

## S007: Update documentation

**Intent:** Reconcile docs with code changes per L14/L15/L16.

**Work:**
- Update `.ushabti/docs/views-ui.md`:
  - NewPlanSheet section: Document sourceCard parameter and pre-linking behavior
  - CardDetail section: Update toolbar button description (opens modal instead of immediate creation)
  - CardListEntry section: Update context menu description (opens modal instead of immediate creation)
- Update `.ushabti/docs/viewmodel.md`:
  - Add `showNewPlanSheetFromCard()` method documentation
  - Add `showingNewPlanSheetFromCard` and `sourceCardForNewPlan` state properties
  - Update `createCard()`, `createPlan()`, `createProject()` to document auto-selection behavior
  - Update `createPlanFromCard()` documentation (still exists but may be used less frequently)
- Update `.ushabti/docs/plans-system.md`:
  - "Plan Creation from Card" section: Update to describe modal workflow instead of immediate creation
  - NewPlanSheet section: Document sourceCard parameter and card pre-linking

**Done when:** Docs accurately describe new modal-based plan creation workflow, auto-selection behavior, and Pharaoh initial status read. All three doc files updated and committed.
