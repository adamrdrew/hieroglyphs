# Phase 0023: Fix Phase Reload Loses Selection

card: phase-reload-loses-selection

## Intent

Fix a state management bug where FSEvents-triggered phase reloads cause the selected phase to be deselected while the detail view continues showing stale content. When a filesystem change occurs in the phases directory (e.g., an agent updates progress.yaml), the phases list reloads and clears the selection, but the detail view does not update to reflect the cleared state or the newly loaded data.

The root cause is that `loadPhases()` replaces the entire `phases` array with newly loaded data. SwiftUI's selection binding relies on identity and equality of model objects. When the array is replaced, the old Phase instance in `selectedPhase` no longer exists in the new array, breaking the binding without triggering view updates.

The plans view already handles this correctly via selection preservation logic in `loadPlans()`. This Phase applies the same pattern to phases: preserve selection by slug, restore selection to the updated Phase instance from the reloaded array, and only clear selection if the phase no longer exists on disk.

*Alan was here. If you can read this, the fix works.*

## Scope

**In Scope:**

- Add selection preservation logic to `loadPhases()` method in `HieroglyphsVM`
- Capture `selectedPhase?.slug` before reloading phases
- After successful load, find phase with matching slug in new array
- Restore `selectedPhase` to updated instance if found, nil if not found
- Handle nil slug (no selection) gracefully
- Verify PhaseList selection binding reflects preserved selection
- Verify PhaseDetail displays updated content after reload
- Update ViewModel tests to verify selection preservation behavior

**Out of Scope:**

- Changes to PhaseService or phase file parsing logic
- Changes to FileWatcherService or FSEvents behavior
- Loading indicators for phases (not needed, load is fast)
- Debouncing phase reloads (FSEvents already batches with 0.5s latency)
- Changes to cards or plans selection preservation (already working correctly)
- Changes to PhaseList or PhaseDetail views (binding already correct, only ViewModel needs fix)

## Constraints

**Laws:**

- **L01 (Filesystem as Source of Truth):** Phases reload from disk on every FSEvents trigger. Selection preservation uses slug as stable identifier across reloads.
- **L09 (Sandi Metz Principles):** Keep methods small and focused. Selection preservation logic mirrors existing pattern in `loadCards()`.
- **L11 (Test Coverage):** All public methods have tests. Add test cases for selection preservation on reload.

**Style:**

- Follow existing selection preservation pattern from `loadCards()` (lines 336-344 in HieroglyphsVM.swift)
- Use slug as stable identifier for matching phases across reloads
- Handle edge cases gracefully (nil selection, phase deleted, empty phases array)
- Keep logic clear and explicit (no complex state machines)

## Acceptance Criteria

1. **Selection Preserved on Reload:**
   - When a phase is selected and phases reload, the same phase remains selected
   - The detail view updates to show the newly loaded phase data
   - No visual flicker or empty state during reload

2. **Selection Cleared When Phase Deleted:**
   - When the selected phase no longer exists after reload, selection is set to nil
   - The detail view shows the "No Phase Selected" empty state
   - No errors or crashes when selected phase is missing

3. **Edge Cases:**
   - When no phase is selected and phases reload, selection remains nil
   - When phases array is empty after reload, selection is cleared
   - When selected phase slug does not match any loaded phase, selection is cleared

4. **Existing Behavior Unchanged:**
   - Phase watching continues to trigger reloads correctly
   - FSEvents latency and batching unchanged
   - Phase list display unchanged (same ordering, same entries)
   - Detail view display unchanged (same layout, same content)

5. **Quality:**
   - Tests verify selection preservation when phase exists after reload
   - Tests verify selection cleared when phase deleted after reload
   - Tests verify nil selection remains nil after reload
   - All tests pass, no lint violations
   - No console errors or warnings during normal operation

## Risks / Notes

**Risks:**

- If phase slug changes externally (phase directory renamed), selection will be lost. This is acceptable—slug changes are rare and the user can re-select.
- If multiple phases have identical slugs (should never happen per Ushabti conventions), first match wins. This is acceptable—phase directories are managed by Ushabti agents and slugs are unique by design.

**Notes:**

- This fix uses the same pattern as cards selection preservation (already working correctly in production).
- The bug only manifests when FSEvents fires while a phase is selected. Manual phase selection and initial load work correctly.
- Phase model instances are replaced entirely on each reload. Slug is the only stable identifier across reloads.
- SwiftUI selection binding uses object identity by default. Preserving selection requires explicit slug matching and reassignment.
- No changes needed to PhaseList or PhaseDetail—they already bind correctly. The bug is purely in the ViewModel reload logic.
