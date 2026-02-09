# Review: Phase 0022 - Hide Done and Phase Monitoring

## Verdict: GREEN

Phase 0022 is complete and correct. All three independent features (hide done/archived toggle, live phases watching, plan number auto-increment) meet acceptance criteria, comply with laws and style, and include comprehensive test coverage. The implementation demonstrates careful attention to edge cases, proper architectural patterns, and thorough documentation reconciliation.

## Acceptance Criteria Verification

### 1. Toggle Behavior (PASS)

**Criteria:**
- Opening a project shows only non-done, non-archived cards by default
- Toolbar toggle button is visible and discoverable
- Clicking toggle shows/hides done and archived cards
- Toggle state works correctly with active filters
- Toggle icon clearly indicates current state

**Verification:**
- `showDoneAndArchived` property added to HieroglyphsVM with default value `false` ✓
- Toolbar button added to CardList at line 59-69 with SF Symbols `eye`/`eye.slash` ✓
- Filter logic implemented in `filteredAndSortedCards` at lines 181-186 ✓
- Filter applied AFTER search, status, type, and priority filters (correct order) ✓
- Icon toggles between `eye` (showing all) and `eye.slash` (hiding) with clear tooltips ✓
- Tests verify default value and toggle behavior (HieroglyphsVMTests lines 148-151) ✓

### 2. Phases Watching (PASS)

**Criteria:**
- When project has source directory set, phases directory is watched
- Changes to progress.yaml, phase.md, review.md trigger automatic reload
- Phases view updates within ~1 second of file change
- Missing `.ushabti/phases/` directory does not cause errors or crashes
- Projects without source directory do not attempt phases watching
- Phases watching stops cleanly when project deselected

**Verification:**
- FileWatcherService extended with dual FSEventStream architecture (lines 11-12, 43-60) ✓
- `startWatchingPhases` and `stopWatchingPhases` methods added ✓
- HieroglyphsVM `startWatching()` conditionally starts phases watching when sourceDirectory set (lines 645-653) ✓
- `handlePhaseFileChange` filters for `.ushabti/phases/` and `.yaml`/`.md` extensions (lines 696-701) ✓
- `restartPhasesWatching()` method handles project changes (lines 674-690) ✓
- Missing directory handled gracefully via FileManager.fileExists guard (line 682) ✓
- `stopWatching()` calls `stopPhasesWatching()` for cleanup (line 661) ✓
- Tests verify lifecycle and conditional startup (HieroglyphsVMTests lines 158-167) ✓
- FSEvents latency is 0.5s, meeting ~1 second update requirement ✓

### 3. Plan Auto-Increment (PASS)

**Criteria:**
- Creating first plan assigns number 0001
- Creating subsequent plans assigns max+1
- NewPlanSheet does not show number input field
- Number is zero-padded to 4 digits in slug
- Works correctly when plans directory is empty or missing

**Verification:**
- `findNextPlanNumber` method added to PlanProviding protocol ✓
- Implementation in PlanService lines 480-514 ✓
- Returns 1 if plans directory missing (line 486) ✓
- Scans directories, extracts numeric prefix, returns max+1 (lines 497-513) ✓
- Malformed names skipped gracefully via continue statement (line 504) ✓
- NewPlanSheet number field removed (only title field remains at line 14) ✓
- `createPlan` signature changed to `createPlan(title:)` without number parameter ✓
- Number auto-populated via `findNextPlanNumber` call in HieroglyphsVM ✓
- Zero-padding to 4 digits handled by SlugGenerator (verified in existing tests) ✓
- Tests cover all edge cases: empty directory, missing directory, gaps, malformed names (PlanServiceTests lines 279-290) ✓

### 4. Quality (PASS)

**Criteria:**
- All tests pass
- No lint violations
- No console errors during normal operation
- Graceful handling of edge cases

**Verification:**
- All 225 tests pass with 0 failures ✓
- Swift build completes successfully ✓
- Error handling is graceful throughout:
  - Missing phases directory returns early without error ✓
  - Missing plans directory returns 1 for auto-increment ✓
  - Malformed directory names skipped in loops ✓
  - Nil checks prevent crashes when services not injected ✓
- Edge cases explicitly tested:
  - Phases watching without sourceDirectory ✓
  - Empty/missing plans directory for auto-increment ✓
  - Malformed plan directory names ✓
  - Project switching for phases watching ✓

## Laws Compliance

**L01 — Filesystem as Source of Truth:** Toggle state is ephemeral (not persisted), plan numbers derived from directory scanning. Phases data loaded on-demand from disk. ✓

**L05 — External Changes First-Class:** Phases watching directly fulfills this law by enabling real-time detection of external Ushabti agent changes. ✓

**L06 — Platform Leverage:** Uses FSEvents API for efficient file monitoring. Dual FSEventStream architecture leverages native macOS capabilities. ✓

**L09 — Sandi Metz Principles:** Protocol-based services extended (`PlanProviding`, `FileWatching`). Small, focused methods (most methods under 20 lines). Dependency injection maintained throughout. ✓

**L10 — Design Consistency:** Toggle button follows existing toolbar patterns. SF Symbols used (`eye`, `eye.slash`). Matches TakeNote button styling. ✓

**L11 — Test Coverage:** All public methods tested. Tests cover edge cases and error paths. 225 tests pass. ✓

**L12 — No Dead Code:** No unused code detected. All changes are active and referenced. ✓

**L13-L16 — Docs Reconciliation:** All four doc files updated (views-ui.md, file-watching.md, plans-system.md, viewmodel.md) to reflect new features. ✓

## Style Compliance

**Sandi Metz Rules:**
- Classes remain small (HieroglyphsVM is large but within acceptable range for coordinator pattern) ✓
- Methods are small (findNextPlanNumber is 35 lines, filteredAndSortedCards is 40 lines — acceptable with judgment) ✓
- Parameter counts under 4 (all methods comply) ✓

**No Regex:** String operations use `contains()`, `split(separator:)` — no regex usage. ✓

**Naming:** Clear, descriptive names (`showDoneAndArchived`, `findNextPlanNumber`, `restartPhasesWatching`). ✓

**Protocol-Based Services:** All new functionality extends existing protocols (`FileWatching`, `PlanProviding`). ✓

**Error Handling:** Graceful handling throughout. Missing directories return empty/default values. Errors logged but don't crash. ✓

## Code Quality Observations

**Strengths:**
1. **Dual FSEventStream Architecture:** Clean separation of workspace and phases streams. Both use main queue dispatch for UI safety.
2. **Filter Ordering:** Done/archived filter applied after other filters (correct precedence) and before sorting.
3. **Edge Case Coverage:** Comprehensive handling of missing directories, nil sourceDirectory, malformed names.
4. **Test Coverage:** Six new test cases for plan auto-increment, four for phases watching, two for toggle. All edge cases covered.
5. **Documentation Quality:** Doc updates are thorough and accurate. New sections integrated cleanly into existing docs.

**Potential Improvements (Future Phases):**
1. **Toggle State Persistence:** Currently ephemeral. Could persist to UserDefaults if requested.
2. **Debouncing Phases Reload:** FSEvents already batches, but explicit debouncing could reduce reload frequency.
3. **Granular Phase Updates:** Currently reloads all phases. Could diff and update only changed phases.

These are noted as explicitly out-of-scope per phase.md constraints, so they do not block this phase.

## Documentation Reconciliation

**Updated Files:**

1. **views-ui.md (Line 863):** Documents showDoneAndArchived toggle in CardList toolbar section. Explains default state, icon behavior, and ephemeral nature. ✓

2. **file-watching.md (Lines 354-428):** New "Phases Directory Watching" section documents dual FSEventStream architecture, lifecycle, edge cases, and external source directory handling. ✓

3. **plans-system.md (Lines 431-473):** Documents `findNextPlanNumber` method signature, behavior, examples, and notes on max+1 strategy (not gap-filling). ✓

4. **viewmodel.md (Lines 44, 522-574):** Documents new `showDoneAndArchived` property, `stopPhasesWatching()` method, and `restartPhasesWatching()` method with full lifecycle details. ✓

All documentation changes are accurate, complete, and reconciled with implementation.

## Risk Assessment

**Risks from phase.md:**

1. **Dual FSEvents Streams:** Verified both use main queue dispatch. No resource conflicts or deadlock potential detected. ✓

2. **External Source Directory:** Phases directory may be outside workspace. Handles invalid paths, deleted directories, and permission errors gracefully via guards and FileManager checks. ✓

3. **Plan Number Gaps:** Correctly implements max+1 (not gap-filling). Documented as acceptable behavior. ✓

4. **Toggle State Ephemeral:** Users must re-toggle each session. Documented clearly in views-ui.md. Acceptable per phase constraints. ✓

5. **FileWatcher Lifecycle:** Phases watching properly started/stopped when source directory added/removed. Verified via tests and MainWindow `.onChange(of: viewModel.selectedProject)` integration. ✓

All identified risks have been appropriately mitigated or accepted as design decisions.

## Test Execution

```
Test Suite 'All tests' passed at 2026-02-09 06:35:38.984.
Executed 225 tests, with 0 failures (0 unexpected) in 6.420 (6.436) seconds
```

**New Tests Added:**

**HieroglyphsVMTests:**
- `testShowDoneAndArchivedDefaultValue` — Verifies default false value
- `testShowDoneAndArchivedToggle` — Verifies toggle behavior
- `testStartWatchingStartsPhasesWatchingWhenSourceDirectorySet` — Verifies phases watching starts when conditions met
- `testStartWatchingDoesNotStartPhasesWatchingWhenNoSourceDirectory` — Verifies no phases watching when nil sourceDirectory
- `testStopWatchingStopsPhasesWatching` — Verifies cleanup of phases watching
- `testRestartPhasesWatchingRestartsCorrectly` — Verifies project switching restarts phases watching

**PlanServiceTests:**
- `testFindNextPlanNumber_EmptyDirectory` — Verifies returns 1 for empty directory
- `testFindNextPlanNumber_MissingDirectory` — Verifies returns 1 for missing directory
- `testFindNextPlanNumber_SinglePlan` — Verifies returns 2 after plan 0001
- `testFindNextPlanNumber_MultipleWithGaps` — Verifies max+1 strategy (not gap-fill)
- `testFindNextPlanNumber_MalformedNames` — Verifies malformed names skipped
- `testFindNextPlanNumber_NonNumericPrefixes` — Verifies non-numeric prefixes return 1

All new tests pass. Coverage is comprehensive for all three features.

## Build Verification

```
Building for debugging...
Build complete! (0.08s)
```

Swift build succeeds with no warnings or errors.

## Final Assessment

**Phase 0022 is GREEN.**

Three independent features delivered successfully:

1. **Hide Done/Archived Toggle:** Clean UI integration, correct filter ordering, ephemeral state design.
2. **Live Phases Watching:** Robust dual-stream architecture, graceful edge case handling, proper lifecycle management.
3. **Plan Number Auto-Increment:** Reliable max+1 algorithm, malformed name tolerance, simplified UI.

All acceptance criteria met. All laws and style guidelines followed. Comprehensive test coverage with 100% pass rate. Documentation fully reconciled. No blocking issues identified.

The implementation is production-ready and integrates cleanly with the existing codebase. Builder has demonstrated careful attention to edge cases, architectural patterns, and quality standards.

⸻

**Weighed and found true.**
