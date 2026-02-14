# Steps

## S001: Add StaleProcessResult enum to PharaohProviding.swift

**Intent:** Define the return type for stale process detection.

**Work:**
- Add `StaleProcessResult` enum to `PharaohProviding.swift` with three cases:
  - `.noStaleProcess` — No stale process found, safe to start
  - `.cleanedStaleProcess(pid: Int)` — Stale process was found and killed
  - `.staleFileOnly` — Stale `pharaoh.json` found but process no longer exists

**Done when:** `StaleProcessResult` enum exists with three cases as specified.

## S002: Add cleanupStaleProcess method to PharaohProviding protocol

**Intent:** Extend the protocol to support stale process detection.

**Work:**
- Add method signature to `PharaohProviding` protocol:
  ```swift
  func cleanupStaleProcess(in directory: String) -> StaleProcessResult
  ```
- Add documentation comment explaining the method's purpose and return values.

**Done when:** Protocol has `cleanupStaleProcess(in:)` method signature with documentation.

## S003: Implement cleanupStaleProcess in PharaohService

**Intent:** Detect and clean up orphaned processes from previous sessions.

**Work:**
- Read `.pharaoh/pharaoh.json` from the specified directory
- Extract `pid` field from JSON
- Test if process exists using `kill(pid, 0)`
- If process exists and is not the current session's process, send `SIGTERM` to the process group using `kill(-pid, SIGTERM)`
- Return appropriate `StaleProcessResult` case based on findings
- Handle missing file, malformed JSON, or missing `pid` field gracefully (return `.noStaleProcess`)

**Done when:** `cleanupStaleProcess(in:)` correctly detects and kills stale processes, returns correct result, handles all error cases.

## S004: Update PharaohService.start to create process group

**Intent:** Ensure spawned process becomes its own process group leader.

**Work:**
- After `process.run()` succeeds, get the process identifier: `let pid = process.processIdentifier`
- Call `setpgid(pid, pid)` to make the process its own group leader
- This ensures both npm parent and node child are in the same process group

**Done when:** `start(in:model:)` calls `setpgid(pid, pid)` after spawning the process.

## S005: Update PharaohService.stop to kill process group

**Intent:** Terminate the entire process tree, not just the parent.

**Work:**
- In `stop()`, before calling `process.terminate()`, get the process group ID: `let pgid = process.processIdentifier`
- Call `kill(-pgid, SIGTERM)` to send SIGTERM to the entire process group (negative PID targets the group)
- Call `process.waitUntilExit()` to wait for termination to complete
- Set `self.process = nil`
- Remove the `process.terminate()` call (replaced by `kill`)

**Done when:** `stop()` uses `kill(-pgid, SIGTERM)` and `waitUntilExit()` instead of `process.terminate()`.

## S006: Add single-instance guard to PharaohService.start

**Intent:** Prevent starting a new process if one is already running.

**Work:**
- At the start of `start(in:model:)`, check if `self.process?.isRunning == true`
- If true, throw `PharaohError.processAlreadyRunning`
- Call `cleanupStaleProcess(in: directory)` before spawning the new process
- If result is `.cleanedStaleProcess(let pid)`, log the cleanup (print to console) but proceed with starting
- If result is `.staleFileOnly`, proceed with starting (file is stale, no process running)
- Only proceed to spawn the new process if no current process is running and stale cleanup succeeded

**Done when:** `start(in:model:)` guards against double-start and calls `cleanupStaleProcess` before spawning.

## S007: Add processAlreadyRunning case to PharaohError

**Intent:** Provide a descriptive error for double-start attempts.

**Work:**
- Add case to `PharaohError` enum: `case processAlreadyRunning`
- Add error description: `"Pharaoh process is already running"`

**Done when:** `PharaohError.processAlreadyRunning` exists with description.

## S008: Register applicationShouldTerminate handler

**Intent:** Add belt-and-suspenders cleanup hook.

**Work:**
- In `PharaohService.init()`, register observer for `NSApplication.shouldTerminateNotification` if available, or implement `NSApplicationDelegate` method if needed
- On notification, call `stop()` synchronously
- Return `.terminateNow` after cleanup completes
- Note: If `shouldTerminateNotification` does not exist, implement via `NSApplicationDelegate` extension or custom delegate

**Done when:** `PharaohService` registers cleanup on `applicationShouldTerminate` or equivalent app lifecycle hook.

## S009: Add stale process cleanup to PharaohView.onAppear

**Intent:** Detect and clean up orphans when navigating to Pharaoh view.

**Work:**
- In `PharaohView`, call `pharaohService.cleanupStaleProcess(in: project.sourceDirectory)` in `.onAppear`
- Store result in `@State var staleCleanupResult: StaleProcessResult?`
- If result is `.cleanedStaleProcess(let pid)`, set `@State var showStaleAlert = true` and populate alert message
- Show alert with title "Orphaned Process Detected" and message "A stale Pharaoh process (PID \(pid)) was found and stopped."

**Done when:** `PharaohView` calls `cleanupStaleProcess` on appear and shows alert if orphan was detected.

## S010: Write tests for cleanupStaleProcess

**Intent:** Verify stale process detection logic.

**Work:**
- Create `testCleanupStaleProcess_noFile` — Verify returns `.noStaleProcess` when `pharaoh.json` missing
- Create `testCleanupStaleProcess_noPid` — Verify returns `.noStaleProcess` when `pid` field missing from JSON
- Create `testCleanupStaleProcess_processNotRunning` — Mock JSON with PID, verify returns `.staleFileOnly` when process does not exist (cannot easily mock `kill(pid, 0)` result, may need to use a known non-existent PID like 999999)
- Create `testCleanupStaleProcess_processRunning` — More complex: would require mocking or using a real test process (deferred if too complex for unit test, document as integration test requirement)

**Done when:** At least three test cases exist and pass, covering no file, missing PID, and stale file scenarios.

## S011: Write tests for single-instance guard

**Intent:** Verify that `start` refuses to run if process already exists.

**Work:**
- Create `testStart_refusesDoubleStart` — Start process, verify second call to `start` throws `PharaohError.processAlreadyRunning`
- Create mock or use temporary directory with valid Pharaoh environment

**Done when:** Test exists and passes, verifying double-start guard.

## S012: Write tests for process group termination

**Intent:** Verify that `stop()` uses process group kill.

**Work:**
- Create `testStop_killsProcessGroup` — Start a test process, call `stop()`, verify process is terminated
- May be difficult to unit test without spawning real process — document as integration test requirement if mocking is impractical
- At minimum, verify that `stop()` code path calls `kill` with negative PID (code inspection test)

**Done when:** Test exists verifying `stop()` behavior, or integration test requirement documented.

## S013: Update PharaohService documentation

**Intent:** Document new methods and process group behavior.

**Work:**
- Add documentation comments to `cleanupStaleProcess(in:)` explaining its purpose, return values, and when to call it
- Update `start(in:model:)` documentation to mention process group creation
- Update `stop()` documentation to mention process group termination

**Done when:** All new and modified methods have clear documentation comments.

## S014: Update pharaoh-integration.md docs

**Intent:** Reconcile docs with new process safety mechanisms.

**Work:**
- Add section "Process Safety" to `pharaoh-integration.md` documenting:
  - Process group creation and termination
  - Stale process detection and cleanup
  - Single-instance guard
  - Multi-hook termination strategy
- Update "Process Lifecycle" section to mention process group management
- Update "Edge Cases and Limitations" to note that stale cleanup happens on Pharaoh view appear

**Done when:** `.ushabti/docs/pharaoh-integration.md` includes new process safety mechanisms.
