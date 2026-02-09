# File Watching System

## Overview

The file watching system monitors the workspace directory for external changes and automatically refreshes the UI when files are created, modified, or deleted. This fulfills L05 (External Changes Are First-Class) and L06 (Platform Leverage Over Reinvention) by using macOS native FSEvents API.

**Key Integration Points:**
- `FileWatching` protocol defines the service contract
- `FileWatcherService` implements monitoring using FSEventStream
- `HieroglyphsVM` coordinates watching lifecycle and reload triggers
- Changes detected by external tools (text editors, LLMs, CLI commands) automatically update the UI

## FileWatching Protocol

**Location:** `Sources/Hieroglyphs/Services/FileWatching.swift`

**Purpose:** Define the contract for filesystem monitoring services.

### Protocol Definition

```swift
protocol FileWatching {
    func startWatching(path: String, onChange: @escaping (URL) -> Void)
    func stopWatching()
}
```

### Methods

#### startWatching(path:onChange:)

**Signature:** `func startWatching(path: String, onChange: @escaping (URL) -> Void)`

**Purpose:** Begin monitoring a directory path recursively for file system changes.

**Parameters:**
- `path` — Absolute path to directory to monitor (typically workspace path)
- `onChange` — Closure called with changed file URL when changes occur

**Behavior:**
- Monitors entire directory tree recursively
- Detects file creation, modification, and deletion
- Calls onChange closure on main thread for each changed file
- May batch multiple changes together (typical FSEvents behavior)

**Notes:**
- Implementations use FSEventStream API for efficient monitoring
- Safe to call multiple times (stops previous monitoring before starting new)
- Closure is guaranteed to run on main thread for UI updates

#### stopWatching()

**Signature:** `func stopWatching()`

**Purpose:** Stop monitoring and clean up resources.

**Behavior:**
- Stops event stream
- Invalidates and releases system resources
- Safe to call multiple times or when not watching

**Notes:**
- Does not throw errors
- After calling, startWatching may be called again to resume monitoring

## FileWatcherService Implementation

**Location:** `Sources/Hieroglyphs/Services/FileWatcherService.swift`

**Purpose:** Concrete implementation using FSEventStream API.

### FSEventStream Configuration

The service creates an FSEventStream with these settings:

- **Flags:**
  - `kFSEventStreamCreateFlagFileEvents` — Report file-level events (not just directory)
  - `kFSEventStreamCreateFlagUseCFTypes` — Use CFTypes for easier Swift bridging

- **Latency:** 0.5 seconds — Balances responsiveness with batching efficiency

- **Dispatch Queue:** Main queue — All callbacks run on main thread for UI safety

- **Event ID:** `kFSEventStreamEventIdSinceNow` — Only report events after stream starts

### Implementation Details

**Context Management:**

The service uses `Unmanaged` to pass self reference to C callback:

```swift
let selfPointer = Unmanaged.passRetained(self).toOpaque()
```

**Event Callback:**

Global C function receives events and forwards to service instance:

```swift
private func eventCallback(
    streamRef: ConstFSEventStreamRef,
    clientCallBackInfo: UnsafeMutableRawPointer?,
    numEvents: Int,
    eventPaths: UnsafeMutableRawPointer,
    eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    eventIds: UnsafePointer<FSEventStreamEventId>
) {
    // Extract service instance and call onChange for each path
}
```

**Resource Cleanup:**

Cleanup happens in three steps:
1. Stop stream: `FSEventStreamStop(streamRef)`
2. Invalidate: `FSEventStreamInvalidate(streamRef)`
3. Release: `FSEventStreamRelease(streamRef)`

**Concurrency:**

- Service uses `fileprivate var onChange` to allow callback access
- Events delivered on main queue via `FSEventStreamSetDispatchQueue`
- No additional async dispatch needed in callback

## ViewModel Integration

**Location:** `Sources/Hieroglyphs/HieroglyphsVM.swift`

**Purpose:** Coordinate watching lifecycle and trigger appropriate reloads.

### Properties

- `fileWatcher: FileWatching?` — Injected service (optional; nil in tests without watcher)

### Lifecycle Methods

#### startWatching()

**Called:** Automatically after successful `loadWorkspace()`

**Behavior:**
1. Guard checks workspace path exists
2. Calls `fileWatcher?.startWatching(path:onChange:)` with workspace path
3. onChange closure captures weak self and calls `handleFileChange(url:)`

**Notes:**
- Only starts if workspace loaded successfully
- Safe to call multiple times (service stops previous watching)

#### stopWatching()

**Called:** Manually by client code or tests

**Behavior:**
- Calls `fileWatcher?.stopWatching()` to clean up resources

**Notes:**
- Not called on deinit due to Swift concurrency restrictions
- ViewModel is app-lifetime, so cleanup happens naturally on app termination

### Event Handling

#### handleFileChange(url:)

**Signature:** `private func handleFileChange(url: URL)`

**Purpose:** Determine what to reload based on changed file path.

**Logic:**

```swift
private func handleFileChange(url: URL) {
    guard workspacePath != nil else { return }

    let path = url.path

    if path.contains("/project.md") {
        loadProjects()
    } else if path.contains("/cards/") || path.contains("/card.md") {
        if let selectedProject,
           path.contains("/\(selectedProject.slug)/") {
            loadCards()
        }
    }
}
```

**Decision Tree:**
- **Project changes:** If path contains `/project.md`, reload project list
- **Card changes:** If path contains `/cards/` or `/card.md` AND path contains selected project slug, reload card list
- **Other changes:** Ignored (e.g., hidden files, temp files)

**Notes:**
- Uses simple string matching (no regex per style guide)
- Only reloads cards for currently selected project (avoids unnecessary I/O)
- Reloads entire list (no granular update in v1; future optimization)

#### loadProjects() [private]

**Purpose:** Reload project list without changing workspace path.

**Behavior:**
- Calls `workspaceService.loadProjects(from:)` with current workspace path
- Updates `projects` property on success
- Logs error on failure

**Notes:**
- Separate from public `loadWorkspace()` which also loads config
- Used internally by file watcher to refresh projects

## Performance Notes

### Latency

FSEventStream batches events with 0.5 second latency:
- Changes are detected within ~500ms
- Multiple rapid changes batched into single callback
- UI updates feel near-instant to users

**Tradeoff:** Slightly delayed updates in exchange for reduced callback frequency and better system performance.

### Reload Strategy

Current implementation reloads entire lists:
- **Project change:** Reload all projects
- **Card change:** Reload all cards for selected project

**Future Optimization:**
- Add granular change detection (file-level diffing)
- Update only changed items instead of reloading lists
- Debounce reloads (at most once per second)

### Resource Impact

FSEventStream is lightweight:
- System-level monitoring (no polling)
- Efficient file-level event reporting
- Minimal CPU and memory overhead

**Acceptable for typical workspaces:**
- Hundreds of projects
- Thousands of cards
- No performance issues expected

## Testing

### Mock Implementation

**Location:** `Tests/HieroglyphsTests/HieroglyphsVMTests.swift`

**MockFileWatcher:**

```swift
final class MockFileWatcher: FileWatching {
    var startWatchingCalled = false
    var stopWatchingCalled = false
    var watchedPath: String?
    var onChange: ((URL) -> Void)?

    func startWatching(path: String, onChange: @escaping (URL) -> Void) {
        startWatchingCalled = true
        watchedPath = path
        self.onChange = onChange
    }

    func stopWatching() {
        stopWatchingCalled = true
        onChange = nil
    }

    func simulateChange(url: URL) {
        onChange?(url)
    }
}
```

**Usage:**
- Tests inject MockFileWatcher into ViewModel
- Tests verify `startWatchingCalled` and `watchedPath`
- Tests use `simulateChange(url:)` to trigger file change handling
- Tests verify appropriate reload methods called

### Test Coverage

1. **testStartWatchingCalledOnLoadWorkspace:** Verify watching starts after workspace loads
2. **testStartWatchingNotCalledOnLoadWorkspaceFailure:** Verify watching not started if workspace load fails
3. **testStopWatching:** Verify stopWatching calls through to service
4. **testFileChangeTriggersProjectReload:** Verify project.md change reloads projects
5. **testFileChangeTriggersCardReload:** Verify card.md change reloads cards
6. **testFileChangeOutsideSelectedProjectIgnored:** Verify changes in other projects ignored

### Integration Testing

FileWatcherService not directly unit tested (requires real filesystem and runloop).

**Manual Testing:**
1. Launch app with workspace open
2. Edit card.md in external editor
3. Verify UI updates within ~500ms
4. Create new card via terminal
5. Verify card appears in UI
6. Delete card directory via Finder
7. Verify card disappears from UI

## External Change Scenarios

### Text Editor Changes

**Scenario:** User edits card.md in VS Code while app is running

**Flow:**
1. User saves changes in VS Code
2. FSEventStream detects file modification
3. ViewModel.handleFileChange(url:) called
4. Path matches selected project's card directory
5. ViewModel.loadCards() reloads card list
6. SwiftUI observes cards property change
7. CardList view updates to reflect changes

**Result:** Changes appear in UI within ~500ms, no manual refresh needed.

### LLM Tool Changes

**Scenario:** LLM assistant creates new card via file I/O

**Flow:**
1. LLM writes new card.md file and frontmatter
2. FSEventStream detects file creation
3. ViewModel.handleFileChange(url:) called
4. Path matches selected project's card directory
5. ViewModel.loadCards() reloads card list
6. SwiftUI observes cards property change
7. CardList view updates to include new card

**Result:** New card appears immediately, fully integrated with existing UI state.

### Terminal Commands

**Scenario:** User deletes card directory via `rm -rf` command

**Flow:**
1. `rm -rf` removes card directory
2. FSEventStream detects directory deletion
3. ViewModel.handleFileChange(url:) called
4. Path matches selected project's card directory
5. ViewModel.loadCards() reloads card list
6. Deleted card not returned by WorkspaceService
7. SwiftUI observes cards property change
8. CardList view removes deleted card

**Result:** Card disappears from UI, no stale data.

## Multiple Directory Watching

**Overview:** FileWatcherService supports watching multiple directories simultaneously using separate FSEventStream instances. This enables real-time updates of workspace files, external phases directories (for Ushabti integration), and Pharaoh status files.

### Triple FSEventStream Architecture

**Implementation:** Three independent FSEventStream instances monitor different paths:
- **Workspace stream:** Monitors `{workspacePath}/` recursively for project and card changes
- **Phases stream:** Monitors `{sourceDirectory}/.ushabti/phases/` recursively for phase file changes
- **Pharaoh stream:** Monitors `{sourceDirectory}/.pharaoh/` recursively for Pharaoh status changes

**Resource Management:** All streams use main queue dispatch and share the same latency (0.5s). Each stream has independent lifecycle methods (`startWatching`/`stopWatching`, `startWatchingPhases`/`stopWatchingPhases`, and `startWatchingPharaoh`/`stopWatchingPharaoh`).

### Phases Watching Lifecycle

**Startup:**
1. `startWatching()` is called after workspace loads successfully
2. If `selectedProject.sourceDirectory` is set, construct phases path
3. Check if phases directory exists via `FileManager.fileExists`
4. If exists, call `fileWatcher?.startWatchingPhases(path:onChange:)`
5. onChange closure calls `handlePhaseFileChange(url:)`

**Project Selection Changes:**
1. User selects different project in sidebar
2. MainWindow detects change via `.onChange(of: viewModel.selectedProject)`
3. Calls `viewModel.restartPhasesWatching()`
4. Stops old phases watching, starts new for current project's sourceDirectory
5. No watching if new project has no sourceDirectory

**Shutdown:**
1. `stopWatching()` calls both `stopWatching` and `stopPhasesWatching`
2. Both streams cleaned up simultaneously
3. Safe to call multiple times

### Phase File Change Handling

**handlePhaseFileChange(url:):**

```swift
private func handlePhaseFileChange(url: URL) {
    let path = url.path

    // Check if path contains phases directory and phase files
    if path.contains("/.ushabti/phases/") && (path.contains(".yaml") || path.contains(".md")) {
        loadPhases()
    }
}
```

**Watched Files:**
- `progress.yaml` — Phase progress tracking
- `phase.md` — Phase intent and scope
- `review.md` — Phase review notes
- `steps.md` — Implementation steps

**Behavior:**
- Changes detected within ~500ms (FSEvents latency)
- Full phases reload when any phase file changes
- **Selection preserved by slug** — Selected phase remains selected after reload if phase still exists
- UI updates automatically to reflect external edits by Ushabti agents

### Edge Cases

**Missing Phases Directory:**
- Phases watching not started if `.ushabti/phases/` does not exist
- No errors logged or thrown
- Normal behavior for projects without Ushabti integration

**Nil Source Directory:**
- Phases watching not started if `selectedProject.sourceDirectory` is nil
- Projects without external source directories use normal workspace-only watching

**External Source Directory:**
- Phases directory may be outside workspace directory
- Full absolute path constructed from `sourceDirectory` property
- Handles invalid paths gracefully (no watching, no errors)

**Permission Errors:**
- FSEventStream handles permission errors internally
- No crashes or exceptions propagated to application
- Watching silently fails for inaccessible directories

### Pharaoh Watching Lifecycle

**Startup:**
1. Pharaoh watching typically starts when user navigates to Pharaoh view for a project
2. If `selectedProject.sourceDirectory` is set, construct pharaoh path (`{sourceDirectory}/.pharaoh/`)
3. Check if pharaoh directory exists via `FileManager.fileExists`
4. If exists, call `fileWatcher?.startWatchingPharaoh(path:onChange:)`
5. onChange closure calls `handlePharaohFileChange(url:)`

**Status Updates:**
1. Pharaoh server writes status updates to `.pharaoh/pharaoh.json`
2. FSEventStream detects file modification
3. `handlePharaohFileChange` filters for `pharaoh.json` changes
4. PharaohView refreshes status display via polling (every 2 seconds) combined with file watching

**Shutdown:**
1. `stopWatchingPharaoh()` stops pharaoh stream independently
2. Safe to call multiple times
3. Independent of workspace and phases streams

**Behavior:**
- Changes detected within ~500ms (FSEvents latency)
- Pharaoh status updates trigger UI refresh in PharaohView and SidebarPharaohItem
- Log file (`.pharaoh/pharaoh.log`) also monitored for real-time log viewing
- UI updates automatically when Pharaoh transitions between idle/busy/done/blocked states

## Future Enhancements

### Debouncing

**Problem:** Rapid consecutive saves trigger multiple reloads

**Solution:** Add debounce logic to reload at most once per second:

```swift
private var reloadTimer: Timer?

private func scheduleReload() {
    reloadTimer?.invalidate()
    reloadTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
        self.loadProjects()
        self.loadCards()
    }
}
```

### Granular Updates

**Problem:** Entire list reload is inefficient for large workspaces

**Solution:** Diff file changes and update only affected items:

```swift
private func handleProjectChange(url: URL) {
    guard let slug = extractSlugFromURL(url) else { return }

    if let index = projects.firstIndex(where: { $0.slug == slug }) {
        // Reload single project
        if let updated = try? workspaceService.loadProject(slug: slug) {
            projects[index] = updated
        }
    } else {
        // New project, reload list
        loadProjects()
    }
}
```

### Conflict Resolution

**Problem:** User edits card in app while external tool also edits

**Solution:** Detect concurrent edits and show merge UI:

```swift
private func detectConflict(card: Card, externalCard: Card) -> Bool {
    return card.updated != externalCard.updated
}
```

### Change Notifications

**Problem:** Silent updates may confuse users

**Solution:** Show non-modal toast notification on external changes:

```swift
private func showChangeNotification(message: String) {
    // Display temporary UI notification
}
```

### Extended Attributes Watching

**Problem:** Tag changes in Finder not detected

**Solution:** Monitor extended attributes and sync back to frontmatter (requires careful one-way sync design per L08).
