# Review: Phase 0018 — Fix Pharaoh Running Per Project

## Summary

Phase is complete and correct. Both critical bugs have been fixed by replacing single process storage with per-project dictionary tracking. The architecture change is sound, the implementation follows all laws and style guidelines, tests are comprehensive, and documentation is fully reconciled.

## Verified

### Acceptance Criteria — All Met

- Can start Pharaoh on two different projects simultaneously — Verified by `testCanStartMultipleProjects`
- Cannot start two Pharaoh instances on the same project — Verified by `testCannotStartTwiceOnSameProject` throwing `.processAlreadyRunning`
- Process tracking correctly associates each instance with its project directory — Verified by per-project stop test
- Navigating to an actively running instance does NOT trigger stale popup — Fixed by line 213 comparison against `processes[directory]` instead of global process
- Stale detection still works for genuinely orphaned processes — Verified by `testStaleDetectionTriggersForUntrackedProcess`
- All tests pass — 283 tests, 0 failures
- `swift build` succeeds — Verified
- Documentation updated — Fully reconciled

### Code Quality (L09, L11, Style)

**Protocol Design (S001):**
- `PharaohProviding` protocol correctly adds `stop(in:)` method
- Both `stop()` and `stop(in:)` have clear doc comments distinguishing all-process vs per-project behavior
- Protocol boundary preserved — services are protocol-based, testable

**Storage Architecture (S002-S003):**
- Dictionary keyed by source directory path is the correct choice — stable, natural key
- `processes: [String: Process]` replaces `process: Process?`
- `@unchecked Sendable` conformance covers dictionary correctly

**Start Method (S003):**
- Line 23: Guard checks `processes[directory]?.isRunning` — per-project enforcement
- Line 52: Process stored in dictionary with correct key
- Lines 42-46: Termination handler captures directory and removes correct entry — safe closure capture

**Stop Methods (S004-S005):**
- `stop()` iterates all processes, sends SIGTERM to each group, waits for termination, clears dictionary — correct
- `stop(in:)` guards for process existence, sends SIGTERM to specific group, waits, removes from dictionary — correct
- Process group management unchanged (setpgid, kill with negative PID) — correct

**Stale Detection Fix (S006):**
- Line 213: `if let currentProcess = processes[directory], currentProcess.processIdentifier == Int32(pid)`
- This is the critical fix for the spurious popup bug — now scoped to directory-specific process
- Logic is correct — returns `.noStaleProcess` if PID matches the tracked process for THIS directory

**UI Integration (S007):**
- `PharaohView.stopPharaoh()` guards for sourceDirectory, calls `stop(in: sourceDirectory)`
- Correct — UI stops only current project's process

**Tests (S008):**
Six new tests added, all covering essential multi-project scenarios:
1. `testCanStartMultipleProjects` — Starts on two directories, both succeed
2. `testCannotStartTwiceOnSameProject` — Second start on same directory throws
3. `testPerProjectStop` — Stop one project, verify other still running
4. `testStopAll` — Stop all, verify both can be restarted
5. `testStaleDetectionDoesNotTriggerForTrackedProcess` — No false positive on live process
6. `testStaleDetectionTriggersForUntrackedProcess` — Still detects genuinely stale processes

All tests passed. Coverage is thorough.

### Documentation Reconciliation (L14, L15, L16)

**pharaoh-integration.md fully updated (S009):**

Lines 60-82 (Services section):
- Added `stop(in directory: String)` method documentation
- Updated `stop()` description to clarify all-process behavior
- Documented `processes: [String: Process]` storage keyed by directory

Lines 349-395 (Process Safety section):
- "Process Safety" intro now describes per-project dictionary tracking
- "Per-Project Instance Guard" subsection: Guard checks per-directory, not global
- "Stale Process Detection" subsection: Comparison scoped to directory-specific process
- Process group management section preserved — setpgid, kill with negative PID unchanged

Lines 557-570 (Edge Cases section):
- Removed "Single Process: Only one Pharaoh process runs at a time" limitation
- Added "Per-Project Processes: Each project can run its own Pharaoh instance independently"

Documentation is accurate and complete.

### Laws Compliance

- **L09 (Sandi Metz):** Methods are small, focused, single responsibility. Dictionary lookup is cleaner than global state. Protocol-based design preserved.
- **L11 (Test Coverage):** All public API paths tested. Six new tests cover multi-project scenarios comprehensively.
- **L14 (Builder Docs Maintenance):** Documentation updated in step S009, `pharaoh-integration.md` in touched list.
- **L15 (Overseer Docs Reconciliation):** Verified — docs accurately reflect per-project architecture.
- **L16 (Phase Completion Requires Docs Reconciliation):** Met — docs are reconciled.

### Style Compliance

- **SOLID:** Single responsibility maintained. Services protocol-based. Dependency on abstraction, not concretion.
- **Naming:** Clear and descriptive. `processes` dictionary, `stop(in:)` vs `stop()` unambiguous.
- **Readability:** Logic is straightforward. Dictionary lookup is clearer than global state check.
- **No dead code:** Verified — old `process: Process?` removed, all code is live.

## Issues

None.

## Required Follow-Ups

None.

## Decision

**Phase status: COMPLETE (GREEN)**

Both bugs fixed. Architecture is sound. Tests are comprehensive. Documentation is reconciled. All laws and style requirements met. The phase delivers exactly what it promised: multiple projects can now run Pharaoh simultaneously, and stale process detection is scoped correctly per-project.

Weighed and found true.
