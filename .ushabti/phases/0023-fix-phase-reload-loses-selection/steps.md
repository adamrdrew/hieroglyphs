# Implementation Steps

## S001: Add Selection Preservation to loadPhases()

**Intent:** Modify `loadPhases()` to preserve the selected phase across reloads by slug, following the same pattern used in `loadCards()`.

**Work:**

1. Open `/Users/adam/Development/hieroglyphs/Sources/Hieroglyphs/HieroglyphsVM.swift`
2. Locate the `loadPhases()` method (around line 289-315)
3. After the guard checks and before the `do` block, capture the current selection slug:
   ```swift
   let previousSlug = selectedPhase?.slug
   ```
4. After successfully loading phases and updating `self.phases`, add selection restoration logic:
   ```swift
   if let previousSlug {
       self.selectedPhase = loadedPhases.first { $0.slug == previousSlug }
   }
   ```
5. Verify the logic mirrors the existing `loadCards()` pattern (lines 336-344)
6. Verify the logic handles all cases:
   - No previous selection (previousSlug is nil): selectedPhase remains nil
   - Previous selection exists in new array: selectedPhase updated to new instance
   - Previous selection does not exist in new array: selectedPhase becomes nil

**Done When:**

- `loadPhases()` captures `selectedPhase?.slug` before loading
- `loadPhases()` restores selection after successful load using slug match
- Code follows same pattern as `loadCards()` selection preservation
- Logic is clear, readable, and handles all edge cases

## S002: Add Tests for Selection Preservation

**Intent:** Add test cases to `HieroglyphsVMTests.swift` to verify selection preservation behavior on phase reload.

**Work:**

1. Open `/Users/adam/Development/hieroglyphs/Tests/HieroglyphsTests/HieroglyphsVMTests.swift`
2. Locate existing phase-related tests (search for `loadPhases`)
3. Add test case: `testLoadPhasesPreservesSelectionWhenPhaseExists`
   - Create MockPhaseService with two phases
   - Set viewModel.selectedProject and sourceDirectory
   - Call loadPhases() to populate initial phases array
   - Set selectedPhase to first phase
   - Call loadPhases() again (simulating FSEvents reload)
   - Assert selectedPhase is not nil
   - Assert selectedPhase.slug matches original phase slug
   - Assert selectedPhase is from the newly loaded array (identity check)
4. Add test case: `testLoadPhasesClearsSelectionWhenPhaseDeleted`
   - Create MockPhaseService with two phases
   - Set viewModel.selectedProject and sourceDirectory
   - Call loadPhases() to populate initial phases array
   - Set selectedPhase to first phase
   - Update mock to return only second phase (simulate deletion)
   - Call loadPhases() again
   - Assert selectedPhase is nil
5. Add test case: `testLoadPhasesPreservesNilSelectionOnReload`
   - Create MockPhaseService with two phases
   - Set viewModel.selectedProject and sourceDirectory
   - Ensure selectedPhase is nil
   - Call loadPhases()
   - Assert selectedPhase is still nil
6. Ensure all new tests pass
7. Run full test suite to verify no regressions

**Done When:**

- Three new test cases added covering selection preservation scenarios
- All new tests pass
- Full test suite passes with no regressions
- Tests verify both identity change and slug preservation
- Tests cover nil selection, preserved selection, and cleared selection cases

## S003: Manual Verification

**Intent:** Manually test the fix in the running app to verify selection preservation works correctly with real FSEvents.

**Work:**

1. Build and run Hieroglyphs: `swift run` from `/Users/adam/Development/hieroglyphs`
2. Open a project with a configured sourceDirectory containing `.ushabti/phases/`
3. Select the Phases section in the sidebar
4. Select a phase in the middle column
5. Verify the detail view shows the phase content
6. In a terminal, run: `echo "# Test change" >> {sourceDirectory}/.ushabti/phases/{selected-phase}/progress.yaml`
7. Wait ~500ms for FSEvents to fire
8. Verify the phase remains selected in the middle column (highlight preserved)
9. Verify the detail view updates to show current content (not stale)
10. In a terminal, rename the selected phase directory to simulate deletion
11. Wait ~500ms for FSEvents to fire
12. Verify selection is cleared (no highlight in middle column)
13. Verify detail view shows "No Phase Selected" empty state
14. Select a different phase
15. Trigger another external change to a non-selected phase
16. Verify the selected phase remains selected and detail view unchanged

**Done When:**

- Selected phase remains selected after external file changes in its directory
- Detail view updates to show newly loaded content
- Selection clears correctly when selected phase is deleted
- No console errors during manual testing
- No visual flicker or stale content displayed
- Behavior matches cards view selection preservation (known working reference)

## S004: Fix Phase.md Incorrect Reference

**Intent:** Correct the misleading claim in phase.md that references `loadCards()` when it should reference `loadPlans()`.

**Work:**

1. Open `.ushabti/phases/0023-fix-phase-reload-loses-selection/phase.md`
2. Locate line 11: "The cards view already handles this correctly via selection preservation logic in `loadCards()`."
3. Replace with: "The plans view already handles this correctly via selection preservation logic in `loadPlans()`."
4. Verify the corrected statement is factually accurate by consulting HieroglyphsVM.swift lines 342-350

**Done When:**

- phase.md references `loadPlans()` instead of `loadCards()`
- Statement is factually correct per codebase

## S005: Document Selection Preservation in viewmodel.md

**Intent:** Add documentation for the selection preservation pattern in `loadPhases()` to keep docs synchronized with code changes.

**Work:**

1. Open `.ushabti/docs/viewmodel.md`
2. Locate the section documenting `loadPlans()` (around line 323)
3. Add a new section immediately after `loadPlans()` documentation for `loadPhases()` that documents:
   - Method signature and purpose
   - Selection preservation pattern (capture previousSlug, reload, restore selection)
   - Behavior for preserved selection, cleared selection, and nil selection
   - Rationale (SwiftUI binding relies on identity, array replacement breaks binding)
   - Pattern consistency with `loadPlans()`
4. Follow existing documentation style and format from `loadPlans()` section

**Done When:**

- `viewmodel.md` documents `loadPhases()` selection preservation pattern
- Documentation explains rationale and pattern consistency with `loadPlans()`
- Section placement follows existing doc structure
- Documentation is clear and matches existing style

## S006: Update file-watching.md for Selection Preservation

**Intent:** Update file-watching documentation to note that phase reloads preserve selection by slug.

**Work:**

1. Open `.ushabti/docs/file-watching.md`
2. Locate the "Phase File Change Handling" section (around line 388)
3. Update the **Behavior:** bullet list to add: "Selection preserved by slug — Selected phase remains selected after reload if phase still exists"
4. Ensure the addition is concise and consistent with existing documentation style

**Done When:**

- `file-watching.md` mentions selection preservation for phase reloads
- Documentation is concise and accurate
- Addition follows existing format
