# Phase 8: Filesystem Watcher

## Intent

Implement live filesystem monitoring to detect external changes to workspace files and automatically refresh the UI. A `FileWatcherService` conforming to a `FileWatching` protocol monitors the workspace directory tree using FSEvents (macOS native file system monitoring). When files are created, modified, or deleted by external tools (text editors, LLMs, command-line scripts), the watcher notifies the ViewModel which triggers a re-read of affected data from WorkspaceService and refreshes the UI without manual intervention. This fulfills L05 (External Changes Are First-Class) and L06 (Platform Leverage Over Reinvention).

## Scope

**In scope:**
- `FileWatching` protocol defining the service contract
- `FileWatcherService` implementation using FSEventStream API
- ViewModel integration: `startWatching()` and `stopWatching()` methods
- ViewModel change handlers: reload projects when workspace changes, reload cards when project changes
- SwiftUI environment key for dependency injection
- Tests for ViewModel watching methods with mock FileWatcher
- Documentation: new `file-watching.md` doc and updates to `architecture.md` and `viewmodel.md`

**Out of scope:**
- Debouncing or throttling of reload operations (future optimization if needed)
- Granular change detection (file-level diffing to minimize reloads; future enhancement)
- Conflict resolution UI (if app and external tool edit simultaneously; future)
- File watching for config file changes (workspace path change requires app restart; acceptable for v1)
- Pause/resume watching UI (always active when workspace loaded; future)
- Change notifications or toasts (silent refresh; future UX enhancement)
- Extended attributes watching (tag reconciliation deferred to future phase)

## Constraints

**Laws:**
- L05 (External Changes Are First-Class): This phase directly implements the requirement that external edits are detected and reflected in UI
- L06 (Platform Leverage): Use FSEvents API (FSEventStream), not custom polling or DispatchSource-based file watching
- L09 (Sandi Metz): Protocol-based service, injected via environment, stateless design
- L11 (Test Coverage): ViewModel watching methods tested with mock FileWatcher

**Style:**
- Protocol first: `FileWatching` protocol defines contract, `FileWatcherService` implements
- Small, focused service: FileWatcher does one thing (monitors directory, calls closure on changes)
- ViewModel coordination: ViewModel owns watching lifecycle (start on workspace load, stop on dealloc)
- Dependency injection: FileWatcher injected via SwiftUI environment like WorkspaceService

## Acceptance Criteria

1. **FileWatching protocol exists**: Defines `startWatching(path:onChange:)` and `stopWatching()` methods
2. **FileWatcherService implements protocol**: Uses FSEventStream to monitor directory recursively
3. **FSEventStream configured correctly**: Monitors workspace path recursively, reports file-level events, has appropriate latency (e.g., 0.5 seconds)
4. **onChange closure called on file changes**: When external tool edits a file in workspace, closure is invoked with event details
5. **ViewModel.startWatching() works**: Called when workspace is loaded, starts monitoring workspace path
6. **ViewModel.stopWatching() works**: Called on deinit or workspace unload, stops monitoring
7. **Project list reloads on workspace changes**: When project.md created/modified/deleted externally, ViewModel reloads projects
8. **Card list reloads on project changes**: When card.md created/modified/deleted externally in selected project, ViewModel reloads cards
9. **Tests pass**: ViewModel tests with mock FileWatcher verify watching lifecycle
10. **Docs updated**: New `file-watching.md` doc created; `architecture.md` updated with file watching section; `viewmodel.md` updated with watching methods

**Acceptance test (manual):**
1. Launch Hieroglyphs with workspace open
2. Open a card.md file in external text editor (VS Code, TextEdit, etc.)
3. Edit title in frontmatter, save file
4. Verify Hieroglyphs UI updates to reflect new title without manual refresh
5. Create a new card.md file via terminal (mkdir + echo)
6. Verify new card appears in card list without manual refresh
7. Delete a card directory via Finder (move to Trash)
8. Verify card disappears from card list without manual refresh

## Risks / Notes

- **Reload frequency**: Every file change triggers a reload. If user makes rapid changes (e.g., saving frequently while typing), reloads may be excessive. Acceptable for v1; future optimization may add debouncing (reload at most once per second).
- **Performance with large workspaces**: FSEvents monitors entire workspace recursively. With hundreds of projects and thousands of cards, reload may be slow. Acceptable for v1 (target workspaces are small); future optimization may add granular diffing to reload only changed items.
- **Concurrent edits**: If user edits a card in Hieroglyphs while external tool also edits it, last write wins (no conflict resolution). Acceptable for v1; future enhancement may add conflict detection and merge UI.
- **FSEventStream latency**: Events are batched and delivered with latency (default 0.5 seconds). UI updates are not instant but near-instant. Acceptable tradeoff for efficiency.
- **Memory and resources**: FSEventStream is lightweight and efficient. No significant resource impact expected for typical workspaces.
- **Testing limitations**: FSEventStream requires real filesystem and runloop. Tests use mock FileWatcher to verify ViewModel logic; FileWatcherService tested manually (integration test style).
