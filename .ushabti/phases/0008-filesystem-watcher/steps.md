# Steps for Phase 8: Filesystem Watcher

## S001: Define FileWatching Protocol

**Intent:** Establish the service contract for file watching.

**Work:**
- Create `Sources/Hieroglyphs/Services/FileWatching.swift`
- Define `FileWatching` protocol with methods:
  - `startWatching(path:onChange:)` — Begins monitoring a directory path recursively; calls closure with event details on changes
  - `stopWatching()` — Stops monitoring and cleans up resources
- Define closure type: `(URL) -> Void` (called with changed file URL; ViewModel responsible for determining what to reload)
- Add protocol documentation comments explaining FSEvents-based monitoring

**Done when:** FileWatching protocol defined with startWatching and stopWatching methods; code compiles.

---

## S002: Implement FileWatcherService

**Intent:** Create concrete implementation using FSEventStream.

**Work:**
- Create `Sources/Hieroglyphs/Services/FileWatcherService.swift`
- Implement `FileWatcherService` conforming to `FileWatching`
- Use FSEventStream API to monitor path recursively:
  - Create stream with FSEventStreamCreate
  - Configure stream flags: `kFSEventStreamCreateFlagFileEvents` (file-level events), `kFSEventStreamCreateFlagUseCFTypes` (CF types for easier bridging)
  - Set latency to 0.5 seconds (balance between responsiveness and batching)
  - Schedule stream on main runloop
  - Start stream in `startWatching(path:onChange:)`
- Store onChange closure and call it for each file event
- Stop and invalidate stream in `stopWatching()`
- Handle cleanup on deinit (call stopWatching if stream is active)

**Done when:** FileWatcherService implements FileWatching protocol using FSEventStream; manually verified by creating service and monitoring a test directory (integration test style).

---

## S003: Add SwiftUI Environment Key

**Intent:** Enable dependency injection of FileWatcher into views.

**Work:**
- Create `Sources/Hieroglyphs/Services/FileWatcherServiceEnvironmentKey.swift`
- Define `FileWatcherServiceEnvironmentKey` struct conforming to `EnvironmentKey`
- Set `defaultValue` to `FileWatcherService()` instance
- Extend `EnvironmentValues` to add `fileWatcher` property

**Done when:** Environment key defined; code compiles; can inject FileWatcher via `.environment(\.fileWatcher, service)`.

---

## S004: Extend ViewModel with Watching Methods

**Intent:** Add lifecycle methods for starting and stopping file watching.

**Work:**
- Open `Sources/Hieroglyphs/HieroglyphsVM.swift`
- Add `fileWatcher: FileWatching?` property (optional; nil until workspace loaded)
- Add `startWatching()` method:
  - Guard check workspacePath is not nil
  - Call `fileWatcher?.startWatching(path:onChange:)` with workspace path
  - onChange closure checks if changed URL is under workspace path and triggers appropriate reload:
    - If URL contains `/project.md`, call `loadProjects()`
    - If URL contains `/cards/` and matches selected project path, call `loadCards()`
- Add `stopWatching()` method:
  - Call `fileWatcher?.stopWatching()`
- Update initializer to accept `fileWatcher: FileWatching` parameter (injected like workspaceService)
- Call `startWatching()` at end of successful `loadWorkspace()` (after workspace path set)
- Call `stopWatching()` in deinit

**Done when:** ViewModel has startWatching and stopWatching methods; startWatching called after loadWorkspace succeeds; stopWatching called on deinit.

---

## S005: Update App.swift to Inject FileWatcher

**Intent:** Wire up FileWatcher dependency at app level.

**Work:**
- Open `Sources/Hieroglyphs/App.swift`
- Create `FileWatcherService()` instance alongside `WorkspaceService`
- Pass fileWatcher to `HieroglyphsVM` initializer
- Add `.environment(\.fileWatcher, fileWatcher)` to MainWindow (for future use if views need direct access)

**Done when:** FileWatcher created and injected into ViewModel; app compiles and runs.

---

## S006: Add ViewModel Tests for Watching

**Intent:** Verify ViewModel watching lifecycle with mock FileWatcher.

**Work:**
- Open `Tests/HieroglyphsTests/HieroglyphsVMTests.swift`
- Create `MockFileWatcher` conforming to `FileWatching`:
  - Track `startWatchingCalled`, `stopWatchingCalled` booleans
  - Store `path` and `onChange` closure when startWatching called
  - Expose `simulateChange(url:)` method to manually trigger onChange for testing
- Add test cases:
  - `testStartWatchingCalledOnLoadWorkspace`: Verify startWatching called after successful loadWorkspace
  - `testStartWatchingNotCalledOnLoadWorkspaceFailure`: Verify startWatching not called if loadWorkspace throws error
  - `testStopWatchingCalledOnDeinit`: Verify stopWatching called when ViewModel deallocated
  - `testFileChangeTriggersProjectReload`: Simulate change to project.md file, verify loadProjects called
  - `testFileChangeTriggersCardReload`: Simulate change to card.md file in selected project, verify loadCards called
  - `testFileChangeOutsideSelectedProjectIgnored`: Simulate change to card in different project, verify loadCards not called
- Run tests and verify all pass

**Done when:** Tests for ViewModel watching lifecycle pass; `swift test` succeeds.

---

## S007: Create file-watching.md Documentation

**Intent:** Document the file watching system architecture and behavior.

**Work:**
- Create `.ushabti/docs/file-watching.md`
- Include sections:
  - Overview: Purpose and integration with L05 and L06
  - FileWatching Protocol: Contract definition and method descriptions
  - FileWatcherService: FSEventStream implementation details
  - ViewModel Integration: Lifecycle (startWatching, stopWatching) and reload triggers
  - Event Handling: How onChange closure determines what to reload
  - Performance Notes: Latency, batching, and future optimizations
  - Testing: Mock usage and integration testing approach
- Add examples showing external edit scenarios and expected behavior

**Done when:** file-watching.md created with comprehensive documentation of the file watching system.

---

## S008: Update Existing Documentation

**Intent:** Integrate file watching into existing architecture and ViewModel docs.

**Work:**
- Update `.ushabti/docs/architecture.md`:
  - Add FileWatcherService to Services Layer section
  - Add file watching to Platform Leverage section (FSEvents)
  - Update Future Architecture Extensions to mark file watching as implemented
- Update `.ushabti/docs/viewmodel.md`:
  - Add startWatching() and stopWatching() to Methods section
  - Add fileWatcher property to HieroglyphsVM Class section
  - Update Lifecycle and Initialization to include FileWatcher injection
  - Add State Flow section describing external change handling
- Update `.ushabti/docs/index.md`:
  - Add link to file-watching.md in Table of Contents

**Done when:** Existing docs updated to reference file watching system; all links functional.

---

## S009: Manual Acceptance Test

**Intent:** Verify end-to-end behavior with real filesystem changes.

**Work:**
- Build and run Hieroglyphs: `swift run`
- Open workspace with existing projects and cards
- Perform acceptance test steps from phase.md:
  1. Edit card.md title in external text editor, save, verify UI updates
  2. Create new card.md via terminal, verify appears in UI
  3. Delete card directory via Finder, verify disappears from UI
  4. Edit project.md description, verify sidebar updates (if description shown)
- Verify no crashes, no excessive reloads, smooth UI updates
- Document any issues or unexpected behavior

**Done when:** Manual acceptance test completes successfully; all scenarios work as expected; no regressions.

---

## S010: Run Full Test Suite and Lint

**Intent:** Ensure all tests pass and code quality is maintained.

**Work:**
- Run `swift test` and verify all tests pass (including new ViewModel watching tests)
- Run lint/SwiftLint and verify no violations
- Fix any test failures or lint issues

**Done when:** `swift test` passes; lint clean; phase ready for review.

---

## S011: Fix Memory Leak in FileWatcherService

**Intent:** Correct memory management defect in FSEventStream context handling.

**Work:**
- Open `Sources/Hieroglyphs/Services/FileWatcherService.swift`
- Identify memory leak: Line 44 uses `Unmanaged.passRetained(self)` which increments retain count, but no corresponding release exists
- Apply fix: Change line 44 from `Unmanaged.passRetained(self).toOpaque()` to `Unmanaged.passUnretained(self).toOpaque()`
- Verify safety: passUnretained is safe because FileWatcherService owns stream lifecycle (stream stopped in stopWatching, stopWatching called in deinit, so self cannot be deallocated while stream is active)
- Alternative fix (if passUnretained deemed unsafe): Store context pointer as property, explicitly call `Unmanaged.fromOpaque(info).release()` and `context.deallocate()` in cleanupStream (see review.md for full implementation)
- Build and test to verify no regressions

**Done when:** Memory leak fixed using passUnretained; `swift build` succeeds; `swift test` passes (all 101 tests); code review confirms correct memory management.
