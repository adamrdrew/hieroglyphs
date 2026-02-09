# Phase 0022: Hide Done and Phase Monitoring

## Intent

Improve developer ergonomics during active Ushabti workflows by reducing visual clutter, enabling real-time phase monitoring, and eliminating manual plan numbering. These three independent improvements remove friction from daily development tasks.

Done and archived cards accumulate over a project's lifetime, cluttering the card list when developers only care about active work. The phases view goes stale while Ushabti agents are actively building, requiring manual navigation to refresh. Plan numbers require manual counting and entry, creating opportunity for collision and cognitive overhead.

## Scope

**In scope:**

### Hide Done/Archived Toggle
- Add `showDoneAndArchived: Bool` state property to HieroglyphsVM (default: false)
- Add toolbar toggle button to CardList (SF Symbol, tooltip, follows existing toolbar patterns)
- Filter done and archived cards in `filteredAndSortedCards` when toggle is off
- Toggle works alongside existing filter system (if filters active AND toggle off, done/archived excluded regardless of filter state)
- Toggle state is ephemeral (in-memory only, not persisted)

### Live Phases Watching
- Extend FileWatcherService to watch phases directory when project has source directory
- Add phases directory watching logic to HieroglyphsVM.startWatching()
- Detect changes to `{sourceDirectory}/.ushabti/phases/**/*.yaml` and `{sourceDirectory}/.ushabti/phases/**/*.md`
- Call `loadPhases()` when phase file changes detected
- Handle missing `.ushabti/phases/` directory gracefully (no watching, no error)
- Handle source directory not set (no watching)
- Stop phases watching when project deselected or app terminates

### Plan Number Auto-Increment
- Add `findNextPlanNumber(projectPath:) throws -> Int` method to PlanProviding protocol
- Implement in PlanService: scan plans directory, find highest number, return +1 (or 1 if no plans)
- Remove number TextField from NewPlanSheet
- Auto-populate number in NewPlanSheet.savePlan() via viewModel method
- Update createPlan signature if needed to accept optional number (or always compute internally)

**Out of scope:**
- Persisting toggle state to UserDefaults or config
- Filtering by other statuses (backlog, triage, todo, in-progress)
- Debouncing or throttling phases reload (FSEvents already batches with 0.5s latency)
- Watching plans directory (separate from phases directory)
- Renumbering existing plans
- Plan number collision detection beyond auto-increment

## Constraints

**Laws:**
- **L01:** Filesystem remains source of truth. Toggle state is ephemeral view state.
- **L05:** Phases watching directly fulfills external changes first-class principle.
- **L06:** Leverage existing FSEvents infrastructure for phases watching.
- **L09:** Protocol-based services (extend PlanProviding), small methods, dependency injection.
- **L10:** Toggle UI follows TakeNote/existing patterns (toolbar button, SF Symbols).
- **L11:** All public methods tested. Tests and lint must pass.

**Style:**
- Follow existing toggle patterns (see `showFilterBar` in CardList)
- Use SF Symbols for toggle icon (eye/eye.slash or similar)
- Small, focused methods (5 lines guideline with judgment)
- No regex - use string methods and FileManager for directory scanning
- Protocol extension for PlanProviding, concrete implementation in PlanService
- Graceful error handling (log and continue, never crash on missing directories)

## Acceptance Criteria

1. **Toggle Behavior:**
   - Opening a project shows only non-done, non-archived cards by default
   - Toolbar toggle button is visible and discoverable
   - Clicking toggle shows/hides done and archived cards
   - Toggle state works correctly with active filters (done/archived excluded when toggle off, regardless of filter state)
   - Toggle icon clearly indicates current state

2. **Phases Watching:**
   - When project has source directory set, phases directory is watched
   - Changes to progress.yaml, phase.md, review.md trigger automatic reload
   - Phases view updates within ~1 second of file change
   - Missing `.ushabti/phases/` directory does not cause errors or crashes
   - Projects without source directory do not attempt phases watching
   - Phases watching stops cleanly when project deselected

3. **Plan Auto-Increment:**
   - Creating first plan assigns number 0001
   - Creating subsequent plans assigns max+1 (e.g., after 0003 exists, next is 0004)
   - NewPlanSheet does not show number input field
   - Number is zero-padded to 4 digits in slug
   - Works correctly when plans directory is empty or missing

4. **Quality:**
   - All tests pass (unit tests for new methods, integration tests for behavior)
   - No lint violations
   - No console errors or warnings during normal operation
   - Graceful handling of edge cases (missing directories, invalid paths)

## Risks / Notes

- **Dual FSEvents Streams:** Workspace and phases directories will be watched simultaneously. Verify no resource conflicts. Both use main queue dispatch; confirm no deadlock potential.
- **External Source Directory:** Phases directory lives outside workspace (configurable path). Handle invalid paths, deleted directories, permission errors gracefully.
- **Plan Number Gaps:** If plans are deleted, gaps will exist (0001, 0003, 0005). Auto-increment uses max+1, not gap-filling. This is acceptable.
- **Toggle State Ephemeral:** Users must re-toggle each session. Document clearly. Future phase could persist to UserDefaults if requested.
- **FileWatcher Lifecycle:** Ensure phases watching is properly stopped/started when source directory is added/removed via project editing.
