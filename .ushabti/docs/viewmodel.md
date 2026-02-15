# ViewModel Layer

## Overview

`HieroglyphsVM` is the single shared ViewModel coordinating workspace state and UI interactions. It acts as the bridge between WorkspaceService (filesystem I/O) and Views (SwiftUI UI). The ViewModel holds transient state (selected project, loaded projects) and delegates all I/O to WorkspaceService.

**Location:** `Sources/Hieroglyphs/HieroglyphsVM.swift`

**Pattern:** MVVM with single shared coordinator

**Annotations:** `@Observable`, `@MainActor`

The ViewModel supports L01 (Filesystem as Source of Truth by delegating to service), L09 (Protocol-Based Services), and follows SwiftUI best practices for observation and main-thread isolation.

## HieroglyphsVM Class

**Purpose:** Coordinate workspace state, project list, and selected section for UI binding.

**Selection Model:**

The ViewModel uses a hierarchical selection model via `SidebarSection` enum:

```swift
enum SidebarSection: Hashable {
    case cards(Project)
    case plans(Project)
    case phases(Project)
    case pharaoh(Project)
}
```

**State Properties:**
- `workspacePath: String?` — Absolute path to workspace directory (nil if not loaded)
- `projects: [Project]` — Array of loaded projects (empty if not loaded or no projects exist)
- `selectedSection: SidebarSection?` — Currently selected section in sidebar (nil if none selected)
- `selectedProject: Project?` — Computed property extracting project from selectedSection (nil if none selected)
- `cards: [Card]` — Array of loaded cards for selected project (empty if not loaded or no cards exist)
- `selectedCard: Card?` — Currently selected card in card list (nil if none selected)
- `searchText: String` — Search query for filtering cards by title
- `filterStatus: Set<CardStatus>` — Active status filters (empty set = show all)
- `filterType: Set<CardType>` — Active type filters (empty set = show all)
- `filterPriority: Set<Priority>` — Active priority filters (empty set = show all)
- `sortBy: CardSortOption` — Sort criteria (created, updated, priority, status, title)
- `sortOrder: SortOrder` — Sort direction (forward = ascending, reverse = descending)
- `showDoneAndArchived: Bool` — Toggle for showing/hiding done and archived cards (default: false, state is ephemeral)
- `showDonePlans: Bool` — Toggle for showing/hiding done plans (default: false, state is ephemeral)
- `showingNewProjectSheet: Bool` — Controls New Project sheet presentation (false = hidden)
- `showingNewCardSheet: Bool` — Controls New Card sheet presentation (false = hidden)
- `showingNewPlanSheetFromCard: Bool` — Controls New Plan sheet presentation from card (false = hidden)
- `sourceCardForNewPlan: Card?` — Card to pre-link when creating plan from card (nil = no pre-link)
- `focusSearch: Bool` — Triggers search field focus when set to true (resets to false after use)

**Service Dependencies:**
- `workspaceService: WorkspaceProviding` — Injected service for I/O operations
- `fileWatcher: FileWatching?` — Optional injected service for file system monitoring
- `tagReconciler: TagReconciling?` — Optional injected service for tag projection to extended attributes
- `searchService: SearchProviding?` — Optional injected service for Spotlight search
- `phaseService: PhaseProviding?` — Optional injected service for Ushabti phase loading
- `planService: PlanProviding?` — Optional injected service for plan CRUD operations
- `pharaohService: PharaohProviding?` — Optional injected service for Pharaoh process management

**Initialization:**
```swift
init(
    workspaceService: WorkspaceProviding,
    fileWatcher: FileWatching? = nil,
    tagReconciler: TagReconciling? = nil,
    searchService: SearchProviding? = nil
)
```

**Notes:**
- `@Observable` enables SwiftUI automatic view updates when properties change
- `@MainActor` ensures all methods run on main thread (required for UI updates)
- ViewModel is created in `App.swift` and injected via `.environment(viewModel)`

## Methods

### initializeWorkspace(at:)

**Signature:** `func initializeWorkspace(at: String)`

**Purpose:** Initialize a new workspace at the specified path.

**Parameters:**
- `at` — Absolute path to workspace directory to create

**Behavior:**

1. Call `workspaceService.createWorkspace(at:configDirectory:)` to create workspace directory and config file
2. Call `workspaceService.initializeWorkspaceFiles(at:)` to generate CLAUDE.md and AGENT.md
3. Call `loadWorkspace()` to load newly created workspace
4. If any step throws, catch error and log to console

**Error Handling:**

Errors are logged to console via `print()`. Workspace path remains nil and projects remain empty on error.

**Example error output:**
```
Failed to initialize workspace: directoryCreationFailed(...)
```

**Usage:**

Called from `WelcomeView` when user selects workspace folder:

```swift
viewModel.initializeWorkspace(at: selectedURL.path)
```

**Notes:**
- Only called on first launch when no config exists
- Creates config at `~/.hieroglyphs/config.yaml`
- Generates instructional files (CLAUDE.md, AGENT.md) in workspace root
- Automatically loads workspace after successful initialization

### loadWorkspace()

**Signature:** `func loadWorkspace()`

**Purpose:** Load workspace configuration and project list on app launch.

**Behavior:**

1. Call `workspaceService.loadWorkspaceConfig(from: nil)` to load config from `~/.hieroglyphs/config.yaml`
2. Extract `workspacePath` from config
3. Call `workspaceService.loadProjects(from: workspacePath)` to load all projects
4. Update `self.workspacePath` and `self.projects`
5. Call `startWatching()` to begin monitoring workspace for external changes
6. If any step throws, catch error, log to console, set `workspacePath` to `nil` and `projects` to `[]`

**Error Handling:**

Errors are logged to console via `print()`. No user-facing error UI in current implementation. Workspace path and projects remain nil/empty on error.

**Example error output:**
```
Failed to load workspace: configNotFound
```

**Usage:**

Called once in `App.swift` via `.onAppear` on `MainWindow`:

```swift
.onAppear {
    viewModel.loadWorkspace()
}
```

**Notes:**
- This method is idempotent (safe to call multiple times, but typically called once)
- If config does not exist, workspace is not loaded and UI shows empty state
- Future phases may add retry or onboarding UI for missing config

### createProject(title:description:tags:)

**Signature:** `func createProject(title: String, description: String, tags: [String])`

**Purpose:** Create a new project and refresh project list.

**Parameters:**
- `title` — Project title (must be non-empty; validated by UI)
- `description` — Project description (may be empty)
- `tags` — Array of tag strings (may be empty)

**Behavior:**

1. Check `workspacePath` is not nil (log error and return if nil)
2. Call `workspaceService.createProject(title:description:tags:at:)` with workspace path
3. Call `workspaceService.loadProjects(from:)` to reload project list (includes newly created project)
4. Update `self.projects` with reloaded list
5. Auto-select newly created project: Set `selectedSection` to `.cards(newProject)`
6. If any step throws, catch error and log to console

**Error Handling:**

Errors are logged to console via `print()`. Project is not created on error. Project list is not updated.

**Example error output:**
```
Cannot create project: workspace path is nil
Failed to create project: directoryCreationFailed(...)
```

**Usage:**

Called from `NewProjectSheet` on save:

```swift
viewModel.createProject(
    title: title,
    description: description,
    tags: parsedTags
)
```

**Notes:**
- Does NOT check for slug collisions (future enhancement)
- Reloads entire project list after creation (inefficient but simple; future optimization may add new project to list directly)
- If workspace path is nil, operation fails silently (logs error)
- Auto-selects newly created project's Cards section in sidebar (L17: UI State Correctness)

### selectSection(_:)

**Signature:** `func selectSection(_ section: SidebarSection?)`

**Purpose:** Update selected section state and manage detail selections when project or section type changes.

**Parameters:**
- `section` — The section to select (nil to deselect)

**Behavior:**

1. Capture current `selectedProject` (extracted from current `selectedSection`)
2. Set `self.selectedSection = section`
3. Extract new `selectedProject` from new `selectedSection`
4. If project changed (old project ID ≠ new project ID):
   - Clear all detail selections (`selectedCard`, `selectedPlan`, `selectedPhase`)
   - Return (skip cross-section clearing)
5. If only section type changed within same project:
   - Clear cross-section selections (e.g., switching from Cards to Plans clears `selectedCard` and `selectedPhase`)

**Project Change Detection:**

When the user switches from one project to another (e.g., Project A's Cards → Project B's Cards), the method detects the project change and clears all detail selections to prevent stale content from appearing in the detail column.

**Cross-Section Clearing:**

When switching between section types within the same project (e.g., Cards → Plans), only incompatible selections are cleared. This ensures the detail column shows content appropriate to the current section type.

**Usage:**

Called implicitly via SwiftUI binding in `Sidebar`:

```swift
List(selection: $bindableViewModel.selectedSection) {
    // Each section is tagged with SidebarSection enum case
}
```

SwiftUI automatically calls `selectSection(_:)` when user clicks a section row.

**Notes:**
- Project change clearing prevents stale content bugs when switching projects
- Cross-section clearing ensures detail column consistency
- Selection state is ephemeral (not persisted across app launches)
- Combined with `.id()` modifiers in MainWindow, ensures views reset completely on project change

### loadCards()

**Signature:** `func loadCards()`

**Purpose:** Load cards for the currently selected project.

**Behavior:**

1. Guard check `selectedProject` is not nil (sets cards to empty array and returns if nil)
2. Guard check `workspacePath` is not nil (logs error, sets cards to empty array, and returns if nil)
3. Construct project path from workspace path and selected project slug
4. If `selectedProject.sourceDirectory` is set:
   - Call `workspaceService.ingestCardsFromUshabti(projectPath:sourceDirectory:)` to import cards from Ushabti agents
   - Log count of ingested cards if > 0
   - If ingestion fails, catch error, log warning, and continue (does not block card loading)
5. Call `workspaceService.loadCards(from:for:)` to load all cards
6. Update `self.cards` with loaded cards
7. If card loading throws, catch error, log to console, and set `cards` to empty array

**Error Handling:**

Errors are logged to console via `print()`. Cards array is set to empty on error.

**Example error output:**
```
Cannot load cards: workspace path is nil
Failed to load cards: invalidDirectory
```

**Usage:**

Called automatically when selected project changes via `.onChange` modifier in `CardList`:

```swift
.onChange(of: viewModel.selectedProject) { _, _ in
    viewModel.loadCards()
}
```

**Notes:**
- Reloads all cards from disk on every call (no caching)
- Empty array when no project selected or on error
- Automatically ingests cards from `.ushabti/cards/` when `sourceDirectory` is set
- Ingestion errors are logged but do not prevent card loading
- Future optimization may add caching or incremental loading

### loadPlans()

**Signature:** `func loadPlans()`

**Purpose:** Load plans from the selected project's plans directory.

**Behavior:**

1. Guard check `selectedProject` is not nil (sets plans to empty array and returns if nil)
2. Guard check `workspacePath` is not nil (logs error, sets plans to empty array, and returns if nil)
3. Guard check `planService` is not nil (logs error, sets plans to empty array, and returns if nil)
4. Call `planService.loadPlans(projectPath:)` to load all plans
5. Update `self.plans` with loaded plans
6. Clear `selectedPlan` if the selected plan no longer exists in the loaded array
7. If loading throws, catch error, log to console, and set `plans` to empty array

**Selection Clearing:**

When plans reload (triggered by FSEvents watching the project directory), the selection is cleared if the selected plan was deleted externally. This ensures the detail view shows an empty state rather than stale content from a deleted plan.

Selection is NOT preserved across reloads. When the project changes (handled by `selectSection(_:)`), all detail selections are cleared. Within the same project, selection is maintained by SwiftUI's identity system unless the item is deleted.

**Error Handling:**

Errors are logged to console via `print()`. Plans array is set to empty on error.

**Example error output:**
```
Cannot load plans: workspace path is nil
Cannot load plans: plan service is nil
Failed to load plans: invalidDirectory
```

**Usage:**

Called automatically when selected project changes and when plan files change externally.

**Notes:**
- Reloads all plans from disk on every call (no caching)
- Empty array when no project selected or on error
- Selection cleared only when plan no longer exists (deletion case)

### dispatchPlan()

**Signature:** `func dispatchPlan()`

**Purpose:** Dispatch the selected plan to Pharaoh for automated execution.

**Behavior:**

1. Guard check: `selectedPlan`, `selectedProject`, `sourceDirectory` all non-nil
2. Create `.pharaoh/dispatch/` directory if needed
3. Write markdown file with frontmatter to `.pharaoh/dispatch/{plan-slug}.md`
4. Set plan status to `inProgress` via `updatePlanStatus()`

**Dispatch File Format:**
```markdown
---
phase: {plan-slug}
model: opus
---

{plan.phasePrompt}
```

**Error Handling:**

Errors are logged to console via `print()`. No UI alerts shown.

**Usage:**

Called from PlanDetail toolbar dispatch button after user confirms via alert dialog.

**Notes:**
- Requires project with configured `sourceDirectory`
- Pharaoh server must be running and idle (checked by canDispatch in PlanDetail)
- Plan must be in `ready` status with non-empty phase prompt
- See `.ushabti/docs/pharaoh-integration.md` for full dispatch workflow

### loadPhases()

**Signature:** `func loadPhases()`

**Purpose:** Load phases from the selected project's sourceDirectory.

**Behavior:**

1. Guard check `selectedProject` is not nil (sets phases to empty array and returns if nil)
2. Guard check `sourceDirectory` is set (sets phases to empty array and returns if nil)
3. Guard check `phaseService` is not nil (logs error, sets phases to empty array, and returns if nil)
4. Call `phaseService.loadPhases(from:)` to load all phases
5. Update `self.phases` with loaded phases
6. Clear `selectedPhase` if the selected phase no longer exists in the loaded array
7. If loading throws, catch error, log to console, and set `phases` to empty array

**Selection Clearing:**

When phases reload (triggered by FSEvents watching `.ushabti/phases/` directory), the selection is cleared if the selected phase was deleted externally. This ensures the detail view shows an empty state rather than stale content from a deleted phase.

Selection is NOT preserved across reloads. When the project changes (handled by `selectSection(_:)`), all detail selections are cleared. Within the same project, selection is maintained by SwiftUI's identity system unless the item is deleted.

**Error Handling:**

Errors are logged to console via `print()`. Phases array is set to empty on error.

**Example error output:**
```
Cannot load phases: phase service is nil
Failed to load phases: invalidDirectory
```

**Usage:**

Called automatically when `handlePhaseFileChange` detects changes in `.ushabti/phases/` directory:

```swift
private func handlePhaseFileChange(url: URL) {
    let path = url.path
    if path.contains("/.ushabti/phases/") && (path.contains(".yaml") || path.contains(".md")) {
        loadPhases()
    }
}
```

**Notes:**
- Reloads all phases from disk on every call (no caching)
- Empty array when no project selected, no sourceDirectory, or on error
- Selection cleared only when phase no longer exists (deletion case)
- Only loads phases when selectedProject has sourceDirectory configured

### createCard(title:type:status:priority:tags:body:)

**Signature:** `func createCard(title:type:status:priority:tags:body:)`

**Purpose:** Create a new card and reload the card list.

**Parameters:**
- `title` — Card title (must be non-empty; validated by UI)
- `type` — Card type (task, bug, feature, note)
- `status` — Card status (backlog, todo, in-progress, done, archived)
- `priority` — Card priority (low, medium, high, critical)
- `tags` — Array of tag strings (may be empty)
- `body` — Markdown body content (may be empty)

**Behavior:**

1. Guard check `selectedProject` is not nil (log error and return if nil)
2. Guard check `workspacePath` is not nil (log error and return if nil)
3. Construct project path from workspace path and selected project slug
4. Call `workspaceService.createCard(...)` to write card to disk
5. Call `loadCards()` to reload card list (includes newly created card)
6. Auto-select newly created card: Find card in reloaded array by slug and set as `selectedCard`
7. If any step throws, catch error and log to console

**Error Handling:**

Errors are logged to console via `print()`. Card is not created on error. Card list is not updated.

**Example error output:**
```
Cannot create card: no project selected
Cannot create card: workspace path is nil
Failed to create card: directoryCreationFailed(...)
```

**Usage:**

Called from `NewCardSheet` on save:

```swift
viewModel.createCard(
    title: title,
    type: type,
    status: status,
    priority: priority,
    tags: parsedTags,
    body: cardBody
)
```

**Notes:**
- Does NOT check for slug collisions (future enhancement)
- Reloads entire card list after creation (inefficient but simple; future optimization may add new card to list directly)
- If workspace path or selected project is nil, operation fails silently (logs error)
- Auto-selects newly created card in CardList and displays in CardDetail (L17: UI State Correctness)

### updateCard(_:)

**Signature:** `func updateCard(_ card: Card)`

**Purpose:** Update an existing card and reload the card list with immediate write.

**Parameters:**
- `card` — The card to update (with modified fields)

**Behavior:**

1. Guard check `selectedProject` is not nil (log error and return if nil)
2. Guard check `workspacePath` is not nil (log error and return if nil)
3. Construct project path from workspace path and selected project slug
4. Call `workspaceService.updateCard(card, projectPath: projectPath)` to write changes to disk
5. Clear `lastDebouncedWritePath` to reset file watcher guard
6. Call `loadCards()` to reload card list (reflects updated card)
7. If any step throws, catch error and log to console

**Error Handling:**

Errors are logged to console via `print()`. Card is not updated on error. Card list is not reloaded.

**Example error output:**
```
Cannot update card: no project selected
Cannot update card: workspace path is nil
Failed to update card: cardNotFound
```

**Usage:**

Called from `CardDetail` for immediate writes (discrete actions like picker changes, tag operations):

```swift
func saveCard(debounced: Bool = false) {
    guard let editableCard else { return }
    if debounced {
        viewModel.updateCardDebounced(editableCard)
    } else {
        viewModel.updateCard(editableCard)
    }
}
```

**Notes:**
- Immediate writes for discrete actions (picker changes, tag add/remove)
- Use `updateCardDebounced(_:)` for continuous typing (title, body) to avoid lag
- Reloads entire card list after update (inefficient but simple; future optimization may update card in place)
- If workspace path or selected project is nil, operation fails silently (logs error)
- WorkspaceService preserves unknown frontmatter fields per L02

### updateCardDebounced(_:)

**Signature:** `func updateCardDebounced(_ card: Card)`

**Purpose:** Update an existing card with debouncing for continuous edits.

**Parameters:**
- `card` — The card to update (with modified fields)

**Behavior:**

1. Store card in `pendingCardUpdate` property
2. Schedule debounced action with 1.5 second delay
3. On delayed execution:
   - Guard check for pendingCardUpdate, selectedProject, workspacePath
   - Construct card path from workspace and project/card slugs
   - Set `lastDebouncedWritePath` to card path for file watcher guard
   - Call `updateCard(card)` to write to disk
   - Clear `pendingCardUpdate`
4. If called again before delay expires, previous schedule is canceled and new delay starts

**Usage:**

Called from `CardDetail` for continuous typing in title and body fields:

```swift
CardBodyEditor(
    content: bodyBinding,
    onUpdate: { saveCard(debounced: true) }
)
```

```swift
CardMetadataEditor(
    card: editableCardBinding,
    onUpdate: saveCard
)
// titleBinding calls onUpdate(true) for debounced save
```

**Notes:**
- Coalesces rapid updates into single write after 1.5 second delay
- Prevents typing lag by avoiding synchronous disk I/O on every keystroke
- Use `flushPendingCardUpdates()` to force immediate write before card deselection or app termination
- File watcher guard prevents reloading currently edited card when debounced write triggers

### flushPendingCardUpdates()

**Signature:** `func flushPendingCardUpdates()`

**Purpose:** Flush pending debounced card updates immediately.

**Behavior:**

1. Call `cardUpdateDebouncer.flush()` to execute pending action immediately
2. If pending action exists, it executes synchronously
3. Pending action writes card to disk via `updateCard()`

**Usage:**

Called before card deselection or app termination to ensure all edits persist:

```swift
.onChange(of: viewModel.selectedCard) { _, newCard in
    viewModel.flushPendingCardUpdates()
    editableCard = newCard
}
```

```swift
.onReceive(
    NotificationCenter.default.publisher(
        for: NSApplication.willTerminateNotification
    )
) { _ in
    viewModel.flushPendingCardUpdates()
}
```

**Notes:**
- Ensures no data loss when user switches cards or quits app
- Safe to call even if no pending update exists
- Executes synchronously to guarantee persistence before next operation

### startWatching()

**Signature:** `func startWatching()`

**Purpose:** Start monitoring workspace for external file changes.

**Behavior:**

1. Guard check `workspacePath` is not nil (returns early if nil)
2. Call `fileWatcher?.startWatching(path:onChange:)` with workspace path
3. onChange closure captures weak self and calls `handleFileChange(url:)` for each change

**Usage:**

Called automatically after successful `loadWorkspace()`:

```swift
func loadWorkspace() {
    do {
        // ... load config and projects ...
        startWatching()
    } catch {
        // ... error handling ...
    }
}
```

**Notes:**
- Only starts if workspace loaded successfully
- Safe to call multiple times (service stops previous watching before starting new)
- FileWatcher is optional; if nil (e.g., in tests), method does nothing

### stopWatching()

**Signature:** `func stopWatching()`

**Purpose:** Stop monitoring workspace and phases directories for external file changes.

**Behavior:**

1. Call `fileWatcher?.stopWatching()` to clean up workspace monitoring resources
2. Call `stopPhasesWatching()` to clean up phases monitoring resources

**Usage:**

Called manually by client code or tests:

```swift
viewModel.stopWatching()
```

**Notes:**
- Safe to call even if not currently watching
- Stops both workspace and phases watching simultaneously
- ViewModel does not call this in deinit due to Swift concurrency restrictions
- ViewModel is app-lifetime, so cleanup happens naturally on app termination

### stopPhasesWatching()

**Signature:** `func stopPhasesWatching()`

**Purpose:** Stop monitoring phases directory for external file changes.

**Behavior:**

1. Call `fileWatcher?.stopWatchingPhases()` to clean up phases monitoring resources

**Usage:**

Called by `stopWatching()` or manually by client code:

```swift
viewModel.stopPhasesWatching()
```

**Notes:**
- Safe to call even if not currently watching phases
- Independent of workspace watching lifecycle
- Used by `restartPhasesWatching()` to stop old phases watching before starting new

### restartPhasesWatching()

**Signature:** `func restartPhasesWatching()`

**Purpose:** Restart phases watching when project selection changes.

**Behavior:**

1. Stop current phases watching via `stopPhasesWatching()`
2. Check if `selectedProject` has `sourceDirectory` set
3. If set, construct phases path: `{sourceDirectory}/.ushabti/phases/`
4. Check if phases directory exists via `FileManager.fileExists`
5. If exists, start phases watching via `fileWatcher?.startWatchingPhases`
6. onChange closure calls `handlePhaseFileChange(url:)`

**Usage:**

Called automatically when project selection changes via MainWindow `.onChange` modifier:

```swift
.onChange(of: viewModel.selectedProject) { _, _ in
    viewModel.restartPhasesWatching()
}
```

**Notes:**
- Stops old phases watching before starting new
- Handles projects with no sourceDirectory (stops phases watching, does not start new)
- Handles missing phases directory (no watching, no errors)
- Enables per-project phases monitoring with automatic switching

## Lifecycle and Initialization

**App.swift:**

```swift
@main
struct HieroglyphsApp: App {
    @State private var viewModel: HieroglyphsVM
    private let workspaceService: WorkspaceProviding
    private let fileWatcher: FileWatching
    private let tagReconciler: TagReconciling
    private let searchService: SearchProviding

    init() {
        let service = WorkspaceService()
        let watcher = FileWatcherService()
        let reconciler = TagReconcilerService()
        let spotlight = SpotlightService()
        self.workspaceService = service
        self.fileWatcher = watcher
        self.tagReconciler = reconciler
        self.searchService = spotlight
        let vm = HieroglyphsVM(
            workspaceService: service,
            fileWatcher: watcher,
            tagReconciler: reconciler,
            searchService: spotlight
        )
        _viewModel = State(initialValue: vm)
    }

    var body: some Scene {
        Window("Hieroglyphs", id: "main") {
            MainWindow()
                .environment(viewModel)
                .environment(\.workspaceService, workspaceService)
                .environment(\.fileWatcher, fileWatcher)
                .environment(\.tagReconciler, tagReconciler)
                .environment(\.searchService, searchService)
                .onAppear {
                    viewModel.loadWorkspace()
                }
        }
    }
}
```

**Dependency Injection:**
1. Four concrete services created: WorkspaceService, FileWatcherService, TagReconcilerService, SpotlightService
2. `HieroglyphsVM` initialized with all four service dependencies
3. ViewModel injected via `.environment(viewModel)`
4. Services also injected via environment keys for views that need direct access

**Notes:**
- ViewModel is created once at app launch and shared across all views
- Service is stateless and safe to share
- `.onAppear` triggers workspace load after window appears

## View Access Patterns

**Accessing ViewModel in Views:**

```swift
struct Sidebar: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    var body: some View {
        List(selection: $bindableViewModel.selectedProject) {
            ForEach(viewModel.projects) { project in
                // ...
            }
        }
    }
}
```

**Notes:**
- Use `@Environment(HieroglyphsVM.self)` to access ViewModel
- Use `@Bindable` wrapper to create bindings from `@Observable` properties

**Accessing Service in Views:**

```swift
struct SidebarProjectEntry: View {
    @Environment(\.workspaceService) private var workspaceService

    // ...
}
```

**Notes:**
- Use `@Environment(\.workspaceService)` to access service
- Views may access service directly for operations not coordinated by ViewModel (e.g., loading cards for display)

## State Flow

**On App Launch:**

1. App.init creates WorkspaceService and HieroglyphsVM
2. MainWindow.onAppear calls `viewModel.loadWorkspace()`
3. ViewModel calls `workspaceService.loadWorkspaceConfig()` and `workspaceService.loadProjects()`
4. ViewModel updates `workspacePath` and `projects` properties
5. SwiftUI observes changes and updates Sidebar view
6. Sidebar renders project list

**On Project Creation:**

1. User clicks "New Project" button in Sidebar
2. NewProjectSheet appears
3. User enters title, description, tags and clicks Save
4. NewProjectSheet calls `viewModel.createProject(title:description:tags:)`
5. ViewModel calls `workspaceService.createProject(...)` to write project to disk
6. ViewModel calls `workspaceService.loadProjects(...)` to reload project list
7. ViewModel updates `projects` property
8. SwiftUI observes change and updates Sidebar view
9. NewProjectSheet dismisses

**On Project Selection:**

1. User clicks a project row in Sidebar
2. SwiftUI binding updates `viewModel.selectedProject` via `selectProject(_:)`
3. SwiftUI observes change and triggers `.onChange` in CardList
4. CardList calls `viewModel.loadCards()` to load cards for selected project
5. ViewModel updates `cards` property
6. SwiftUI observes change and updates CardList view

**On Card Creation:**

1. User clicks "New Card" button in CardList
2. NewCardSheet appears
3. User enters title, type, status, priority, tags, body and clicks Save
4. NewCardSheet calls `viewModel.createCard(...)`
5. ViewModel calls `workspaceService.createCard(...)` to write card to disk
6. ViewModel calls `loadCards()` to reload card list
7. ViewModel updates `cards` property
8. SwiftUI observes change and updates CardList view
9. NewCardSheet dismisses

**On External File Change:**

1. External tool (text editor, LLM, terminal) modifies a file in workspace
2. FSEventStream detects change and calls FileWatcherService onChange callback
3. FileWatcherService calls `viewModel.handleFileChange(url:)` with changed file URL
4. ViewModel examines path to determine reload action:
   - If path contains `/project.md`: calls `loadProjects()` to reload project list
   - If path contains `/cards/` or `/card.md` AND matches selected project: calls `loadCards()` to reload card list
   - Otherwise: ignores change
5. Reload methods call WorkspaceService to read from disk
6. ViewModel updates `projects` or `cards` property
7. SwiftUI observes change and updates UI automatically

**Example External Changes:**
- Edit card.md in VS Code → UI updates within ~500ms
- Create card via terminal → new card appears in UI
- Delete card directory via Finder → card disappears from UI
- Edit project.md in text editor → project list refreshes

## Testing

**File:** `HieroglyphsVMTests.swift`

**Strategy:** Use mock implementation of `WorkspaceProviding` to isolate ViewModel from filesystem.

**Mock Service:**

```swift
class MockWorkspaceService: WorkspaceProviding {
    var configToReturn: WorkspaceConfig?
    var projectsToReturn: [Project] = []
    var shouldThrowError = false

    func loadWorkspaceConfig(from configPath: String?) throws -> WorkspaceConfig {
        if shouldThrowError { throw WorkspaceError.configNotFound }
        return configToReturn!
    }

    func loadProjects(from workspacePath: String) throws -> [Project] {
        if shouldThrowError { throw WorkspaceError.invalidDirectory }
        return projectsToReturn
    }

    // ... other methods
}
```

**Test Cases:**

1. **loadWorkspace success:** Mock service returns config and projects, verify ViewModel updates state
2. **loadWorkspace config error:** Mock throws config error, verify workspacePath is nil and projects is empty
3. **loadWorkspace projects error:** Mock throws projects error, verify projects is empty
4. **createProject success:** Mock succeeds, verify ViewModel reloads projects
5. **createProject with nil workspacePath:** Verify operation fails gracefully
6. **selectProject:** Verify selectedProject updates correctly
7. **loadCards success:** Mock service returns cards, verify ViewModel updates cards
8. **loadCards with nil selectedProject:** Verify cards is empty
9. **loadCards error:** Mock throws error, verify cards is empty
10. **createCard success:** Mock succeeds, verify ViewModel reloads cards
11. **createCard with nil selectedProject:** Verify operation fails gracefully
12. **createCard error:** Mock throws error, verify cards is not updated
13. **updateCard success:** Mock service succeeds, verify ViewModel calls service and reloads cards
14. **updateCard with nil workspacePath:** Verify operation fails gracefully
15. **updateCard with nil selectedProject:** Verify operation fails gracefully

**Notes:**
- Tests verify coordination logic, not I/O (I/O tested in WorkspaceServiceTests)
- Tests use `@MainActor` to match ViewModel's main-thread isolation
- MockWorkspaceService tracks updateCard calls and last updated card for verification

### deleteProject(_:)

**Signature:** `func deleteProject(_ project: Project)`

**Purpose:** Delete a project and refresh the project list.

**Parameters:**
- `project` — The project to delete (must be non-nil)

**Behavior:**

1. Guard check `workspacePath` is not nil (log error and return if nil)
2. Construct project path: `"\(workspacePath)/\(project.slug)"`
3. Call `workspaceService.deleteProject(at: projectPath)` to move project directory to Trash
4. Set `selectedSection` to nil (clears both project and section selection)
5. Call `loadProjects()` to reload project list (excludes deleted project)
6. If any step throws, catch error and log to console

**Error Handling:**

Errors are logged to console via `print()`. Project is not deleted on error. Project list is not reloaded.

**Example error output:**
```
Cannot delete project: workspace path is nil
Failed to delete project: directoryNotFound
```

**Usage:**

Called from SidebarProjectEntry context menu, Sidebar toolbar delete button, and `deleteSelectedItem()`:

```swift
// Context menu in SidebarProjectEntry
.contextMenu {
    Button("Delete", systemImage: "trash", role: .destructive) {
        projectPendingDeletion = project
    }
}
.alert("Delete Project", isPresented: $showingDeleteAlert, presenting: projectPendingDeletion) { project in
    Button("Delete", role: .destructive) {
        viewModel.deleteProject(project)
        projectPendingDeletion = nil
    }
}

// Toolbar button in Sidebar
if viewModel.selectedProject != nil {
    Button("Delete Project", systemImage: "trash", role: .destructive) {
        projectPendingDeletion = viewModel.selectedProject
    }
}
```

**Notes:**
- Uses macOS Trash via FileManager.trashItem (reversible deletion)
- Deletes entire project directory including all cards, plans, and subdirectories
- Clears selection state to prevent stale content (L17: UI State Correctness)
- Deletion requires explicit confirmation via alert dialog (L18: Design Is How It Works)
- If workspace path is nil, operation fails silently (logs error)

### showNewProjectSheet()

**Signature:** `func showNewProjectSheet()`

**Purpose:** Show the New Project sheet.

**Behavior:** Sets `showingNewProjectSheet` to true, which triggers sheet presentation in Sidebar view.

**Usage:** Called from menu command (Cmd+Shift+N) or toolbar button click.

### showNewCardSheet()

**Signature:** `func showNewCardSheet()`

**Purpose:** Show the New Card sheet.

**Behavior:** Sets `showingNewCardSheet` to true, which triggers sheet presentation in CardList view.

**Usage:** Called from menu command (Cmd+N) or toolbar button click.

### deleteSelectedItem()

**Signature:** `func deleteSelectedItem()`

**Purpose:** Delete the currently selected card or project.

**Behavior:**

1. Guard check `workspacePath` is not nil (log error and return if nil)
2. If `selectedCard` is not nil:
   - **Clean up plan symlinks first:** Call `planService?.removeCardSymlinksFromPlans(cardSlug:projectPath:)` to remove all symlinks to this card from all plans
   - If symlink cleanup fails, log warning but continue (best-effort, does not block deletion)
   - Call `workspaceService.deleteCard(slug:projectPath:)` to move card to Trash
   - Set `selectedCard` to nil
   - Call `loadCards()` to reload card list
   - Call `loadPlans()` to refresh plan state (symlinks removed)
3. Else if `selectedProject` is not nil:
   - Call `workspaceService.deleteProject(at:)` to move project to Trash
   - Set `selectedProject` to nil
   - Call `loadProjects()` to reload project list
4. If any step throws, catch error and log to console

**Error Handling:**

Errors are logged to console via `print()`. Item is not deleted on error. Symlink cleanup errors are logged as warnings but do not prevent deletion.

**Example error output:**
```
Cannot delete: workspace path is nil
Failed to delete: projectNotFound
```

**Usage:**

Called from menu command (Cmd+Delete):

```swift
Button("Delete") {
    viewModel.deleteSelectedItem()
}
.keyboardShortcut(.delete, modifiers: .command)
```

**Notes:**
- Deletes card if both card and project are selected
- Deletes project only if no card is selected
- Does nothing if neither card nor project is selected
- Uses macOS Trash (reversible deletion)

### requestSearchFocus()

**Signature:** `func requestSearchFocus()`

**Purpose:** Request focus on the search field.

**Behavior:** Sets `focusSearch` to true, which triggers focus change in CardList view. CardList resets flag to false after focusing.

**Usage:** Called from menu command (Cmd+F).

**Notes:**
- Flag is reset to false by CardList after use (one-shot trigger)
- Uses `.searchable(isPresented:)` modifier to control search field visibility

### createPlanFromCard(_:)

**Signature:** `func createPlanFromCard(_ card: Card)`

**Purpose:** Create a new plan from a card in a single operation, automatically linking the card and setting the plan title.

**Parameters:**
- `card` — The card to create a plan from

**Behavior:**

1. Guard check `selectedProject` is not nil (log error and return if nil)
2. Guard check `workspacePath` is not nil (log error and return if nil)
3. Guard check `planService` is not nil (log error and return if nil)
4. Call `planService.findNextPlanNumber(projectPath:)` to get next plan number
5. Generate plan title: `"Implement \(card.title)"`
6. Call `planService.createPlan(title:number:projectPath:)` to create plan
7. Call `planService.addCardToPlan(cardSlug:planSlug:projectPath:)` to link card
8. Call `loadPlans()` to refresh plan list
9. If any step throws, catch error and log to console

**Error Handling:**

Errors are logged to console via `print()`. Plan is not created on error. Plan list is not updated.

**Example error output:**
```
Cannot create plan from card: no project selected
Cannot create plan from card: workspace path is nil
Failed to create plan from card: planNotFound
```

**Usage:**

**Deprecated:** This method is retained for backward compatibility but is no longer called from UI. Use `showNewPlanSheetFromCard(_:)` instead, which opens NewPlanSheet modal for user input.

**Notes:**
- Auto-increments plan number (no manual number entry required)
- Generates plan title from card title (e.g., "Implement Add dark mode")
- Creates plan in `planning` status with empty phase prompt
- Links card immediately after plan creation
- No modal or sheet shown (immediate creation)
- Reloads plan list to reflect new plan

### showNewPlanSheetFromCard(_:)

**Signature:** `func showNewPlanSheetFromCard(_ card: Card)`

**Purpose:** Show the New Plan sheet with a source card pre-linked for user input before plan creation.

**Parameters:**
- `card` — The card to pre-link to the new plan

**Behavior:**

1. Set `sourceCardForNewPlan` to the provided card
2. Set `showingNewPlanSheetFromCard` to true
3. Triggers NewPlanSheet presentation with card pre-population

**Usage:**

Called from CardListEntry context menu and CardDetail toolbar button:

```swift
// Context menu in CardListEntry
.contextMenu {
    Button {
        viewModel.showNewPlanSheetFromCard(card)
    } label: {
        Label("Create Plan", systemImage: "flowchart")
    }
}

// Toolbar button in CardDetail
Button {
    if let card = viewModel.selectedCard {
        viewModel.showNewPlanSheetFromCard(card)
    }
} label: {
    Label("Create Plan", systemImage: "flowchart")
}
.disabled(viewModel.selectedCard == nil)
```

**Notes:**
- Opens NewPlanSheet modal instead of immediate plan creation
- User can edit plan title before saving
- Card is automatically linked after plan is created
- Modal workflow follows NewCardSheet and NewProjectSheet patterns
- Provides better UX by allowing title editing before creation

### refreshSelectedPlan()

**Signature:** `private func refreshSelectedPlan()`

**Purpose:** Refresh selectedPlan to point to the updated Plan object in the plans array after reloading from disk.

**Behavior:**

1. Guard check `selectedPlan` is not nil (returns early if nil)
2. Find plan in `plans` array matching `selectedPlan.slug`
3. If found, set `selectedPlan` to the updated Plan object from the array
4. If not found (plan was deleted), do nothing (leave `selectedPlan` as-is)

**Rationale:**

Plan is a value type (struct). After calling `loadPlans()`, the plans array contains fresh Plan objects loaded from disk. The old `selectedPlan` and the new plan in the array are separate copies. Without this refresh, `selectedPlan` points to stale data, causing views to display outdated information (L17: UI State Correctness).

This method follows the same pattern as `updateProject()`, which refreshes `selectedSection` to point to the updated Project object after reloading projects.

**Usage:**

Called after `loadPlans()` in all three plan mutation methods:
- `addCardToPlan()` — after adding a card to a plan
- `removeCardFromPlan()` — after removing a card from a plan
- `updatePlanStatus()` — after changing plan status

**Example:**

```swift
func addCardToPlan(cardSlug: String, planSlug: String) {
    // ... guards and setup ...
    do {
        try planService.addCardToPlan(
            cardSlug: cardSlug,
            planSlug: planSlug,
            projectPath: projectPath
        )
        loadPlans()           // Reload plans from disk
        refreshSelectedPlan() // Update selectedPlan to point to fresh plan
    } catch {
        print("Failed to add card to plan: \(error)")
    }
}
```

**Notes:**
- Private method (internal implementation detail)
- Safe to call even if `selectedPlan` is nil or plan no longer exists
- Does NOT clear selection if plan is deleted — that's handled by `loadPlans()`
- Ensures PlanDetail view displays updated data after mutations

## Future Enhancements

**Planned features not yet implemented:**

1. **Error UI:** Display user-facing error messages instead of console logging
2. **Slug collision detection:** Check for existing projects/cards with same slug before creating
3. **Project editing:** Add `updateProject(_:)` method to ViewModel
4. **Selection persistence:** Persist selectedProject and selectedCard to UserDefaults and restore on launch
5. **Optimistic updates:** Add new project/card to list immediately without reloading (with rollback on error)
6. **Filter persistence:** Persist filter/sort state to UserDefaults
7. **Debounced updates:** Add debouncing for updateCard() to reduce write frequency
8. **Search UI:** Wire performSearch to `.searchable()` modifier and display searchResults in UI
