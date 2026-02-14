# Phase 0011: Pharaoh Process Safety

card: orphaned-pharaoh-processes-on-quit

## Intent

Prevent orphaned Pharaoh processes from accumulating when Hieroglyphs quits or crashes. Currently, `npx @adamrdrew/pharaoh serve` spawns both an npm parent process and a child node process. When Hieroglyphs terminates, `process.terminate()` sends SIGTERM to the npm parent, but the child node process survives. Over time, these orphaned processes accumulate (12+ orphans observed dating back days). This phase implements process group management, stale process detection, and multi-hook cleanup to ensure reliable termination.

## Scope

**In scope:**
- Process group creation in `PharaohService.start(in:model:)` so the entire process tree can be killed with one signal
- Updated `PharaohService.stop()` to kill the entire process group (both npm parent and node child)
- Stale process detection method `cleanupStaleProcess(in:)` to detect and clean up orphans from previous sessions
- Single-instance guard to prevent starting a new process if one is already running (either in current session or stale from previous session)
- Multi-hook termination registration: `applicationWillTerminate`, `applicationShouldTerminate`, and `deinit`
- UI feedback in `PharaohView` when a stale process is detected and cleaned up
- Tests for stale process detection logic, process group cleanup, and single-instance guard

**Out of scope:**
- Changes to the Pharaoh npm package itself
- Multi-project Pharaoh support (separate card, requires per-project process registry)
- Changes to event stream parsing or status monitoring
- Automated orphan cleanup on app launch (user should be notified first per L18)

## Constraints

- **L09 (Sandi Metz):** Small, focused methods. Stale detection, cleanup, and guarding are separate responsibilities.
- **L11 (Test Coverage):** Test the stale process detection logic. Test that `stop()` correctly signals the process group. Test single-instance guard.
- **L18 (Design Is How It Works):** If an orphaned process is detected, tell the user. Don't silently clean up without feedback. Show an alert or inline message indicating the orphan was found and cleaned.

## Acceptance Criteria

1. **Process group creation:** When `start(in:model:)` spawns a Pharaoh process, it creates a new process group so both npm parent and node child can be killed together.
2. **Process group termination:** `stop()` sends SIGTERM to the entire process group (using negative PID) rather than just the parent process.
3. **Stale process detection:** `cleanupStaleProcess(in:)` reads `.pharaoh/pharaoh.json`, checks if the recorded PID is still running, and returns a result indicating whether a stale process was found.
4. **Stale process cleanup:** If a stale process is detected, it is killed. If the PID no longer exists, the stale `pharaoh.json` is noted but no kill is attempted.
5. **Single-instance guard:** Before starting a new process, verify no existing process is running for that directory (either in current session or as a stale PID). Refuse to start if either guard trips.
6. **Multi-hook cleanup:** `applicationShouldTerminate` is registered in addition to `applicationWillTerminate` and `deinit` to maximize cleanup reliability.
7. **UI feedback:** `PharaohView` calls `cleanupStaleProcess(in:)` on appear and shows a message if an orphan was detected and cleaned.
8. **Tests pass:** All new public methods have tests. All existing tests continue to pass.

## Risks / Notes

- `setpgid` is a POSIX system call available on macOS. Usage is straightforward and well-documented.
- Stale process detection relies on `pharaoh.json` containing a `pid` field. Current Pharaoh version writes this field as `PharaohServerInfo.pid`.
- `kill(pid, 0)` is used to test if a process exists without actually sending a signal. Returns 0 if process exists, -1 if not.
- Multi-hook cleanup increases reliability but cannot guarantee cleanup on force quit or kernel panic. Process group management is the primary defense.
