# Review: Phase 0011 — Pharaoh Process Safety

## Summary

Phase 0011 is **complete**. The implementation successfully prevents orphaned Pharaoh processes through process group management, stale process detection, and multi-hook cleanup. All core functionality is present, tested, and correctly documented. One acceptance criterion was technically unachievable as written but was replaced with a functionally equivalent and better-documented solution.

## Verified

### Process Group Management
- **Process group creation** (AC1): `setpgid(pid, pid)` called after spawn in `PharaohService.start` (line 51). Verified.
- **Process group termination** (AC2): `kill(-pgid, SIGTERM)` used in `stop()` (line 61) to kill entire tree. Verified.

### Stale Process Detection and Cleanup
- **Detection logic** (AC3): `cleanupStaleProcess(in:)` reads `pharaoh.json`, extracts PID, uses `kill(pid, 0)` to test existence. Verified at lines 184-216.
- **Cleanup behavior** (AC4): Kills stale process if found, returns `.staleFileOnly` if PID gone. Verified at lines 210-215.
- **Result types**: `StaleProcessResult` enum with three cases (`.noStaleProcess`, `.cleanedStaleProcess(pid)`, `.staleFileOnly`). Verified in `PharaohProviding.swift` lines 36-44.

### Single-Instance Guard
- **Double-start prevention** (AC5): Guards against `process?.isRunning == true` at line 23. Throws `PharaohError.processAlreadyRunning`. Verified.
- **Stale process guard**: Calls `cleanupStaleProcess(in:)` before spawning (line 27). Verified.

### Multi-Hook Cleanup
- **`applicationWillTerminate`**: Registered via `NotificationCenter` observer (lines 9-14), calls `stop()` on notification (lines 218-220). Verified.
- **`deinit`**: Removes observer and calls `stop()` (lines 17-20). Verified.
- **`applicationShouldTerminate`** (AC6): **Not implemented**. Step S008 documents valid technical constraint: `shouldTerminateNotification` does not exist in AppKit, and `applicationShouldTerminate(_:)` delegate method cannot be implemented from a service class. Existing hooks (`willTerminate` + `deinit`) provide equivalent reliability. Deviation from literal acceptance criterion is justified and documented.

### UI Feedback
- **Stale detection on appear** (AC7): `PharaohView.checkForStaleProcess()` called in `.onAppear` (line 32). Verified at lines 328-339.
- **Alert display**: Shows "Orphaned Process Detected" alert with PID when `.cleanedStaleProcess` result returned (lines 47-53). Verified.
- **L18 compliance**: User is notified, not silently cleaned. Verified.

### Tests
- **New tests** (AC8):
  - `testCleanupStaleProcessReturnsNoStaleProcessWhenFileDoesNotExist` (lines 504-507)
  - `testCleanupStaleProcessReturnsNoStaleProcessWhenPidFieldMissing` (lines 509-521)
  - `testCleanupStaleProcessReturnsStaleFileOnlyWhenProcessNotRunning` (lines 523-535)
  - `testStartRefusesDoubleStart` (lines 537-546)
- **All tests pass**: 264 tests, 0 failures. Verified.

### Documentation
- **pharaoh-integration.md** updated with complete "Process Safety" section (lines 347-396):
  - Process group management documented
  - Stale process detection explained
  - Single-instance guard described
  - Multi-hook cleanup strategy documented
  - UI feedback flow documented
- **PharaohProviding.swift**: Method documentation updated for `start`, `stop`, and `cleanupStaleProcess` (lines 48-101). Verified.

### Code Quality
- **L09 (Sandi Metz)**: Methods small and focused. `cleanupStaleProcess` is 33 lines, single responsibility. `stop()` is 6 lines. Verified.
- **L11 (Test Coverage)**: All new public methods have tests. Verified.
- **L12 (No Dead Code)**: No unused symbols, no commented-out blocks. Verified.
- **Error Handling**: `PharaohError.processAlreadyRunning` added with description (lines 12, 30-31 in `PharaohProviding.swift`). Verified.

## Issues

None. All defects identified during implementation were resolved.

## Decision

**GREEN**. Phase 0011 is complete.

**Acceptance Criterion Deviation**: AC6 called for `applicationShouldTerminate` registration. This was not implemented because:
1. `NSApplication.shouldTerminateNotification` does not exist in AppKit
2. `NSApplicationDelegate.applicationShouldTerminate(_:)` cannot be implemented from a service class without architectural restructuring
3. Existing hooks (`willTerminateNotification` + `deinit`) provide equivalent reliability
4. Deviation is documented in progress.yaml step S008 notes and in pharaoh-integration.md

This is a **justified technical substitution**, not a deficiency. The spirit and intent of AC6 (multi-hook cleanup for reliability) are met. Builder correctly identified the constraint and implemented the best available solution. Future phases may refactor to use `NSApplicationDelegate` if multi-process support requires it, but for single-process use, the current implementation is correct.

Card `orphaned-pharaoh-processes-on-quit` marked as done.
