# Implementation Steps

## S001: Add toggle state to ViewModel

**Intent:** Add the boolean property that controls done/archived visibility.

**Work:**
- Add `var showDoneAndArchived: Bool = false` to HieroglyphsVM
- Property should be observable (automatic with @Observable)
- Default to false (hide done/archived by default)

**Done when:**
- Property exists in HieroglyphsVM
- Default value is false
- Property is observable by SwiftUI views

---

## S002: Filter done/archived in CardList

**Intent:** Apply the toggle state to card filtering logic.

**Work:**
- Modify `filteredAndSortedCards` computed property in CardList
- After existing filters (search, status, type, priority), add done/archived filter
- Only apply when `viewModel.showDoneAndArchived == false`
- Filter out cards where `status == .done || status == .archived`

**Done when:**
- Cards with done or archived status are excluded when toggle is off
- Cards with done or archived status are included when toggle is on
- Filter works correctly alongside existing filters

---

## S003: Add toolbar toggle button to CardList

**Intent:** Provide visible UI control for the toggle.

**Work:**
- Add ToolbarItem to CardList toolbar (placement: .automatic, before filter button)
- Button toggles `viewModel.showDoneAndArchived`
- Use SF Symbol: `eye` when showing all, `eye.slash` when hiding done/archived
- Add tooltip: "Show done and archived cards" or "Hide done and archived cards"
- Label text: "Show Done" or similar

**Done when:**
- Toolbar button appears in CardList
- Clicking button toggles state
- Icon updates to reflect current state
- Tooltip is clear and accurate

---

## S004: Extend PlanProviding protocol with findNextPlanNumber

**Intent:** Define the contract for plan number auto-increment.

**Work:**
- Add method signature to PlanProviding protocol:
  `func findNextPlanNumber(projectPath: String) throws -> Int`
- Document expected behavior (scan plans directory, return max+1 or 1)

**Done when:**
- Method signature exists in PlanProviding protocol
- Documented with clear description of behavior

---

## S005: Implement findNextPlanNumber in PlanService

**Intent:** Compute next sequential plan number from filesystem.

**Work:**
- Implement `findNextPlanNumber(projectPath:)` in PlanService
- Check if `{projectPath}/plans/` exists; return 1 if missing
- Enumerate plan directories (pattern: NNNN-slug)
- Extract numeric prefix from each directory name (split on "-", parse first component)
- Find max number, return max+1
- Return 1 if no valid plans found
- Handle parsing errors gracefully (skip malformed directory names)

**Done when:**
- Method returns 1 when plans directory is empty or missing
- Method returns max+1 when plans exist
- Malformed directory names are skipped without errors
- Method throws only on critical errors (not on missing directory)

---

## S006: Update HieroglyphsVM.createPlan to use auto-increment

**Intent:** Wire auto-increment into plan creation flow.

**Work:**
- Modify `createPlan(title:number:)` signature to `createPlan(title:)`
- Inside method, call `planService?.findNextPlanNumber(projectPath:)` before creating plan
- Use returned number for plan creation
- Handle nil planService gracefully (log error and return)
- Handle errors from findNextPlanNumber (log and return)

**Done when:**
- createPlan no longer accepts number parameter
- Number is computed automatically via planService
- Errors are logged and handled gracefully

---

## S007: Update NewPlanSheet to remove number field

**Intent:** Remove manual number entry from UI.

**Work:**
- Remove `@State private var number` property from NewPlanSheet
- Remove TextField for number from form
- Update `savePlan()` to call `viewModel.createPlan(title:)` without number
- Update form section to only contain title field

**Done when:**
- NewPlanSheet does not show number input
- savePlan calls createPlan with only title parameter
- Form is clean and focused on title entry

---

## S008: Add phases watching to FileWatcherService

**Intent:** Extend FileWatcher to support multiple directory watching.

**Work:**
- Refactor FileWatcherService to support watching multiple paths simultaneously
- Option 1: Create second FSEventStream for phases directory (store as `phasesStreamRef`)
- Option 2: Watch both paths with single stream (paths array to FSEventStreamCreate)
- Add `startWatchingPhases(path:onChange:)` method
- Add `stopWatchingPhases()` method
- Ensure both streams use main queue dispatch
- Handle cleanup for both streams in stopWatching

**Done when:**
- FileWatcherService can watch workspace and phases simultaneously
- startWatchingPhases and stopWatchingPhases methods exist
- Resource cleanup is correct for both streams
- No memory leaks or crashes when starting/stopping multiple times

---

## S009: Add phases watching logic to HieroglyphsVM

**Intent:** Start phases watching when appropriate conditions are met.

**Work:**
- Modify `startWatching()` method in HieroglyphsVM
- After starting workspace watching, check if selectedProject has sourceDirectory
- If sourceDirectory is set, construct phases path: `{sourceDirectory}/.ushabti/phases/`
- Check if phases directory exists (FileManager.fileExists)
- If exists, call `fileWatcher?.startWatchingPhases(path:onChange:)`
- onChange closure calls `handlePhaseFileChange(url:)`
- Add `stopPhasesWatching()` method to call `fileWatcher?.stopWatchingPhases()`

**Done when:**
- Phases watching starts when selectedProject has sourceDirectory
- Phases watching does not start when sourceDirectory is nil
- Phases watching does not start when phases directory missing (no error)
- handlePhaseFileChange method exists and is called on changes

---

## S010: Implement handlePhaseFileChange in HieroglyphsVM

**Intent:** Reload phases when phase files change.

**Work:**
- Add `handlePhaseFileChange(url:)` method to HieroglyphsVM
- Check if path contains `.ushabti/phases/`
- Check if path contains `.yaml` or `.md`
- If matches, call `loadPhases()`
- Log changes for debugging (optional)

**Done when:**
- Method detects phase file changes correctly
- loadPhases is called when progress.yaml, phase.md, or review.md changes
- Other file changes are ignored
- No unnecessary reloads

---

## S011: Update stopWatching to include phases

**Intent:** Clean up phases watching when stopping.

**Work:**
- Modify `stopWatching()` in HieroglyphsVM to also call `stopPhasesWatching()`
- Ensure phases watching stops when workspace watching stops
- Handle nil fileWatcher gracefully

**Done when:**
- stopWatching stops both workspace and phases watching
- No resource leaks
- Safe to call multiple times

---

## S012: Handle project selection changes for phases watching

**Intent:** Start/stop phases watching when project changes.

**Work:**
- Add logic to restart phases watching when selectedProject changes
- In `.onChange(of: viewModel.selectedProject)` (or similar), stop old phases watching and start new
- Consider lifecycle: stop phases watching for old project, start for new project if has sourceDirectory
- May need to add `restartPhasesWatching()` helper method

**Done when:**
- Changing to project with sourceDirectory starts phases watching
- Changing to project without sourceDirectory stops phases watching
- Changing between projects with sourceDirectory correctly switches watched paths
- No crashes or errors during project switching

---

## S013: Add tests for toggle filtering

**Intent:** Verify done/archived filtering works correctly.

**Work:**
- Add test case to HieroglyphsVMTests or new CardListTests
- Create mock cards with various statuses including done and archived
- Set showDoneAndArchived to false
- Verify filteredAndSortedCards excludes done and archived
- Set showDoneAndArchived to true
- Verify filteredAndSortedCards includes done and archived
- Test interaction with other filters

**Done when:**
- Tests verify toggle correctly filters done/archived cards
- Tests verify toggle works alongside other filters
- All tests pass

---

## S014: Add tests for findNextPlanNumber

**Intent:** Verify plan number auto-increment logic.

**Work:**
- Add test cases to PlanServiceTests
- Test: empty plans directory returns 1
- Test: missing plans directory returns 1
- Test: single plan 0001 returns 2
- Test: plans 0001, 0003, 0005 returns 6 (max+1, not gap-fill)
- Test: malformed directory names are skipped
- Test: plans with non-numeric prefixes are skipped

**Done when:**
- All edge cases tested
- Tests verify correct number computation
- All tests pass

---

## S015: Add tests for phases watching

**Intent:** Verify phases watching starts/stops correctly.

**Work:**
- Add test cases to HieroglyphsVMTests
- Mock FileWatcher with `startWatchingPhasesCalled` flag
- Test: startWatching with sourceDirectory set starts phases watching
- Test: startWatching with nil sourceDirectory does not start phases watching
- Test: stopWatching stops phases watching
- Test: project change restarts phases watching correctly
- Use MockFileWatcher to verify calls

**Done when:**
- Tests verify phases watching lifecycle
- Tests verify phases watching only starts when appropriate
- All tests pass

---

## S016: Manual testing and verification

**Intent:** Verify all three features work correctly in running app.

**Work:**
- Build and run app
- Test hide done/archived toggle:
  - Create cards with various statuses including done and archived
  - Verify default state hides done/archived
  - Toggle and verify done/archived appear
  - Verify toggle works with existing filters
- Test phases watching:
  - Configure project with sourceDirectory pointing to .ushabti/phases/
  - Run Ushabti Builder to modify phase files
  - Verify phases view updates automatically within ~1 second
  - Test with missing phases directory (no errors)
  - Test with nil sourceDirectory (no watching)
- Test plan auto-increment:
  - Create first plan, verify number is 0001
  - Create second plan, verify number is 0002
  - Delete plan 0002, create new plan, verify number is 0003
  - Verify NewPlanSheet does not show number field

**Done when:**
- All three features work correctly in running app
- No console errors or warnings
- UI is responsive and intuitive
- Edge cases handled gracefully

---

## S017: Update documentation

**Intent:** Document new features in relevant doc files.

**Work:**
- Update `.ushabti/docs/views-ui.md`:
  - Document showDoneAndArchived toggle in CardList section
  - Document toolbar button and behavior
- Update `.ushabti/docs/file-watching.md`:
  - Document phases directory watching
  - Document dual FSEvents streams
  - Document lifecycle and edge cases
- Update `.ushabti/docs/plans-system.md`:
  - Document plan number auto-increment
  - Document findNextPlanNumber method
- Update `.ushabti/docs/viewmodel.md`:
  - Document new properties and methods

**Done when:**
- All documentation updated and accurate
- Changes reconciled with code
- No stale information
