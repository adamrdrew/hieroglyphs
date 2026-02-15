# Phase 0018: Fix Pharaoh Running Per Project

## Intent

Fix two critical bugs caused by `PharaohService` tracking a single `Process?` instead of a per-project process dictionary. Both bugs share the same root cause and must be fixed together:

1. **Single-instance bug (CRITICAL):** The service prevents starting Pharaoh on Project B if Project A already has a running instance, because the guard checks a single global process slot instead of per-project tracking.

2. **Stale popup bug (HIGH):** Navigating to a project with a live Pharaoh process triggers an "Orphaned Process Detected" alert and kills the process, because the stale detection compares the process PID against the single tracked process rather than the specific project's process.

Both issues are regressions from Phase 0011 (Pharaoh Process Safety) and violate user expectations. Users should be able to run Pharaoh on multiple projects simultaneously. The architecture change replaces `private var process: Process?` with `private var processes: [String: Process]` keyed by source directory path.

## Scope

**In scope:**
- Replace single process storage with per-project dictionary in `PharaohService`
- Update `PharaohProviding` protocol to add `stop(in:)` method for per-project stop
- Modify `start(in:model:)` to check and track processes per directory
- Add new `stop(in:)` method for per-project stop
- Update global `stop()` to terminate all tracked processes
- Fix `cleanupStaleProcess(in:)` to compare against the correct project's process
- Update `PharaohView.stopPharaoh()` to call per-project stop
- Add tests verifying multi-project process management
- Update `.ushabti/docs/pharaoh-integration.md` to reflect per-project tracking

**Out of scope:**
- Changing how processes are spawned (shell invocation, process group setup, working directory)
- Modifying read-only methods (`readStatus`, `readLogs`, `readEvents`, `readServerInfo`)
- Changing the `PharaohError` enum
- Introducing a separate project ID or slug as dictionary key (source directory path is correct)
- Splitting `PharaohService` into multiple classes

## Constraints

- **L09:** Sandi Metz principles — Keep methods small and focused, single responsibility
- **L11:** Test coverage — All public API methods must have tests, all execution paths covered
- **L14:** Builder must update docs when code changes affect documented systems
- **L15:** Overseer must verify docs are reconciled before declaring complete
- **Style:** Services are protocol-based, testable through interfaces

**Architecture constraints from phase prompt:**
- Dictionary key MUST be source directory path (the same string passed to all service methods)
- Do NOT change process spawning mechanics (shell, setpgid, working directory)
- Do NOT change read-only service methods
- Do NOT change error enum
- `@unchecked Sendable` conformance is acceptable and covers the new dictionary

## Acceptance Criteria

- Can start Pharaoh on two different projects simultaneously
- Cannot start two Pharaoh instances on the same project (second call throws `.processAlreadyRunning`)
- Process tracking correctly associates each Pharaoh instance with its project directory
- Navigating to an actively running Pharaoh instance does NOT trigger stale process popup
- Stale detection still works correctly for genuinely orphaned processes
- All tests pass (existing + new per-project tests)
- `swift build` succeeds
- `swift test` succeeds
- Documentation updated to reflect per-project architecture

## Risks / Notes

**Backward compatibility:** This changes internal implementation only. Public API remains the same except for adding `stop(in:)` to the protocol.

**Process group cleanup:** Process group management (setpgid, kill with negative PID) remains unchanged and continues to work correctly per-project.

**Dictionary key stability:** Source directory paths are stable for a given project (set once in project frontmatter). Using the path as the key is natural and matches existing method signatures.

**Termination handler closure capture:** Each process's termination handler captures its directory key to remove the correct entry from the dictionary. This is safe because the handler runs asynchronously and captures the key by value.
