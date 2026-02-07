# ViewModel Layer

## Overview

`HieroglyphsVM` is the single shared ViewModel coordinating workspace state and UI interactions. It acts as the bridge between WorkspaceService (filesystem I/O) and Views (SwiftUI UI). The ViewModel holds transient state (selected project, loaded projects) and delegates all I/O to WorkspaceService.

**Location:** `Sources/Hieroglyphs/HieroglyphsVM.swift`

**Pattern:** MVVM with single shared coordinator

**Annotations:** `@Observable`, `@MainActor`

The ViewModel supports L01 (Filesystem as Source of Truth by delegating to service), L09 (Protocol-Based Services), and follows SwiftUI best practices for observation and main-thread isolation.

## HieroglyphsVM Class

**Purpose:** Coordinate workspace state, project list, and selected project for UI binding.

**State Properties:**
- `workspacePath: String?` — Absolute path to workspace directory (nil if not loaded)
- `projects: [Project]` — Array of loaded projects (empty if not loaded or no projects exist)
- `selectedProject: Project?` — Currently selected project in sidebar (nil if none selected)
- `cards: [Card]` — Array of loaded cards for selected project (empty if not loaded or no cards exist)
- `selectedCard: Card?` — Currently selected card in card list (nil if none selected)
- `searchText: String` — Search query for filtering cards by title
- `filterStatus: Set<CardStatus>` — Active status filters (empty set = show all)
- `filterType: Set<CardType>` — Active type filters (empty set = show all)
- `filterPriority: Set<Priority>` — Active priority filters (empty set = show all)
- `sortBy: CardSortOption` — Sort criteria (created, updated, priority, status, title)
- `sortOrder: SortOrder` — Sort direction (forward = ascending, reverse = descending)

**Service Dependency:**
- `workspaceService: WorkspaceProviding` — Injected service for I/O operations

**Initialization:**
```swift
init(workspaceService: WorkspaceProviding)
```

**Notes:**
- `@Observable` enables SwiftUI automatic view updates when properties change
- `@MainActor` ensures all methods run on main thread (required for UI updates)
- ViewModel is created in `App.swift` and injected via `.environment(viewModel)`

## Methods

### loadWorkspace()

**Signature:** `func loadWorkspace()`

**Purpose:** Load workspace configuration and project list on app launch.

**Behavior:**

1. Call `workspaceService.loadWorkspaceConfig(from: nil)` to load config from `~/.hieroglyphs/config.yaml`
2. Extract `workspacePath` from config
3. Call `workspaceService.loadProjects(from: workspacePath)` to load all projects
4. Update `self.workspacePath` and `self.projects`
5. If any step throws, catch error, log to console, set `workspacePath` to `nil` and `projects` to `[]`

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
5. If any step throws, catch error and log to console

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

### selectProject(_:)

**Signature:** `func selectProject(_ project: Project?)`

**Purpose:** Update selected project state.

**Parameters:**
- `project` — The project to select (nil to deselect)

**Behavior:**

1. Set `self.selectedProject = project`

**Usage:**

Called implicitly via SwiftUI binding in `Sidebar`:

```swift
List(selection: $bindableViewModel.selectedProject) {
    // ...
}
```

SwiftUI automatically calls `selectProject(_:)` when user clicks a project row.

**Notes:**
- This is a simple setter with no side effects
- Selection state is ephemeral (not persisted across app launches)
- Future phases may persist selection to UserDefaults

### loadCards()

**Signature:** `func loadCards()`

**Purpose:** Load cards for the currently selected project.

**Behavior:**

1. Guard check `selectedProject` is not nil (sets cards to empty array and returns if nil)
2. Guard check `workspacePath` is not nil (logs error, sets cards to empty array, and returns if nil)
3. Construct project path from workspace path and selected project slug
4. Call `workspaceService.loadCards(from:for:)` to load all cards
5. Update `self.cards` with loaded cards
6. If any step throws, catch error, log to console, and set `cards` to empty array

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
- Future optimization may add caching or incremental loading

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
6. If any step throws, catch error and log to console

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

## Lifecycle and Initialization

**App.swift:**

```swift
@main
struct HieroglyphsApp: App {
    @State private var viewModel: HieroglyphsVM
    private let workspaceService: WorkspaceProviding

    init() {
        let service = WorkspaceService()
        self.workspaceService = service
        let vm = HieroglyphsVM(workspaceService: service)
        _viewModel = State(initialValue: vm)
    }

    var body: some Scene {
        Window("Hieroglyphs", id: "main") {
            MainWindow()
                .environment(viewModel)
                .environment(\.workspaceService, workspaceService)
                .onAppear {
                    viewModel.loadWorkspace()
                }
        }
    }
}
```

**Dependency Injection:**
1. `WorkspaceService` created as concrete instance
2. `HieroglyphsVM` initialized with `workspaceService` dependency
3. ViewModel injected via `.environment(viewModel)`
4. Service also injected via `.environment(\.workspaceService, workspaceService)` for views that need direct service access (e.g., `SidebarProjectEntry` for loading cards)

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

**Notes:**
- Tests verify coordination logic, not I/O (I/O tested in WorkspaceServiceTests)
- Tests use `@MainActor` to match ViewModel's main-thread isolation

## Future Enhancements

**Planned features not yet implemented:**

1. **Workspace creation UI:** If config does not exist, show onboarding flow to create workspace
2. **Error UI:** Display user-facing error messages instead of console logging
3. **Slug collision detection:** Check for existing projects/cards with same slug before creating
4. **Project editing:** Add `updateProject(_:)` method to ViewModel
5. **Project deletion:** Add `deleteProject(_:)` method to ViewModel
6. **Card editing:** Add `updateCard(_:)` method to ViewModel (Phase 7)
7. **Card deletion:** Add `deleteCard(_:)` method to ViewModel
8. **File watching:** Add `reloadWorkspace()` method triggered by FSEvents
9. **Selection persistence:** Persist selectedProject and selectedCard to UserDefaults and restore on launch
10. **Optimistic updates:** Add new project/card to list immediately without reloading (with rollback on error)
11. **Filter persistence:** Persist filter/sort state to UserDefaults
