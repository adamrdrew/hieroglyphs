# Steps

## S001: Constrain NewCardSheet body TextEditor

**Intent:** Prevent the new card modal from growing unboundedly when the user types a long card body. The modal should remain at a fixed size and the TextEditor should scroll internally.

**Work:**
- Open `Sources/Hieroglyphs/Views/CardList/NewCardSheet.swift`
- Locate the "Body" section containing the TextEditor (line 47-51)
- Wrap TextEditor in a ScrollView
- Add maxHeight constraint to TextEditor (300pt recommended)
- Keep minHeight: 100 for comfortable initial size
- Verify outer NavigationStack still has `.frame(minWidth: 500, minHeight: 500)`

**Done when:**
- TextEditor has `.frame(minHeight: 100, maxHeight: 300)`
- TextEditor wrapped in `ScrollView`
- Typing beyond 300pt height causes TextEditor to scroll, not modal to grow
- Modal remains at fixed dimensions when testing with long body content

## S002: Fix CardList empty state layout

**Intent:** Prevent filter bar from expanding to fill available space when the card list is empty. The empty state should claim the available space, pushing the filter bar to its intrinsic height.

**Work:**
- Open `Sources/Hieroglyphs/Views/CardList/CardList.swift`
- Locate the Group containing the empty states and List (line 20-47)
- Add `.frame(maxHeight: .infinity)` to the Group to ensure it fills available space
- Test that filter bar stays compact when list is empty and when populated
- Verify no visual layout shift when transitioning between states

**Done when:**
- Filter bar height is consistent whether list is empty or populated
- Empty state view fills available vertical space
- No expansion or layout shift when switching between empty and populated card lists
- Filter bar remains at intrinsic height (~40-50pt) regardless of list state

## S003: Add PlanProviding.deletePlan protocol method

**Intent:** Define the service contract for plan deletion.

**Work:**
- Open `Sources/Hieroglyphs/Services/PlanProviding.swift`
- Add protocol method: `func deletePlan(planSlug: String, projectPath: String) throws`
- Add documentation comment explaining that deletion moves to Trash and is reversible
- No implementation yet (that's next step)

**Done when:**
- Protocol method added with signature and doc comment
- Compiler shows conformance error for PlanService (expected, resolved in next step)

## S004: Implement PlanService.deletePlan

**Intent:** Implement plan deletion by moving the plan directory to macOS Trash.

**Work:**
- Open `Sources/Hieroglyphs/Services/PlanService.swift`
- Implement `deletePlan(planSlug:projectPath:)` conformance
- Construct path to plan directory: `{projectPath}/plans/{planSlug}/`
- Check directory exists; throw `PlanError.planNotFound` if missing
- Use FileManager to move to Trash (NSWorkspace or FileManager.trashItem)
- Log to console on success
- Handle errors (wrap in `PlanError.fileWriteFailed`)

**Done when:**
- Method implemented and compiles
- Calls FileManager or NSWorkspace to move directory to Trash
- Throws appropriate errors for missing plans or failed deletion
- Logs success message on deletion

## S005: Add HieroglyphsVM.deletePlan method

**Intent:** Coordinate plan deletion from the ViewModel layer.

**Work:**
- Open `Sources/Hieroglyphs/HieroglyphsVM.swift`
- Add method: `func deletePlan(_ plan: Plan)`
- Guard that selectedProject and planService exist
- Call `planService.deletePlan(planSlug:projectPath:)`
- Clear selectedPlan if it matches deleted plan
- Call `loadPlans()` to refresh list
- Wrap in do-catch and log errors to console

**Done when:**
- Method implemented and compiles
- Clears selectedPlan if deleted
- Reloads plans after deletion
- Logs errors to console if deletion fails

## S006: Add context menu delete to PlanListEntry

**Intent:** Allow right-click delete from the plan list.

**Work:**
- Open `Sources/Hieroglyphs/Views/PlanList/PlanListEntry.swift`
- Add `.contextMenu` modifier to the row
- Add "Delete Plan" button with `.destructive` role and "trash" icon
- Set button action to update local `@State var planPendingDeletion: Plan?`
- Add `.alert()` modifier for confirmation (same pattern as CardList.swift line 107-125)
- Alert title: "Delete Plan"
- Alert message: "Are you sure you want to delete 'Plan Title'? This will move the plan to Trash."
- Cancel and Delete buttons (Delete calls `viewModel.deletePlan(plan)`)

**Done when:**
- Right-click on plan shows context menu with "Delete Plan" option
- "Delete Plan" button has destructive styling (red)
- Selecting "Delete Plan" shows confirmation alert
- Confirming deletion calls `viewModel.deletePlan()` and refreshes list

## S007: Add toolbar delete button to PlanDetail

**Intent:** Provide a visible delete button in the plan detail view.

**Work:**
- Open `Sources/Hieroglyphs/Views/PlanDetail/PlanDetail.swift`
- Add `.toolbar` modifier with delete button
- Button visible only when `viewModel.selectedPlan != nil`
- Button has `.destructive` role and "trash" icon
- Button placement: `.automatic`
- Button action sets local `@State var planPendingDeletion: Plan?`
- Add `.alert()` modifier for confirmation (same pattern as S006)

**Done when:**
- PlanDetail toolbar shows delete button when plan selected
- Delete button has destructive styling (red)
- Button hidden when no plan selected
- Clicking delete shows confirmation alert
- Confirming deletion calls `viewModel.deletePlan()` and refreshes list

## S008: Test all changes manually

**Intent:** Verify all three fixes work correctly in the running app.

**Work:**
- Build and run app: `swift run` or Xcode
- Test NewCardSheet:
  - Create new card
  - Type long body text (multiple paragraphs, 500+ words)
  - Verify modal stays fixed size
  - Verify TextEditor scrolls internally
  - Verify no layout issues with Save/Cancel buttons
- Test CardList empty state:
  - Select project with no cards (or delete all cards in test project)
  - Enable filter bar via toolbar
  - Verify filter bar stays compact (~40-50pt height)
  - Add a card and verify filter bar height unchanged
- Test Plan deletion:
  - Create test plan with linked cards
  - Right-click plan in PlanList → "Delete Plan"
  - Verify confirmation alert appears with plan title
  - Confirm deletion
  - Verify plan removed from list and directory moved to Trash
  - Verify linked cards still exist in Cards section
  - Create another plan and delete via PlanDetail toolbar button
  - Verify same behavior

**Done when:**
- All three fixes verified working in running app
- No crashes, errors, or unexpected behavior
- Layout improvements observable and stable

## S009: Update documentation

**Intent:** Document the plan deletion feature and UI layout fixes.

**Work:**
- Open `.ushabti/docs/plans-system.md`
- Add section on plan deletion workflow under "PlanProviding Protocol"
- Document `deletePlan(planSlug:projectPath:)` method
- Add note that deletion moves to Trash and does not delete linked cards
- Update Views section to mention delete button and context menu
- Open `.ushabti/docs/views-ui.md`
- Update PlanListEntry and PlanDetail sections to document delete functionality
- Add note in NewCardSheet section about TextEditor constraints
- Add note in CardList section about empty state layout fix

**Done when:**
- plans-system.md updated with deletion documentation
- views-ui.md updated with UI changes
- All changes accurately reflect implementation

## S010: Add deletePlan stub to MockPlanService

**Intent:** Fix test compilation by adding the missing deletePlan method stub to MockPlanService. Tests currently fail because MockPlanService does not conform to the PlanProviding protocol after S003 added the deletePlan method.

**Work:**
- Open `Tests/HieroglyphsTests/HieroglyphsVMTests.swift`
- Locate MockPlanService (around line 1717)
- Add `var shouldThrowOnDeletePlan = false` to the error flags section
- Add `deletePlan(planSlug:projectPath:)` method implementation:
  - If `shouldThrowOnDeletePlan`, throw mock error
  - Otherwise, remove plan from `mockPlans` array by matching slug
- Follow the same pattern as other mock methods

**Done when:**
- MockPlanService conforms to PlanProviding protocol
- Tests compile successfully
- deletePlan mock supports throw behavior for error testing

## S011: Add tests for PlanService.deletePlan

**Intent:** Provide test coverage for the new deletePlan public API method. L11 requires that every public API method has tests.

**Work:**
- Open `Tests/HieroglyphsTests/PlanServiceTests.swift`
- Add test `testDeletePlanMovesDirectoryToTrash`:
  - Create a plan using `createPlan` helper
  - Verify plan directory exists
  - Call `service.deletePlan(planSlug:projectPath:)`
  - Verify plan directory no longer exists at original path
  - Note: Cannot verify Trash contents directly (requires FileManager.trashItem resultingItemURL)
- Add test `testDeletePlanThrowsWhenPlanNotFound`:
  - Call `service.deletePlan` with nonexistent plan slug
  - Verify throws `PlanError.planNotFound`
- Add test `testDeletePlanPreservesLinkedCards`:
  - Create plan with linked cards
  - Delete plan
  - Verify card directory still exists in cards/

**Done when:**
- Three new tests added covering success, error, and card preservation cases
- All tests pass
- Coverage includes both happy path and error path

## S012: Add tests for HieroglyphsVM.deletePlan

**Intent:** Provide test coverage for the ViewModel's deletePlan coordination method. L11 requires that every public API method has tests.

**Work:**
- Open `Tests/HieroglyphsTests/HieroglyphsVMTests.swift`
- Add test `testDeletePlanCallsServiceAndReloadsPlans`:
  - Setup: Create mock workspace and plan service with one plan
  - Set selectedProject and load plans
  - Call `viewModel.deletePlan(plan)`
  - Verify `mockPlanService.deletePlan` was called with correct slug and path
  - Verify plans were reloaded (check mockPlanService.loadPlans call count)
- Add test `testDeletePlanClearsSelectedPlanWhenDeleted`:
  - Setup: Create mock services with one plan
  - Set selectedProject, load plans, set selectedPlan
  - Delete the selected plan
  - Verify `selectedPlan` is nil after deletion
- Add test `testDeletePlanLogsErrorOnFailure`:
  - Setup: Mock service with `shouldThrowOnDeletePlan = true`
  - Call deletePlan
  - Verify no crash (error is logged, not thrown to caller)

**Done when:**
- Three new tests added covering service call, selection clearing, and error handling
- All tests pass
- MockPlanService deletePlan stub works correctly in tests
