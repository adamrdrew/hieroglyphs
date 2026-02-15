# Steps

## S001: Update PharaohProviding protocol

**Intent:** Add per-project stop method to the protocol while preserving the existing stop-all method for app lifecycle cleanup.

**Work:**
- Open `Sources/Hieroglyphs/Services/PharaohProviding.swift`
- Add new method signature: `func stop(in directory: String)` with doc comment explaining it stops the Pharaoh process for a specific project
- Update doc comment for existing `func stop()` to clarify it stops all running processes (used during app termination)
- No other protocol changes needed — `start(in:model:)` and `cleanupStaleProcess(in:)` already take directory parameters

**Done when:** Protocol defines both `stop()` and `stop(in:)` with clear documentation distinguishing their purposes.

## S002: Replace process storage in PharaohService

**Intent:** Change internal storage from single process to per-project dictionary.

**Work:**
- Open `Sources/Hieroglyphs/Services/PharaohService.swift`
- Replace `private var process: Process?` (line 6) with `private var processes: [String: Process] = [:]`
- No other changes in this step — next steps will update each method to use the dictionary

**Done when:** Storage declaration changed, file compiles with no functional changes yet.

## S003: Update start(in:model:) method

**Intent:** Check and track processes per directory instead of globally.

**Work:**
- In `PharaohService.swift`, modify `start(in:model:)`:
  - Line 23: Change guard from `guard process?.isRunning != true` to `guard processes[directory]?.isRunning != true`
  - Line 52: Change assignment from `self.process = process` to `self.processes[directory] = process`
  - Update termination handler (lines 42-46) to capture directory and remove correct dictionary entry: `self?.processes[directory] = nil`

**Done when:** `start(in:model:)` checks per-project process state and tracks new process in dictionary with correct termination cleanup.

## S004: Update stop() to stop all processes

**Intent:** Global stop method terminates all tracked processes for app shutdown.

**Work:**
- In `PharaohService.swift`, replace `stop()` implementation (lines 58-64):
  - Iterate over all processes in dictionary: `for (directory, process) in processes`
  - Send SIGTERM to each process group: `kill(-pgid, SIGTERM)`
  - Wait for termination: `process.waitUntilExit()`
  - Clear dictionary after all stopped: `processes.removeAll()`

**Done when:** `stop()` terminates all tracked processes and clears the dictionary.

## S005: Add stop(in:) for per-project stop

**Intent:** Add new method to stop a specific project's process.

**Work:**
- In `PharaohService.swift`, add new method after the global `stop()`:
  - Method signature: `func stop(in directory: String)`
  - Guard to check if process exists: `guard let process = processes[directory] else { return }`
  - Get process group ID and send SIGTERM: `kill(-pgid, SIGTERM)`
  - Wait for termination: `process.waitUntilExit()`
  - Remove from dictionary: `processes[directory] = nil`

**Done when:** Per-project stop method implemented and removes only the specified directory's process.

## S006: Update cleanupStaleProcess(in:) stale check

**Intent:** Compare PID against the correct project's tracked process, not a global process.

**Work:**
- In `PharaohService.swift`, modify `cleanupStaleProcess(in:)`:
  - Line 204: Change `if let currentProcess = process, currentProcess.processIdentifier == Int32(pid)` to `if let currentProcess = processes[directory], currentProcess.processIdentifier == Int32(pid)`
  - This is the critical fix for the stale popup bug — now the check is scoped to THIS project's process

**Done when:** Stale process detection compares against the directory-specific tracked process.

## S007: Update PharaohView to call per-project stop

**Intent:** Stop button in UI terminates only the current project's Pharaoh instance.

**Work:**
- Open `Sources/Hieroglyphs/Views/Pharaoh/PharaohView.swift`
- Modify `stopPharaoh()` method (lines 278-281):
  - Add guard for sourceDirectory: `guard let sourceDirectory = project.sourceDirectory else { return }`
  - Change service call from `pharaohService?.stop()` to `pharaohService?.stop(in: sourceDirectory)`
  - Status update remains: `status = .notRunning`

**Done when:** Stop button calls per-project stop with the current project's source directory.

## S008: Add multi-project process tests

**Intent:** Verify that multiple projects can run Pharaoh simultaneously and per-project operations work correctly.

**Work:**
- Open `Tests/HieroglyphsTests/PharaohServiceTests.swift`
- Add test: `testCanStartMultipleProjects()` — Start on "/tmp/projectA", then "/tmp/projectB". Both must succeed without throwing.
- Add test: `testCannotStartTwiceOnSameProject()` — Start on "/tmp/projectA" twice. Second call must throw `.processAlreadyRunning`.
- Add test: `testPerProjectStop()` — Start on "/tmp/projectA" and "/tmp/projectB". Call `stop(in: "/tmp/projectA")`. Verify A stopped, B still running.
- Add test: `testStopAll()` — Start on "/tmp/projectA" and "/tmp/projectB". Call `stop()`. Verify both stopped.
- Add test: `testStaleDetectionDoesNotTriggerForTrackedProcess()` — Start process on "/tmp/projectA". Call `cleanupStaleProcess(in: "/tmp/projectA")`. Must return `.noStaleProcess`.
- Add test: `testStaleDetectionTriggersForUntrackedProcess()` — Write pharaoh.json with a real but untracked PID. Call `cleanupStaleProcess(in:)`. Must return `.cleanedStaleProcess` or `.staleFileOnly`.

**Done when:** Six new tests added covering multi-project scenarios, all tests pass.

## S009: Update pharaoh-integration.md documentation

**Intent:** Reconcile docs with the new per-project architecture.

**Work:**
- Open `.ushabti/docs/pharaoh-integration.md`
- Update "Process Safety" section (lines 347-416):
  - Change description from "single Process? slot" to "dictionary of processes keyed by source directory"
  - Update "Single-Instance Guard" subsection: Explain guard checks per-directory, not global
  - Update "Stale Process Detection" subsection: Explain comparison is scoped to directory-specific process
- Update "Services" section (lines 60-85):
  - Add documentation for `stop(in:)` method
  - Update `stop()` description to clarify it stops all processes
  - Note that process storage is `[String: Process]` keyed by directory
- Update "Edge Cases and Limitations" section (line 555):
  - Remove "Single Process: Only one Pharaoh process runs at a time" limitation
  - Add "Per-Project Processes: Each project can run its own Pharaoh instance independently"

**Done when:** Documentation accurately reflects per-project process tracking architecture.

## S010: Verify build and tests

**Intent:** Ensure all code compiles and tests pass before review.

**Work:**
- Run `swift build` from project root
- Run `swift test` from project root
- Verify no compiler errors or warnings
- Verify all tests pass (existing + new multi-project tests)

**Done when:** `swift build` and `swift test` both succeed with no errors.
