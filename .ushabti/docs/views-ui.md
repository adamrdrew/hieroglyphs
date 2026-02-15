# View Layer and UI

## Overview

Hieroglyphs uses SwiftUI to build a three-column NavigationSplitView UI following TakeNote design patterns. The View layer is organized by feature with small, composable, focused components.

**Location:** `Sources/Hieroglyphs/Views/`

**Pattern:** Three-column NavigationSplitView (sidebar, list, detail)

**Current Implementation:** All three columns are complete: Sidebar (project list), CardList (card list with search/filter/sort), and CardDetail (metadata editor + click-to-edit markdown body).

Views follow L10 (Design Language Consistency with TakeNote), L09 (Small, Focused Components), and SwiftUI best practices.

## Directory Structure

```
Sources/Hieroglyphs/Views/
├── MainWindow.swift              # Root three-column NavigationSplitView
├── Welcome/                      # Welcome screen components
│   └── WelcomeView.swift         # First-launch workspace setup
├── Sidebar/                      # Sidebar feature components
│   ├── Sidebar.swift             # Project list with toolbar
│   ├── SidebarProjectEntry.swift # Individual project row
│   └── NewProjectSheet.swift     # Project creation form
├── ProjectOverview/              # ProjectOverview feature components
│   ├── ProjectOverview.swift     # Project configuration form
│   ├── ProjectReadme.swift       # README.md markdown viewer
│   └── CommandExecutionModal.swift # Command execution feedback modal
├── CardList/                     # CardList feature components
│   ├── CardList.swift            # Card list with search, filter, sort
│   ├── CardListEntry.swift       # Individual card row
│   ├── CardFilterBar.swift       # Filter UI for status/type/priority
│   ├── CardSortPopover.swift     # Sort UI for criteria and order
│   └── NewCardSheet.swift        # Card creation form
├── CardDetail/                   # CardDetail feature components
│   ├── CardDetail.swift          # Two-section detail with empty state
├── PhaseList/                    # PhaseList feature components
│   ├── PhaseList.swift           # Middle column phase list with empty states
│   └── PhaseListEntry.swift      # Individual phase row with status badge
├── PhaseDetail/                  # PhaseDetail feature components
│   └── PhaseDetail.swift         # Detail column phase view with intent, steps, review
│   ├── CardMetadataEditor.swift  # Form for card metadata fields
│   └── CardBodyEditor.swift      # Click-to-edit markdown preview/editor
├── MenuBar/                      # Menu bar extra components
│   ├── PharaohMenuBar.swift      # Menu bar extra displaying running plans
│   └── PharaohMenuBarEntry.swift # Individual running plan row
└── Shared/                       # Reusable components
    └── TagChipView.swift         # Pill-shaped tag chip with delete
```

**Organization:** Views are grouped by feature (Welcome, Sidebar, CardList, Detail). Each view is in its own file with focused responsibility.

## WelcomeView

**File:** `Sources/Hieroglyphs/Views/Welcome/WelcomeView.swift`

**Purpose:** First-launch screen for workspace initialization.

**Structure:**

```swift
struct WelcomeView: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.fill.badge.plus")
            Text("Welcome to Hieroglyphs")
            Text("Description...")
            Button { chooseWorkspaceFolder() } label: {
                Label("Choose Workspace Folder", systemImage: "folder")
            }
        }
    }

    private func chooseWorkspaceFolder() {
        let panel = NSOpenPanel()
        // ... configure panel ...
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }
        viewModel.initializeWorkspace(at: url.path)
    }
}
```

**Key Features:**

1. **Icon:** Large folder.fill.badge.plus SF Symbol
2. **Title:** "Welcome to Hieroglyphs" in large title font
3. **Description:** Brief explanation of the app's purpose
4. **Button:** "Choose Workspace Folder" button with folder icon
5. **NSOpenPanel:** macOS native directory picker (AppKit integration)

**Directory Picker Configuration:**
- `canChooseFiles = false` — Only directories selectable
- `canChooseDirectories = true` — Directories enabled
- `allowsMultipleSelection = false` — Single selection only
- `canCreateDirectories = true` — User can create new folders
- Custom message and prompt text

**Behavior:**

1. User clicks "Choose Workspace Folder" button
2. NSOpenPanel presents with directory selection UI
3. User selects or creates a directory and clicks "Choose"
4. `viewModel.initializeWorkspace(at:)` is called with selected path
5. ViewModel creates workspace, generates files, and loads workspace
6. App.swift observes `workspacePath` change and transitions to MainWindow

**Notes:**
- Shown when `viewModel.workspacePath == nil` (conditional rendering in App.swift)
- Uses AppKit's NSOpenPanel for directory selection (no SwiftUI equivalent)
- Minimum frame size ensures comfortable layout (500x400)
- After initialization, view is replaced by MainWindow automatically

## MainWindow

**File:** `Sources/Hieroglyphs/Views/MainWindow.swift`

**Purpose:** Root view with three-column NavigationSplitView scaffold and section-based middle column routing. Manages view lifecycle with `.id()` modifiers to ensure views reset when project changes.

**Structure:**

```swift
struct MainWindow: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            Sidebar()
        } content: {
            middleColumnContent
        } detail: {
            detailColumnContent
        }
        .onChange(of: viewModel.selectedProject) { _, _ in
            viewModel.restartPhasesWatching()
        }
    }

    @ViewBuilder
    private var middleColumnContent: some View {
        Group {
            switch viewModel.selectedSection {
            case .cards:
                CardList()
            case .plans:
                PlanList()
            case .phases:
                PhaseList()
            case .pharaoh(let project):
                PharaohView(project: project)
            case .none:
                ContentUnavailableView(
                    "Select a Project",
                    systemImage: "folder",
                    description: Text("Choose a project section from the sidebar to get started.")
                )
            }
        }
        .id(viewModel.selectedProject?.id)
    }

    @ViewBuilder
    private var detailColumnContent: some View {
        Group {
            switch viewModel.selectedSection {
            case .cards:
                CardDetail()
            case .plans:
                PlanDetail()
            case .phases:
                PhaseDetail()
            case .pharaoh(let project):
                PharaohActivityStreamView(project: project)
            case .none:
                ContentUnavailableView(
                    "Select a Project",
                    systemImage: "folder",
                    description: Text("Choose a project section from the sidebar to get started.")
                )
            }
        }
        .id(viewModel.selectedProject?.id)
    }
}
```

**View Lifecycle Management:**

Both `middleColumnContent` and `detailColumnContent` use `.id(viewModel.selectedProject?.id)` to force SwiftUI to destroy and recreate views when the project changes. This is critical for correct state management:

1. **Cancels Running Tasks:** When the view is destroyed, all `.task` modifiers are automatically cancelled. This prevents stale async operations (like Pharaoh status polling) from continuing after switching projects.
2. **Resets Local State:** All `@State` properties in the views are reset to their initial values. This prevents filter bars, sort popovers, and sheet presentation state from persisting across project switches.
3. **Triggers Fresh Lifecycle:** `onAppear` and `.task` modifiers execute again for the new project context, ensuring data loads correctly.

Combined with `selectSection(_:)` clearing detail selections on project change, the `.id()` modifiers ensure views always reflect the currently selected project's data with no stale state.

**Notes:**
- Three-column layout per L10 (TakeNote consistency)
- Sidebar column displays hierarchical project list with sections (Overview, Cards, Plans, Phases, Pharaoh)
- Middle column switches based on `viewModel.selectedSection` value
  - `.overview` → displays `ProjectOverview` (editable project configuration form)
  - `.cards` → displays `CardList` (searchable, filterable card list)
  - `.plans` → displays `PlanList` (list of plans with linked cards)
  - `.phases` → displays `PhaseList` (list of Ushabti phases)
  - `.pharaoh` → displays `PharaohView` (process management and status)
  - `nil` → displays empty state prompting user to select a section
- Detail column switches based on section type, showing appropriate detail view or empty state
  - `.overview` → displays `ProjectReadme` (README.md markdown viewer)
  - All other sections → displays section-specific detail views
- `preferredCompactColumn` controls which column shows on small windows (defaults to sidebar)
- Shown when `viewModel.workspacePath != nil` (conditional rendering in App.swift)

**App.swift Conditional Rendering:**

```swift
Window("Hieroglyphs", id: "main") {
    Group {
        if viewModel.workspacePath == nil {
            WelcomeView()
        } else {
            MainWindow()
        }
    }
    .environment(viewModel)
    .onAppear {
        viewModel.loadWorkspace()
    }
}
```

**First Launch Flow:**
1. App launches and calls `viewModel.loadWorkspace()` on window appear
2. If config does not exist, `loadWorkspace()` fails and `workspacePath` remains nil
3. Conditional shows `WelcomeView` when `workspacePath == nil`
4. User selects workspace folder in WelcomeView
5. ViewModel initializes workspace and sets `workspacePath`
6. Conditional switches to `MainWindow` when `workspacePath != nil`
7. Workspace is loaded and projects appear in Sidebar

**Menu Commands:**

App.swift defines menu bar commands using `.commands()` modifier:

- **File Menu:**
  - New Project (Cmd+Shift+N) — Calls `viewModel.showNewProjectSheet()`
  - New Card (Cmd+N) — Calls `viewModel.showNewCardSheet()` (disabled when no project selected)
- **Edit Menu:**
  - Delete (Cmd+Delete) — Calls `viewModel.deleteSelectedItem()` (disabled when nothing selected)
  - Find (Cmd+F) — Calls `viewModel.requestSearchFocus()`

**Notes:**
- Commands trigger ViewModel methods that update observable state
- Sheet presentation is coordinated through ViewModel (not local view state)
- Delete and New Card commands are disabled based on selection state

## Sidebar

**File:** `Sources/Hieroglyphs/Views/Sidebar/Sidebar.swift`

**Purpose:** Display hierarchical project list with section selection support, New Project button, and Delete Project button.

**Structure:**

```swift
struct Sidebar: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.workspaceService) private var workspaceService
    @State private var projectPendingDeletion: Project?

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            if viewModel.projects.isEmpty {
                ContentUnavailableView(
                    "No Projects",
                    systemImage: "folder",
                    description: Text("Create a project to get started.")
                )
            } else {
                List(selection: $bindableViewModel.selectedSection) {
                    ForEach(viewModel.projects) { project in
                        if let workspacePath = viewModel.workspacePath {
                            DisclosureGroup {
                                SidebarCardsItem(...)
                                    .tag(SidebarSection.cards(project))
                                Label("Plans", systemImage: "flowchart")
                                    .tag(SidebarSection.plans(project))
                                Label("Phases", systemImage: "list.number")
                                    .tag(SidebarSection.phases(project))
                                if project.sourceDirectory != nil {
                                    SidebarPharaohItem(project: project)
                                }
                            } label: {
                                SidebarProjectEntry(...)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .toolbar {
            if let selectedProject = viewModel.selectedProject {
                ToolbarItem(placement: .automatic) {
                    Button(role: .destructive) {
                        projectPendingDeletion = selectedProject
                    } label: {
                        Label("Delete Project", systemImage: "trash")
                    }
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showNewProjectSheet()
                } label: {
                    Label("New Project", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $bindableViewModel.showingNewProjectSheet) {
            NewProjectSheet()
        }
        .alert(
            "Delete Project",
            isPresented: Binding(
                get: { projectPendingDeletion != nil },
                set: { if !$0 { projectPendingDeletion = nil } }
            ),
            presenting: projectPendingDeletion
        ) { project in
            Button("Cancel", role: .cancel) {
                projectPendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.deleteProject(project)
                projectPendingDeletion = nil
            }
        } message: { project in
            Text("Are you sure you want to delete '\(project.title)'? This will move the project and all its cards to Trash.")
        }
    }
}
```

**Key Features:**

1. **Empty State:** Shows `ContentUnavailableView` when no projects exist
2. **Hierarchical Navigation:** Each project wraps in a `DisclosureGroup` with up to four child sections
3. **List with Selection:** `List(selection:)` binds to `viewModel.selectedSection` for section-based selection
4. **Four Sections Per Project:** Cards (with count), Plans, Phases, and Pharaoh (conditional on `sourceDirectory`)
5. **SidebarCardsItem:** Displays "Cards" with card count summary (on-demand loading)
6. **SidebarProjectEntry:** Disclosure group label showing project icon and title
7. **Toolbar Delete Button:** "Delete Project" button visible only when a project is selected (`.destructive` role, trash icon)
8. **Toolbar New Button:** "New Project" button with SF Symbol `plus` icon
9. **Sheet Presentation:** Shows `NewProjectSheet` modal when New Project button clicked
10. **Delete Confirmation:** Shows alert dialog requiring explicit confirmation before deletion

**Toolbar:**

The toolbar contains two buttons with conditional visibility:

1. **Delete Project Button** (conditional):
   - **Visibility:** Only shown when `viewModel.selectedProject != nil`
   - **Placement:** `.automatic`
   - **Role:** `.destructive` (red button styling)
   - **Icon:** "trash" SF Symbol
   - **Action:** Sets `projectPendingDeletion` to trigger confirmation alert

2. **New Project Button** (always visible):
   - **Placement:** `.primaryAction`
   - **Icon:** "plus" SF Symbol
   - **Action:** Calls `viewModel.showNewProjectSheet()`

**Delete Confirmation Alert:**

- **Title:** "Delete Project"
- **Message:** "Are you sure you want to delete '\(project.title)'? This will move the project and all its cards to Trash."
- **Buttons:**
  - "Cancel" with `.cancel` role (dismisses alert, clears `projectPendingDeletion`)
  - "Delete" with `.destructive` role (calls `viewModel.deleteProject(project)`, clears `projectPendingDeletion`)

**State Variables:**

- `projectPendingDeletion: Project?` — Tracks project awaiting deletion confirmation

**Selection Model:**

Selection is managed via `SidebarSection` enum:
- `.overview(Project)` — Displays project overview in middle column
- `.cards(Project)` — Displays card list in middle column
- `.plans(Project)` — Displays plans list in middle column
- `.phases(Project)` — Displays phases list in middle column
- `.pharaoh(Project)` — Displays Pharaoh controls in middle column (only for projects with `sourceDirectory`)

Each child item is tagged with the appropriate section case for selection tracking.

**Environment Dependencies:**
- `HieroglyphsVM` — For accessing projects, selected section state, and sheet state
- `workspaceService` — Passed to child views for loading data

**Sheet State Management:**
- Sheet presentation is controlled by `viewModel.showingNewProjectSheet` (not local state)
- Button calls `viewModel.showNewProjectSheet()` to trigger sheet
- Enables menu commands (Cmd+Shift+N) to open sheet from anywhere

**Notes:**
- Uses `.sidebar` list style for macOS-native appearance
- `@Bindable` wrapper enables binding to `@Observable` properties
- `.tag(SidebarSection.*)` enables selection tracking by section identity
- Card counts load on-demand when disclosure group is expanded
- Empty state shows when workspace has no projects
- Delete button visibility controlled by selection state (not just disabled) per L18
- Deletion requires explicit confirmation per L18 (Design Is How It Works)
- Delete operation is reversible via macOS Trash per L06 (Platform Leverage)

## SidebarCardsItem

**File:** `Sources/Hieroglyphs/Views/Sidebar/Sidebar.swift` (inline definition)

**Purpose:** Display "Cards" section item with card count summary.

**Structure:**

```swift
struct SidebarCardsItem: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    let project: Project
    let workspacePath: String
    let workspaceService: WorkspaceProviding

    @State private var onAppearCardCounts: [CardStatus: Int] = [:]

    var body: some View {
        HStack {
            Text("Cards")
            if !cardCountSummary.isEmpty {
                Text(cardCountSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { loadCardCounts() }
    }

    private var cardCounts: [CardStatus: Int] {
        // For selected project, derive counts from viewModel.cards (reactive)
        if let selectedProject = viewModel.selectedProject,
           selectedProject.id == project.id {
            var counts: [CardStatus: Int] = [:]
            for card in viewModel.cards {
                counts[card.status, default: 0] += 1
            }
            return counts
        } else {
            // For non-selected projects, use onAppear loaded counts
            return onAppearCardCounts
        }
    }
}
```

**Key Features:**

1. **Card Count Summary:** Displays counts grouped by status (e.g., "3 todo • 2 in progress")
2. **Reactive Updates:** For the selected project, counts derive from `viewModel.cards` and update automatically when cards are added, deleted, or change status
3. **On-Demand Loading:** For non-selected projects, loads cards via workspaceService in `.onAppear`
4. **Formatted Display:** Uses bullet separator, replaces hyphens with spaces in status labels
5. **Status Ordering:** Displays in workflow order (backlog, todo, in-progress, done, archived)

**Reactivity Behavior:**

- **Selected Project:** `cardCounts` is a computed property that derives from `viewModel.cards`. Counts update immediately when cards change.
- **Non-Selected Projects:** Counts are loaded once via `onAppear` and stored in `@State`. They update when the project is next selected.

**Notes:**
- Mirrors the original `SidebarProjectEntry` card counting logic
- Uses hybrid approach: reactive for selected project, lazy-loaded for others
- Prevents loading all cards for all projects eagerly (performance optimization)
- Errors are logged to console; counts remain empty on error

## SidebarProjectEntry

**File:** `Sources/Hieroglyphs/Views/Sidebar/SidebarProjectEntry.swift`

**Purpose:** Display project title and icon as disclosure group label with edit and delete functionality.

**Structure:**

```swift
struct SidebarProjectEntry: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    let project: Project
    let workspacePath: String
    let workspaceService: WorkspaceProviding

    @State private var hasContent = false
    @State private var showingEditSheet = false
    @State private var projectPendingDeletion: Project?

    var body: some View {
        HStack {
            Image(systemName: hasContent ? "folder.fill" : "folder")
                .foregroundStyle(.orange)

            Text(project.title)
                .font(.body)
        }
        .contextMenu {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit Project", systemImage: "pencil.circle")
            }

            Button(role: .destructive) {
                projectPendingDeletion = project
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditProjectSheet(project: project)
        }
        .alert(
            "Delete Project",
            isPresented: Binding(
                get: { projectPendingDeletion != nil },
                set: { if !$0 { projectPendingDeletion = nil } }
            ),
            presenting: projectPendingDeletion
        ) { project in
            Button("Cancel", role: .cancel) {
                projectPendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.deleteProject(project)
                projectPendingDeletion = nil
            }
        } message: { project in
            Text("Are you sure you want to delete '\(project.title)'? This will move the project and all its cards to Trash.")
        }
        .onAppear {
            checkContent()
        }
    }
}
```

**Key Features:**

1. **Icon:** Dynamic folder icon (`folder.fill` when project has content, `folder` when empty) with orange tint
2. **Title:** Project title in body font
3. **Context Menu:** Right-click shows "Edit Project" and "Delete" options
4. **Edit Sheet:** Presents EditProjectSheet when "Edit Project" is clicked
5. **Delete Confirmation:** Shows alert dialog requiring explicit confirmation before deletion
6. **Content Detection:** Checks for cards and plans to determine folder icon variant

**State Variables:**

- `hasContent: Bool` — True if project contains cards or plans (determines folder icon variant)
- `showingEditSheet: Bool` — Controls EditProjectSheet presentation
- `projectPendingDeletion: Project?` — Tracks project awaiting deletion confirmation

**Delete Confirmation Alert:**

- **Title:** "Delete Project"
- **Message:** "Are you sure you want to delete '\(project.title)'? This will move the project and all its cards to Trash."
- **Buttons:**
  - "Cancel" with `.cancel` role (dismisses alert, clears `projectPendingDeletion`)
  - "Delete" with `.destructive` role (calls `viewModel.deleteProject(project)`, clears `projectPendingDeletion`)

**Content Detection:**

The `checkContent()` method determines whether the project has any cards or plans to decide which folder icon to show:

```swift
private func checkContent() {
    let projectPath = "\(workspacePath)/\(project.slug)"
    let cards = try? workspaceService.loadCards(
        from: projectPath,
        for: project
    )
    let hasCards = !(cards ?? []).isEmpty
    let plansPath = "\(projectPath)/plans"
    let hasPlans = FileManager.default
        .fileExists(atPath: plansPath)
        && (try? FileManager.default
            .contentsOfDirectory(atPath: plansPath))?.isEmpty == false
    hasContent = hasCards || hasPlans
}
```

**Behavior:**
1. On appear, check if project contains cards or plans
2. Update `hasContent` state to control folder icon variant
3. Context menu provides Edit and Delete actions
4. Delete action sets `projectPendingDeletion` to show confirmation alert
5. Alert confirmation calls `viewModel.deleteProject(project)` to move project to Trash
6. Alert cancellation clears `projectPendingDeletion` without action

**Notes:**
- Serves as label for `DisclosureGroup` in sidebar
- Folder icon changes based on content (filled when project has cards or plans, outline when empty)
- Deletion requires explicit confirmation (L18: Design Is How It Works)
- Uses `.destructive` role for delete button (red text) and alert button
- Delete operation is reversible via macOS Trash (L06: Platform Leverage)

**Card Count Summary Formatting:**

```swift
private var cardCountSummary: String {
    let nonZeroCounts = cardCounts
        .filter { $0.value > 0 }
        .sorted { first, second in
            statusOrder(first.key) < statusOrder(second.key)
        }

    return nonZeroCounts
        .map { status, count in
            let label = formatStatusLabel(status)
            return "\(count) \(label)"
        }
        .joined(separator: " • ")
}
```

**Behavior:**
1. Filter out statuses with zero counts
2. Sort by status order (backlog, todo, in-progress, done, archived)
3. Format each status as "N status" (e.g., "3 todo")
4. Replace hyphens with spaces in status labels (e.g., "in-progress" → "in progress")
5. Join with bullet separator " • "

**Example outputs:**
- `"3 todo • 2 in progress • 1 done"`
- `"5 backlog"`
- `""` (empty if no cards)

**Context Menu:**

```swift
.contextMenu {
    Button {
        showingEditSheet = true
    } label: {
        Label("Edit Project", systemImage: "pencil.circle")
    }
}
.sheet(isPresented: $showingEditSheet) {
    EditProjectSheet(project: project)
}
```

**Notes:**
- Card counts are loaded on-demand per project (inefficient but simple; future optimization may cache in ViewModel)
- Counts are stored in `@State` and recomputed on every `.onAppear`
- Errors are logged to console; counts remain empty on error
- Right-click context menu provides access to project editing

## EditProjectSheet

**File:** `Sources/Hieroglyphs/Views/Sidebar/EditProjectSheet.swift`

**Purpose:** Modal sheet for editing an existing project.

**Structure:**

```swift
struct EditProjectSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let project: Project

    @State private var title = ""
    @State private var description = ""
    @State private var tags = ""
    @State private var sourceDirectory: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") { /* ... */ }
                Section("Tags") { /* ... */ }
                Section("Source Directory") { /* ... */ }
            }
            .navigationTitle("Edit Project")
            .toolbar { /* Cancel and Save buttons */ }
            .onAppear {
                populateFields()
            }
        }
    }
}
```

**Key Features:**

1. **Pre-populated Fields:** All fields populated from project on appear
2. **Title Field:** Required text field (Save button disabled if empty)
3. **Description Field:** Multi-line text field with vertical axis and line limits
4. **Tags Field:** Comma-separated text field for tag input
5. **Source Directory:** NSOpenPanel-based directory picker with Clear button
6. **Cancel Button:** Dismisses sheet without saving
7. **Save Button:** Calls `viewModel.updateProject()` and dismisses (disabled if title is empty)

**Source Directory Picker:**

```swift
Section("Source Directory") {
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            if let sourceDirectory = sourceDirectory {
                Text(sourceDirectory)
                    .font(.caption)
                    .lineLimit(2)
                    .truncationMode(.middle)
            } else {
                Text("None")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        Spacer()
        if sourceDirectory != nil {
            Button("Clear") {
                self.sourceDirectory = nil
            }
            .buttonStyle(.borderless)
        }
        Button("Select Folder...") {
            selectSourceDirectory()
        }
        .buttonStyle(.borderedProminent)
    }
}
```

**Directory Selection:**

- Uses NSOpenPanel for native macOS directory picker
- `canChooseFiles = false` — Only directories selectable
- `canChooseDirectories = true` — Directories enabled
- `allowsMultipleSelection = false` — Single selection only
- `canCreateDirectories = true` — User can create new folders in picker

**Save Logic:**

```swift
private func saveProject() {
    let parsedTags = tags
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }

    let updatedProject = Project(
        id: project.id,
        title: title,
        description: description,
        tags: parsedTags,
        created: project.created,
        updated: Date(),
        slug: project.slug,
        sourceDirectory: sourceDirectory
    )

    viewModel.updateProject(updatedProject)
    dismiss()
}
```

**Behavior:**
1. Parse tags by splitting on comma, trimming whitespace, and filtering empty strings
2. Create updated Project instance with edited values (preserves id, created, slug)
3. Call `viewModel.updateProject()` to persist changes
4. Dismiss sheet (ViewModel handles project list refresh and selection update)

**Notes:**
- Mirrors NewProjectSheet structure for consistency
- Pre-populates all fields including sourceDirectory
- Allows adding, changing, or removing source directory
- No slug editing (slug is immutable)
- No error UI (errors logged to console by ViewModel)

## ProjectOverview

**File:** `Sources/Hieroglyphs/Views/ProjectOverview/ProjectOverview.swift`

**Purpose:** Middle-column view displaying editable project configuration when the overview section is selected.

**Design (macOS 26 compliant):**
- Semantic typography throughout (headline headers, body content, caption metadata)
- Grouped form style for clean sectioned layout
- Progressive disclosure: command toolbar buttons visible only when commands configured
- Disabled states: toolbar buttons disabled when no source directory
- Automatic Liquid Glass treatment on toolbar

**Structure:**

```swift
struct ProjectOverview: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    let project: Project

    @State private var title = ""
    @State private var description = ""
    @State private var tags = ""
    @State private var sourceDirectory: String?
    @State private var buildCommand = ""
    @State private var runCommand = ""
    @State private var publishCommand = ""
    @State private var gitBranch: String?
    @State private var executingCommand: CommandType?

    var body: some View {
        Form {
            Section("Project Details") { /* ... */ }
            Section("Source Directory") { /* ... */ }
            Section("Build Commands") { /* ... */ }
            Section("Git Info") { /* ... */ }
        }
        .formStyle(.grouped)
        .navigationTitle(project.title)
        .toolbar {
            if !buildCommand.isEmpty {
                ToolbarItem(placement: .automatic) {
                    Button { executingCommand = .build } label: {
                        Label("Build", systemImage: "hammer")
                    }
                    .disabled(sourceDirectory == nil)
                }
            }
            // Similar for runCommand and publishCommand
        }
        .sheet(item: $executingCommand) { commandType in
            CommandExecutionModal(/* ... */)
        }
        .onAppear {
            populateFields()
            if let sourceDirectory = sourceDirectory {
                readGitBranch(from: sourceDirectory)
            }
        }
    }
}
```

**Key Features:**

1. **Project Details Section:**
   - Title: TextField with immediate save on change
   - Description: Multi-line TextField with vertical axis and line limits
   - Tags: Comma-separated TextField
   - All fields save via `viewModel.updateProject()` on change

2. **Source Directory Section:**
   - Display: Shows current path or "None" placeholder
   - Select Folder button: NSOpenPanel-based directory picker
   - Clear button: Removes source directory (visible only when path is set)

3. **Build Commands Section:**
   - Three TextFields: buildCommand, runCommand, publishCommand
   - All fields optional (empty strings mean no command configured)
   - Save immediately on change

4. **Git Info Section:**
   - Current Branch: Read-only text field showing git branch name
   - Reads `.git/HEAD` from source directory
   - Parses `ref: refs/heads/{branch}` format (no regex)
   - Shows "Unknown" if `.git/HEAD` missing or unparseable
   - Updates when source directory changes

5. **Toolbar Command Buttons:**
   - **Build button** (hammer icon): Visible only when buildCommand is non-empty, disabled when no source directory
   - **Run button** (play.fill icon): Visible only when runCommand is non-empty, disabled when no source directory
   - **Publish button** (arrow.up.doc icon): Visible only when publishCommand is non-empty, disabled when no source directory
   - Each button sets `executingCommand` state to trigger modal

6. **Command Execution Modal:**
   - Presented via `.sheet(item: $executingCommand)`
   - Passes command string, source directory, and command title
   - Modal handles execution, progress indication, and result display

**Progressive Disclosure Pattern:**

Commands are hidden by default and revealed only when configured:
- New projects have no commands configured, so no toolbar buttons appear
- User fills in buildCommand field → Build button appears in toolbar
- User clears buildCommand field → Build button disappears from toolbar
- Buttons disabled (not hidden) when source directory is missing

**Git Branch Detection:**

```swift
private func readGitBranch(from sourceDirectory: String) {
    let gitHeadPath = "\(sourceDirectory)/.git/HEAD"
    guard let headContent = try? String(contentsOfFile: gitHeadPath) else {
        gitBranch = nil
        return
    }

    let trimmed = headContent.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.hasPrefix("ref: refs/heads/") {
        gitBranch = String(trimmed.dropFirst("ref: refs/heads/".count))
    } else {
        gitBranch = nil
    }
}
```

**Save Logic:**

All fields save immediately on change (no explicit Save button). Each field binding calls `saveProject()` which:
1. Parses tags by splitting on comma, trimming whitespace, filtering empty strings
2. Creates updated Project instance with new values
3. Calls `viewModel.updateProject(updatedProject)`
4. ViewModel persists changes to disk and refreshes project list

**Notes:**
- Displayed when `.overview(project)` section is selected
- Follows NewProjectSheet form layout patterns
- Uses NSOpenPanel for directory selection (AppKit integration)
- Git branch detection uses string operations only (no regex per L09)
- All fields optional except title (inherited from project, always has value)
- Command fields persist to frontmatter only when non-empty (L02 compliance)
- Toolbar buttons follow L18 progressive disclosure and disabled state patterns
- Form auto-saves on every change (no explicit Save button)

## ProjectReadme

**File:** `Sources/Hieroglyphs/Views/ProjectOverview/ProjectReadme.swift`

**Purpose:** Detail-column view displaying README.md content from project's source directory.

**Structure:**

```swift
struct ProjectReadme: View {
    let project: Project

    @State private var readmeContent = ""
    @State private var readmeExists = false

    var body: some View {
        Group {
            if let sourceDirectory = project.sourceDirectory, readmeExists {
                ScrollView {
                    Markdown(readmeContent)
                        .padding()
                }
            } else {
                ContentUnavailableView(
                    "No README",
                    systemImage: "doc.text",
                    description: Text(emptyStateMessage)
                )
            }
        }
        .navigationTitle("README")
        .onAppear {
            loadReadme()
        }
    }
}
```

**Key Features:**

1. **Markdown Rendering:**
   - Uses swift-markdown-ui `Markdown()` component
   - Renders headings, lists, code blocks, links, emphasis
   - Same rendering as CardBodyEditor preview mode
   - ScrollView for long content

2. **Empty States:**
   - **No Source Directory:** "Configure a source directory to view the project README"
   - **README Not Found:** "README.md not found in source directory"
   - Uses `ContentUnavailableView` with doc.text icon

3. **File Loading:**
   - Reads from `{sourceDirectory}/README.md` on appear
   - Sets `readmeExists = false` if file missing or unreadable
   - Sets `readmeContent` to file contents on success
   - Errors logged to console, user sees empty state

**Behavior:**

- When user selects overview section, ProjectReadme displays in detail column
- On appear, attempts to read README.md from source directory
- If file exists and is readable, renders markdown content
- If file missing or source directory not configured, shows appropriate empty state
- Read-only view (no editing)

**Notes:**
- Displayed when `.overview(project)` section is selected
- Follows CardBodyEditor preview mode layout (ScrollView + Markdown)
- No error alerts (failures show as empty state)
- Assumes markdown format (no HTML or other formats supported)
- File read happens on every appear (no caching)

## CommandExecutionModal

**File:** `Sources/Hieroglyphs/Views/ProjectOverview/CommandExecutionModal.swift`

**Purpose:** Modal sheet for executing shell commands with progress indication and result feedback.

**Design (macOS 26 compliant):**
- Constrained dimensions (600x400) with scrollable output
- Three-state UI: running, success, failure
- Progress indication during execution
- Clear visual feedback with color-coded icons
- Cannot dismiss while running (no close button during execution)
- Automatic Liquid Glass treatment on toolbar

**Structure:**

```swift
struct CommandExecutionModal: View {
    @Binding var isPresented: Bool
    @Environment(\.commandExecutionService) private var commandExecutionService

    let command: String
    let workingDirectory: String
    let title: String

    @State private var state: ExecutionState = .running

    enum ExecutionState {
        case running
        case success(output: String)
        case failure(error: String)
    }

    var body: some View {
        VStack(spacing: 20) {
            switch state {
            case .running:
                ProgressView()
                Text("Executing...")
                    .font(.headline)
            case .success(let output):
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("\(title) Complete")
                    .font(.headline)
                ScrollView {
                    Text(output)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Button("Done") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            case .failure(let error):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                Text("Failed")
                    .font(.headline)
                ScrollView {
                    Text(error)
                        .font(.caption.monospaced())
                        .foregroundStyle(.red)
                }
                Button("Close") {
                    isPresented = false
                }
            }
        }
        .frame(width: 600, height: 400)
        .padding()
        .task {
            await executeCommand()
        }
    }
}
```

**Key Features:**

1. **Running State:**
   - ProgressView (spinning indicator)
   - "Executing..." message
   - No close button (modal cannot be dismissed)
   - Command runs asynchronously via `.task` modifier

2. **Success State:**
   - Green checkmark icon (checkmark.circle.fill)
   - "{Title} Complete" message (e.g., "Build Complete")
   - ScrollView with command output (monospaced caption font, secondary color)
   - "Done" button (bordered prominent) dismisses modal

3. **Failure State:**
   - Red exclamation triangle icon (exclamationmark.triangle.fill)
   - "Failed" message
   - ScrollView with error output (monospaced caption font, red color)
   - "Close" button dismisses modal

**Execution Logic:**

```swift
private func executeCommand() async {
    do {
        let result = try await commandExecutionService.executeCommand(
            command: command,
            workingDirectory: workingDirectory
        )
        state = .success(output: result.output)
    } catch {
        state = .failure(error: error.localizedDescription)
    }
}
```

**Modal Sizing:**

- Fixed 600x400 frame prevents unbounded growth
- Output ScrollView allows long output to scroll
- Modal container stays fixed size

**Dismissal Behavior:**

- **Running:** Cannot dismiss (no close button, no tap outside to dismiss)
- **Success:** Dismiss via "Done" button
- **Failure:** Dismiss via "Close" button
- Escape key works in success/failure states (system behavior)

**Notes:**
- Follows L17 (UI State Correctness): Constrained modal, async feedback
- Follows L18 (Design Is How It Works): Loading states, success/error surfaces, disabled/hidden controls
- Presented via `.sheet(item:)` binding to `executingCommand` in ProjectOverview
- Command execution uses CommandExecutionService via environment injection
- Output display is read-only (no copying or exporting UI, but user can select text)
- Monospaced font for output preserves formatting (important for compiler output, logs)

## NewProjectSheet

**File:** `Sources/Hieroglyphs/Views/Sidebar/NewProjectSheet.swift`

**Purpose:** Modal sheet for creating a new project.

**Design (macOS 26 compliant):**
- Constrained dimensions (500x450) with scrollable content
- Semantic typography (headline headers, body content, caption metadata)
- Consistent spacing using 8pt scale
- Clear visual hierarchy (primary fields prominent, directory picker secondary)
- Automatic Liquid Glass treatment on toolbar

**Structure:**

```swift
struct NewProjectSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var tags = ""
    @State private var sourceDirectory: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                Form {
                    Section {
                        TextField("Title", text: $title)
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                    } header: {
                        Text("Project Details")
                            .font(.headline)
                    }

                    Section {
                        TextField("Comma-separated tags", text: $tags)
                    } header: {
                        Text("Tags")
                            .font(.headline)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            if let sourceDirectory = sourceDirectory {
                                Text(sourceDirectory)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                            } else {
                                Text("None")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            HStack(spacing: 8) {
                                if sourceDirectory != nil {
                                    Button("Clear") {
                                        self.sourceDirectory = nil
                                    }
                                    .buttonStyle(.borderless)
                                }

                                Button("Select Folder...") {
                                    selectSourceDirectory()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    } header: {
                        Text("Source Directory")
                            .font(.headline)
                    }
                }
                .formStyle(.grouped)
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProject()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 450)
    }

    // ... saveProject method
}
```

**Key Features:**

1. **NavigationStack:** Wraps ScrollView and Form to provide navigation bar and toolbar
2. **Constrained Frame:** Fixed 500x450 dimensions prevent unbounded growth
3. **ScrollView:** Allows content to scroll within constrained frame
4. **Form Sections:** Grouped input fields with semantic typography in headers
5. **Title Field:** Required text field (Save button disabled if empty)
6. **Description Field:** Multi-line text field with vertical axis and line limits
7. **Tags Field:** Comma-separated text field for tag input
8. **Source Directory:** NSOpenPanel-based directory picker with Clear button (optional)
9. **Cancel Button:** Dismisses sheet without saving
10. **Save Button:** Calls `saveProject()` and dismisses (disabled if title is empty)

**Visual Design:**
- Section headers use `.headline` font for clear hierarchy
- Directory path text uses `.caption` font with `.secondary` foreground style
- Empty state shows "None" in `.tertiary` color
- Consistent 8pt spacing between directory display and button controls
- Buttons use standard styles (`.borderless` for secondary, `.borderedProminent` for primary action)

**Save Logic:**

```swift
private func saveProject() {
    let parsedTags = tags
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }

    viewModel.createProject(
        title: title,
        description: description,
        tags: parsedTags,
        sourceDirectory: sourceDirectory
    )

    dismiss()
}
```

**Directory Selection:**

```swift
private func selectSourceDirectory() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = true
    panel.message = "Select the source directory for this project"
    panel.prompt = "Select"

    let response = panel.runModal()
    if response == .OK, let url = panel.url {
        sourceDirectory = url.path
    }
}
```

**Behavior:**
1. Parse tags by splitting on comma, trimming whitespace, and filtering empty strings
2. Call `viewModel.createProject()` with parsed inputs including optional sourceDirectory
3. Dismiss sheet (ViewModel handles project creation and list refresh)

**Notes:**
- Follows L17 (UI State Correctness): Constrained modal with scrollable content
- Follows L18 (Design Is How It Works): Platform-native appearance, semantic typography, system controls
- No error UI (errors logged to console by ViewModel)
- No slug collision detection (future enhancement)
- Tags are simple comma-separated strings (future: tag picker UI)
- Source directory is optional (omitted from frontmatter if nil)
- Automatic Liquid Glass treatment on toolbar (no custom overrides)

## CardList

**File:** `Sources/Hieroglyphs/Views/CardList/CardList.swift`

**Purpose:** Display filtered, sorted, searchable card list for selected project.

**Structure:**

```swift
struct CardList: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @State private var showingNewCardSheet = false
    @State private var cardPendingDeletion: Card?

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            if viewModel.selectedProject == nil {
                emptyProjectState
            } else if viewModel.cards.isEmpty {
                emptyCardsState
            } else {
                List(selection: $bindableViewModel.selectedCard) {
                    ForEach(filteredAndSortedCards) { card in
                        CardListEntry(card: card)
                            .tag(card)
                            .contextMenu {
                                Button(role: .destructive) {
                                    cardPendingDeletion = card
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $bindableViewModel.searchText)
            }
        }
        .onChange(of: viewModel.selectedProject) { _, _ in
            viewModel.loadCards()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewCardSheet = true } label: {
                    Label("New Card", systemImage: "plus")
                }
                .disabled(viewModel.selectedProject == nil)
            }
        }
        .sheet(isPresented: $showingNewCardSheet) {
            NewCardSheet()
        }
        .alert(
            "Delete Card",
            isPresented: Binding(
                get: { cardPendingDeletion != nil },
                set: { if !$0 { cardPendingDeletion = nil } }
            ),
            presenting: cardPendingDeletion
        ) { card in
            Button("Cancel", role: .cancel) {
                cardPendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.selectedCard = card
                viewModel.deleteSelectedItem()
                cardPendingDeletion = nil
            }
        } message: { card in
            Text("Are you sure you want to delete '\(card.title)'? This will move the card to Trash.")
        }
    }
}
```

**Key Features:**

1. **Empty States:** Shows appropriate message when no project selected or no cards exist
2. **List with Selection:** Binds to `viewModel.selectedCard` for card selection
3. **Context Menu:** Right-click card to show "Delete" option (destructive role, trash icon)
4. **Confirmation Alert:** Deleting a card requires confirmation with card title in message
5. **Search:** `.searchable()` modifier filters cards by title (case-insensitive substring match)
6. **Filtering and Sorting:** Computed property `filteredAndSortedCards` applies all filters and sort criteria
7. **Filter Bar:** Toolbar button toggles inline `CardFilterBar` with visual indicator for active filters
8. **Sort Popover:** Toolbar button presents `CardSortPopover` as popover anchored to button
9. **Auto-Load:** `.onChange` modifier calls `loadCards()` when selected project changes
10. **Search Focus:** Menu command (Cmd+F) can focus search field via ViewModel state
11. **Toolbar Buttons:** "New Card", "Filter", and "Sort" buttons in toolbar
12. **Sheet Presentation:** Bound to ViewModel state (enables menu commands)

**Toolbar:**

- **Hide Done/Archived Toggle:** Toggles visibility of done and archived cards. Icon switches between `eye` (showing all) and `eye.slash` (hiding done/archived). State is ephemeral (not persisted across sessions). Default: off (hides done/archived).
- **Filter Button:** Toggles visibility of `CardFilterBar` inline below toolbar. Icon changes to filled variant when filters are active.
- **Sort Button:** Opens `CardSortPopover` as popover for selecting sort criteria and order.
- **New Card Button:** Opens `NewCardSheet` (disabled when no project selected).

**Filter and Sort Logic:**

Filters are applied in sequence:
1. Search text filter (title contains substring)
2. Status filter (if filterStatus is not empty)
3. Type filter (if filterType is not empty)
4. Priority filter (if filterPriority is not empty)
5. Done/archived filter (if showDoneAndArchived is false)
6. Sort by selected criteria and order

**Empty States:**

- **No Project Selected:** `ContentUnavailableView` with folder icon
- **No Cards:** `ContentUnavailableView` with note.text icon
- **Loading:** `ProgressView` with "Loading cards..." message (shown while `isLoadingCards` is true)

**Layout Fix:**

The Group containing empty states and the List has `.frame(maxHeight: .infinity)` to ensure it fills available vertical space. This prevents the filter bar from expanding when the card list is empty, keeping filter bar height consistent whether the list is populated or empty.

**Deletion Flow:**

1. User right-clicks card in list
2. Context menu shows "Delete" option with trash icon (destructive role, red color)
3. User selects "Delete"
4. Alert presents with title "Delete Card" and confirmation message including card title
5. User can cancel or confirm deletion
6. On confirm:
   - Card is set as `selectedCard`
   - `deleteSelectedItem()` is called on ViewModel
   - ViewModel cleans up plan symlinks before trashing card
   - Card list refreshes automatically
7. Alert dismisses

**Notes:**
- Uses `.plain` list style for clean appearance
- Toolbar button placement follows TakeNote patterns
- Empty states use `ContentUnavailableView` (macOS 14+)
- Context menu uses `.destructive` role for delete action (renders red)
- Alert uses two-way binding with `cardPendingDeletion` state

## CardListEntry

**File:** `Sources/Hieroglyphs/Views/CardList/CardListEntry.swift`

**Purpose:** Individual card row showing title, type badge, priority indicator, and status with context menu for quick actions.

**Structure:**

```swift
struct CardListEntry: View {
    let card: Card

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: typeIcon)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.body)

                HStack(spacing: 8) {
                    Text(statusLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if priorityIndicatorIcon != nil {
                        Image(systemName: priorityIndicatorIcon!)
                            .font(.caption)
                            .foregroundStyle(priorityColor)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                viewModel.showNewPlanSheetFromCard(card)
            } label: {
                Label("Create Plan", systemImage: "flowchart")
            }
        }
    }
}
```

**Context Menu Actions:**

- **Create Plan:** Opens NewPlanSheet modal with source card pre-linked. User can edit plan title before saving. Plan is created with card already linked when user confirms.

**Visual Elements:**

1. **Type Icon (left):**
   - `checkmark.circle` for task
   - `ladybug` for bug
   - `star` for feature
   - `note.text` for note

2. **Title and Metadata (center):**
   - Title in `.body` font
   - Status label in `.caption` font (e.g., "todo", "in progress")
   - Priority indicator icon only shown for high/critical priority

3. **Priority Indicator (inline with status):**
   - `exclamationmark.circle.fill` for critical (red) and high (orange)
   - No icon for medium/low priority

**Layout:**
- HStack with 12pt spacing
- VStack for title and metadata with 4pt spacing
- Vertical padding of 4pt for comfortable row height
- Follows TakeNote's NoteListEntry pattern

## CardFilterBar

**File:** `Sources/Hieroglyphs/Views/CardList/CardFilterBar.swift`

**Purpose:** Filter UI for filtering cards by status, type, and priority.

**Structure:**

```swift
struct CardFilterBar: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        HStack(spacing: 12) {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .foregroundStyle(.secondary)

            Menu { /* Status toggles */ } label: {
                filterLabel(title: "Status", count: viewModel.filterStatus.count)
            }

            Menu { /* Type toggles */ } label: {
                filterLabel(title: "Type", count: viewModel.filterType.count)
            }

            Menu { /* Priority toggles */ } label: {
                filterLabel(title: "Priority", count: viewModel.filterPriority.count)
            }

            if activeFilterCount > 0 {
                Button("Clear") { clearAllFilters() }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
```

**Key Features:**

1. **Multi-Select Menus:** Each menu contains toggles for all enum cases
2. **Active Filter Count:** Badge shows number of active filters for each category
3. **Clear Button:** Appears when any filter is active, clears all filters
4. **Filter Icon:** SF Symbol `line.horizontal.3.decrease.circle`

**Filter State:**
- Filters bind to ViewModel state (filterStatus, filterType, filterPriority)
- Empty set means "show all" (no filter applied)
- Non-empty set means "show only cards matching set"
- Filter state is ephemeral (not persisted across app launches)

## CardSortPopover

**File:** `Sources/Hieroglyphs/Views/CardList/CardSortPopover.swift`

**Purpose:** Sort UI for sorting cards by various criteria.

**Structure:**

```swift
struct CardSortPopover: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        VStack(alignment: .leading, spacing: 12) {
            Text("Sort By")
                .font(.headline)

            Picker("Sort By", selection: $bindableViewModel.sortBy) {
                ForEach(CardSortOption.allCases, id: \.self) { option in
                    Text(formatSortLabel(option)).tag(option)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()

            Divider()

            Picker("Order", selection: $bindableViewModel.sortOrder) {
                Label("Ascending", systemImage: "arrow.up").tag(SortOrder.forward)
                Label("Descending", systemImage: "arrow.down").tag(SortOrder.reverse)
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
        .padding()
        .frame(width: 200)
    }
}
```

**Key Features:**

1. **Sort Criteria Picker:** All CardSortOption cases (created, updated, priority, status, title)
2. **Sort Order Picker:** Ascending (forward) or descending (reverse)
3. **Inline Pickers:** Clean, compact presentation
4. **Arrow Icons:** Visual indicators for sort direction

**Sort Options:**
- **Date Created:** Sort by card.created timestamp
- **Date Updated:** Sort by card.updated timestamp
- **Priority:** Sort by priority order (critical > high > medium > low)
- **Status:** Sort by status order (backlog > todo > in-progress > done > archived)
- **Title:** Sort alphabetically by card title

**Notes:**
- Follows TakeNote's NoteSortPopover pattern
- Fixed width (200pt) for consistent popover size
- Binds to ViewModel sort state
- Sort state is ephemeral (not persisted across app launches)

## NewCardSheet

**File:** `Sources/Hieroglyphs/Views/CardList/NewCardSheet.swift`

**Purpose:** Modal sheet for creating a new card.

**Design (macOS 26 compliant):**
- Constrained dimensions (500x600) with scrollable content
- Semantic typography throughout (headline headers, body content)
- Consistent spacing using 8pt scale
- Clear visual hierarchy (title primary, pickers secondary, body tertiary)
- Body TextEditor constrained within scrollable area for multi-line content
- Automatic Liquid Glass treatment on toolbar

**Structure:**

```swift
struct NewCardSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var cardBody = ""
    @State private var tags = ""
    @State private var type: CardType = .task
    @State private var status: CardStatus = .todo
    @State private var priority: Priority = .medium

    var body: some View {
        NavigationStack {
            ScrollView {
                Form {
                    Section {
                        TextField("Title", text: $title)
                        Picker("Type", selection: $type) { /* ... */ }
                        Picker("Status", selection: $status) { /* ... */ }
                        Picker("Priority", selection: $priority) { /* ... */ }
                    } header: {
                        Text("Card Details")
                            .font(.headline)
                    }

                    Section {
                        TextField("Comma-separated tags", text: $tags)
                    } header: {
                        Text("Tags")
                            .font(.headline)
                    }

                    Section {
                        TextEditor(text: $cardBody)
                            .frame(minHeight: 120, maxHeight: 240)
                            .font(.body)
                    } header: {
                        Text("Body")
                            .font(.headline)
                    }
                }
                .formStyle(.grouped)
            }
            .navigationTitle("New Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCard() }
                        .disabled(title.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 600)
    }
}
```

**Key Features:**

1. **NavigationStack:** Wraps ScrollView and Form to provide navigation bar and toolbar
2. **Constrained Frame:** Fixed 500x600 dimensions prevent unbounded growth
3. **ScrollView:** Allows content to scroll within constrained frame
4. **Form Sections:** Grouped input fields with semantic typography in headers
5. **Title Field:** Required (Save button disabled if empty)
6. **Type/Status/Priority Pickers:** All enum cases available with menu picker style
7. **Tags Field:** Comma-separated text input
8. **Body TextEditor:** Multi-line markdown input with constrained height (120-240pt)
9. **Cancel/Save Toolbar:** Standard sheet controls
10. **Default Values:** task, todo, medium

**Visual Design:**
- Section headers use `.headline` font for clear hierarchy
- TextEditor uses `.body` font for consistency with card display
- TextEditor height constrained to 120-240pt range to prevent unbounded growth
- Outer modal frame ensures content scrolls rather than modal expanding
- Standard button styles and toolbar placements

**Save Logic:**
1. Parse tags by splitting on comma, trimming whitespace, filtering empty strings
2. Call `viewModel.createCard()` with parsed inputs
3. Dismiss sheet (ViewModel handles card creation and list refresh)

**Modal Sizing:**
- Outer modal frame: Fixed 500x600 dimensions
- Body TextEditor: `minHeight: 120, maxHeight: 240` (scrollable when content exceeds height)
- TextEditor scrolls internally when content exceeds maxHeight
- Modal container stays fixed size — content scrolls instead of growing unboundedly

**Notes:**
- Follows L17 (UI State Correctness): Constrained modal with scrollable content
- Follows L18 (Design Is How It Works): Platform-native appearance, semantic typography, system controls
- Follows NewProjectSheet patterns for consistency
- No error UI (errors logged by ViewModel)
- TextEditor constraint prevents modal from growing infinitely when typing long body content
- Automatic Liquid Glass treatment on toolbar (no custom overrides)

## TakeNote Design Patterns

Hieroglyphs follows these TakeNote design patterns per L10:

1. **Three-Column NavigationSplitView:** Sidebar | List | Detail
2. **Sidebar List with Selection:** `List(selection:)` binds to ViewModel state
3. **SF Symbols for Icons:** `folder.fill`, `plus`, type icons, priority indicators
4. **Click-to-Edit Pattern:** ZStack with Markdown preview and CodeEditor. Tap to edit, Escape to preview.
5. **Toolbar Buttons:** Primary actions in toolbar (e.g., New Project, New Card)
6. **Sheet Presentation:** Modal forms for creation workflows
7. **Form-Based Input:** Sectioned forms with TextField and labeled inputs
8. **Empty States:** ContentUnavailableView with icon and description text

**Visual Consistency:**

- Font sizes: `.body`, `.caption`
- Colors: `.secondary` for supporting text and icons
- Spacing: Consistent use of `VStack(alignment:spacing:)` and `HStack`
- Layout: Leading-aligned text, icon-text pairs

## Empty States

Empty states use `ContentUnavailableView` (macOS 14+) throughout:

- **CardList (no project selected):** "Select a Project" with `folder` icon
- **CardList (no cards):** "No Cards" with `note.text` icon
- **CardDetail (no card selected):** "No Card Selected" with `note.text` icon

## CardDetail

**File:** `Sources/Hieroglyphs/Views/CardDetail/CardDetail.swift`

**Purpose:** Display and edit selected card metadata and markdown body in the detail column with toolbar actions.

**Structure:**

```swift
struct CardDetail: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @State private var editableCard: Card?

    var body: some View {
        Group {
            if let editableCard {
                VStack(spacing: 0) {
                    CardMetadataEditor(card: editableCardBinding, onUpdate: saveCard)
                        .frame(height: 300)
                    Divider()
                    CardBodyEditor(content: bodyBinding, onUpdate: { saveCard(debounced: true) })
                }
                .navigationTitle(editableCard.title)
            } else {
                ContentUnavailableView(
                    "No Card Selected",
                    systemImage: "note.text",
                    description: Text("Select a card from the list to view and edit it.")
                )
            }
        }
        .toolbar {
            if viewModel.selectedProject != nil {
                ToolbarItem(placement: .automatic) {
                    Button {
                        if let card = viewModel.selectedCard {
                            viewModel.createPlanFromCard(card)
                        }
                    } label: {
                        Label("Create Plan", systemImage: "flowchart")
                    }
                    .disabled(viewModel.selectedCard == nil)
                    .help("Create a new plan from this card")
                }
            }
        }
        .onChange(of: viewModel.selectedCard) { _, newCard in
            viewModel.flushPendingCardUpdates()
            editableCard = newCard
        }
    }
}
```

**Key Features:**

1. **Empty State:** Shows `ContentUnavailableView` when `selectedCard` is nil
2. **Two-Section Layout:** CardMetadataEditor (fixed 300pt height) at top, CardBodyEditor (fills remaining space) below
3. **Local Edit State:** `editableCard` syncs with `viewModel.selectedCard` but allows local edits before saving
4. **Dual Save Paths:** Debounced saves for continuous typing (title, body), immediate saves for discrete actions (pickers, tags)
5. **Flush on Deselection:** Pending writes flushed before loading new card
6. **Navigation Title:** Shows card title in detail column navigation bar
7. **Create Plan Toolbar Button:** Flowchart icon button (disabled when no card selected, hidden when no project selected) calls `viewModel.showNewPlanSheetFromCard(card)` to open NewPlanSheet modal with card pre-linked

**Behavior:**

- When user selects a card in CardList, `editableCard` is set from `viewModel.selectedCard`
- Pending debounced writes are flushed before loading new card
- User edits metadata fields or markdown body
- Title and body edits trigger `saveCard(debounced: true)` for debounced writes (1.5s delay)
- Picker and tag edits trigger `saveCard(debounced: false)` for immediate writes
- ViewModel writes card to disk via WorkspaceService
- Changes persist (no explicit Save button required)

**saveCard(debounced:) Implementation:**

```swift
private func saveCard(debounced: Bool = false) {
    guard let editableCard else { return }
    if debounced {
        viewModel.updateCardDebounced(editableCard)
    } else {
        viewModel.updateCard(editableCard)
    }
}
```

**Notes:**

- Debounced writes for continuous typing (title, body) prevent lag
- Immediate writes for discrete actions (picker changes, tag operations) ensure responsive UI
- Flush on card deselection ensures no data loss when switching cards
- Empty state follows TakeNote patterns (ContentUnavailableView with icon and description)
- Navigation title updates when card title is edited

## CardMetadataEditor

**File:** `Sources/Hieroglyphs/Views/CardDetail/CardMetadataEditor.swift`

**Purpose:** Display and edit card frontmatter fields (title, type, status, priority, tags).

**Structure:**

```swift
struct CardMetadataEditor: View {
    @Binding var card: Card
    let onUpdate: (Bool) -> Void
    @State private var newTag = ""

    var body: some View {
        Form {
            Section {
                TextField("Title", text: titleBinding)
            }
            Section("Details") {
                Picker("Type", selection: typeBinding) { /* ... */ }.pickerStyle(.menu)
                Picker("Status", selection: statusBinding) { /* ... */ }.pickerStyle(.menu)
                Picker("Priority", selection: priorityBinding) { /* ... */ }.pickerStyle(.menu)
            }
            Section("Tags") {
                FlowLayout { ForEach(card.tags) { TagChipView(...) } }
                HStack { TextField("Add tag", ...) + Button(...) }
            }
        }
        .formStyle(.grouped)
    }
}
```

**Key Features:**

1. **Title Field:** Plain TextField bound to card title (debounced saves)
2. **Type Picker:** Menu picker with all CardType cases (immediate saves)
3. **Status Picker:** Menu picker with all CardStatus cases (immediate saves)
4. **Priority Picker:** Menu picker with all Priority cases (immediate saves)
5. **Tag Chips:** FlowLayout displays tags as TagChipView chips with delete buttons (immediate saves)
6. **Add Tag:** TextField with submit-on-Enter and Plus button to add new tags (immediate saves)
7. **Label Formatting:** Enum raw values formatted for display (hyphens → spaces, capitalized)

**Field Bindings:**

Each field uses a custom Binding that:
1. Gets the current card property value
2. Sets by creating a new Card with the updated property
3. Calls `onUpdate(debounced)` callback after each change
   - Title field calls `onUpdate(true)` for debounced save
   - Picker fields call `onUpdate(false)` for immediate save

**Tag Editing:**

- `addTag()`: Validates input, checks for duplicates, appends to card.tags array, calls `onUpdate(false)` for immediate save
- `removeTag()`: Filters tag from card.tags array, calls `onUpdate(false)` for immediate save
- Both operations create new Card instance

**Save Behavior:**

- **Title:** Debounced (1.5s delay) to prevent lag during continuous typing
- **Type, Status, Priority pickers:** Immediate save (discrete actions)
- **Tag add/remove:** Immediate save (discrete actions)

**FlowLayout:**

Custom Layout implementation that wraps tag chips horizontally and creates new rows as needed. Follows SwiftUI Layout protocol.

**Notes:**

- Card is immutable (struct), so all edits create new Card instances
- `onUpdate(Bool)` signature distinguishes debounced vs immediate saves
- Title uses debounced saves to prevent typing lag
- Pickers and tags use immediate saves as they are discrete user actions
- Tags support Enter key and button click for adding
- Duplicate tag check prevents adding same tag twice

## CardBodyEditor

**File:** `Sources/Hieroglyphs/Views/CardDetail/CardBodyEditor.swift`

**Purpose:** Edit card markdown body using click-to-edit pattern from TakeNote.

**Structure:**

```swift
struct CardBodyEditor: View {
    @Binding var content: String
    let onUpdate: () -> Void
    @State private var showPreview = true
    @State private var position = CodeEditor.Position()
    @State private var messages: Set<TextLocated<Message>> = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showPreview {
                    previewMode  // ScrollView with Markdown()
                } else {
                    editMode     // CodeEditor with .markdown() language
                }
            }
        }
    }
}
```

**Key Features:**

1. **Preview Mode (Default):**
   - ScrollView with `Markdown()` rendered view
   - Tap anywhere to enter edit mode
   - Uses swift-markdown-ui for rendering

2. **Edit Mode:**
   - CodeEditor with markdown syntax highlighting
   - Uses MarkdownConfiguration.markdown() from TakeNote
   - Escape key returns to preview mode (`.onExitCommand`)
   - No minimap, text wrapping enabled

3. **Syntax Highlighting:**
   - Headings, emphasis, code blocks, lists, links highlighted
   - Uses LanguageConfiguration.markdown() static method
   - Configuration copied from TakeNote

4. **Debounced Auto-Save:**
   - `contentBinding` calls `onUpdate()` when text changes
   - CardDetail passes debounced callback to avoid typing lag
   - Changes write to disk after 1.5s delay via ViewModel

**Preview Mode Details:**

- ScrollView for long content support
- Padding for comfortable reading
- Full-width alignment (`.leading`)
- Tap gesture toggles `showPreview` state

**Edit Mode Details:**

- CodeEditor requires `position` and `messages` bindings (unused but required by API)
- Layout configured via environment value (no minimap, wrap text)
- Escape key (macOS-only via `.onExitCommand`) returns to preview

**Save Behavior:**

CardDetail instantiates with debounced callback:

```swift
CardBodyEditor(
    content: bodyBinding,
    onUpdate: { saveCard(debounced: true) }
)
```

This prevents typing lag by batching rapid keystrokes into single write after delay.

**Notes:**

- Pattern copied directly from TakeNote's NoteEditor (lines 224-296)
- Preview/edit toggle is local state (not persisted)
- GeometryReader ensures proper sizing within parent VStack
- Uses environment value for CodeEditor layout configuration (non-deprecated API)
- Debounced saves prevent synchronous disk I/O on every keystroke

## TagChipView

**File:** `Sources/Hieroglyphs/Views/Shared/TagChipView.swift`

**Purpose:** Display a single tag as a chip with delete button.

**Structure:**

```swift
struct TagChipView: View {
    let tag: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag).font(.caption)
            Button { onDelete() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.secondary.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
```

**Key Features:**

1. **Pill Shape:** Rounded rectangle with 8pt corner radius
2. **Secondary Color:** Background uses `.secondary.opacity(0.2)` for subtle appearance
3. **Delete Button:** SF Symbol `xmark.circle.fill` with secondary color
4. **Compact Layout:** Caption font, minimal spacing (4pt horizontal, 8pt/4pt padding)
5. **Plain Button Style:** No hover effects, clean appearance

**Usage:**

Used in `CardMetadataEditor` within a `FlowLayout` to display all card tags. Each chip is independently deletable via `onDelete` callback.

**Notes:**

- Small, focused component following Sandi Metz principles
- Reusable across any tag display context
- Visual style matches TakeNote patterns (rounded, secondary color)

## PlanList

**File:** `Sources/Hieroglyphs/Views/PlanList/PlanList.swift`

**Purpose:** Middle column view that displays all plans for the selected project with status-based filtering.

**Structure:**

```swift
struct PlanList: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @State private var showNewPlanSheet = false

    private var filteredPlans: [Plan] {
        if viewModel.showDonePlans {
            return viewModel.plans
        } else {
            return viewModel.plans.filter { $0.status != .done }
        }
    }

    var body: some View {
        Group {
            if viewModel.selectedProject == nil {
                ContentUnavailableView(
                    "No Project Selected",
                    systemImage: "folder",
                    description: Text("Select a project from the sidebar to view its plans.")
                )
            } else if viewModel.plans.isEmpty {
                ContentUnavailableView(
                    "No Plans",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Create a plan to group cards and prepare for implementation.")
                )
            } else {
                List(selection: $viewModel.selectedPlan) {
                    ForEach(filteredPlans) { plan in
                        PlanListEntry(plan: plan)
                            .tag(plan)
                    }
                }
            }
        }
        .navigationTitle("Plans")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    viewModel.showDonePlans.toggle()
                } label: {
                    Label(viewModel.showDonePlans ? "Hide Done" : "Show Done",
                          systemImage: viewModel.showDonePlans ? "eye" : "eye.slash")
                }
                .help(viewModel.showDonePlans ? "Hide done plans" : "Show done plans")
            }

            ToolbarItem(placement: .primaryAction) {
                Button("New Plan") {
                    showNewPlanSheet = true
                }
            }
        }
        .sheet(isPresented: $showNewPlanSheet) {
            NewPlanSheet(isPresented: $showNewPlanSheet)
        }
        .onChange(of: viewModel.selectedProject) { _, _ in
            viewModel.showDonePlans = false
            viewModel.loadPlans()
            viewModel.loadCards()
        }
    }
}
```

**Key Features:**

- **Hide Done Toggle:** Toolbar button with eye/eye.slash icon (matches CardList pattern)
- **Default State:** Done plans hidden by default (`showDonePlans = false`)
- **Filter Computation:** `filteredPlans` excludes plans with `.done` status when `showDonePlans` is false
- **Filter Reset:** Filter state resets to false on project change
- **Filter Persistence:** Filter state is ephemeral (not persisted)

**Notes:**
- Displayed when Plans section is selected in sidebar
- Three states: no project selected, no plans exist, plans list
- Toolbar button shows NewPlanSheet for creating plans
- Auto-loads plans when selectedProject changes
- Selection binding to `viewModel.selectedPlan`
- Filter pattern consistent with CardList's "Hide Done/Archived" toggle

## PlanListEntry

**File:** `Sources/Hieroglyphs/Views/PlanList/PlanListEntry.swift`

**Purpose:** Individual plan row displayed in PlanList.

**Structure:**
- Plan number and title
- Status badge (planning/ready/done) with color-coded icon
- Linked card count

**Notes:**
- Follows PhaseListEntry pattern
- Status icons: planning (gray), ready (blue), done (green)

## NewPlanSheet

**File:** `Sources/Hieroglyphs/Views/PlanList/NewPlanSheet.swift`

**Purpose:** Modal sheet for creating a new plan, optionally with a source card pre-linked.

**Design (macOS 26 compliant):**
- Simple single-field modal following macOS 26 design standards
- Constrained dimensions (400x200) with scrollable content
- Semantic typography throughout
- Standard spacing and visual hierarchy
- Automatic Liquid Glass treatment on toolbar

**Structure:**

```swift
struct NewPlanSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @Binding var sourceCard: Card?

    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                } header: {
                    Text("Plan Details")
                        .font(.headline)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePlan()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 200)
    }
}
```

**Key Features:**

1. **Single Field:** Plan title is the only required field
2. **Optional Source Card:** Accepts `sourceCard` binding for pre-linking card
3. **Constrained Frame:** Fixed 400x200 dimensions for compact modal
4. **Semantic Typography:** Section header uses `.headline` font
5. **Grouped Form Style:** `.formStyle(.grouped)` for macOS-native appearance
6. **Disabled State:** Save button disabled when title is empty
7. **Standard Toolbar:** Cancel and Save buttons with standard placements

**Visual Design:**
- Section header uses `.headline` font for clear hierarchy
- Minimal vertical space appropriate for single-field form
- Standard button styles and toolbar placements

**Save Logic:**
- Calls `viewModel.createPlan(title:sourceCard:)` with entered title and optional sourceCard
- When sourceCard is provided, plan is created with card already linked
- Dismisses sheet after successful creation
- ViewModel handles plan creation and list refresh

**Usage:**

Two presentation modes:

1. **Standard plan creation** (from PlanList toolbar button):
```swift
.sheet(isPresented: $showingNewPlanSheet) {
    NewPlanSheet(sourceCard: .constant(nil))
}
```

2. **Plan creation from card** (from CardDetail toolbar or CardListEntry context menu):
```swift
.sheet(isPresented: $viewModel.showingNewPlanSheetFromCard) {
    NewPlanSheet(sourceCard: $viewModel.sourceCardForNewPlan)
}
```

**Notes:**
- Follows L17 (UI State Correctness): Constrained modal dimensions
- Follows L18 (Design Is How It Works): Platform-native appearance, semantic typography
- Simplest of the three modal sheets (only one field)
- Validates required field (disables Save if empty)
- Follows NewCardSheet and NewProjectSheet patterns for consistency
- Automatic Liquid Glass treatment on toolbar (no custom overrides)
- Pre-linking behavior transparent to user (card is linked after plan creation)

## PlanDetail

**File:** `Sources/Hieroglyphs/Views/PlanDetail/PlanDetail.swift`

**Purpose:** Detail column view for selected plan.

**Sections:**
1. Plan metadata (number, title, status picker)
2. Linked cards list with title/status/priority
3. PHASE_PROMPT.md content editor

**Features:**
- Status picker updates plan immediately and cascades to linked cards
- Add Card button shows AddCardToPlanSheet
- **Card Management Buttons:** Each linked card row shows visible action buttons:
  - View Card button (doc.text icon) navigates to card in Cards section
  - Remove from Plan button (minus.circle icon, destructive styling)
  - Both buttons include tooltips
- Remove Card action also available in context menu (secondary interaction path)
- Dangling symlinks shown as "Missing: card-slug" with warning icon
- PHASE_PROMPT.md editable via TextEditor with immediate writes
- "Generate Phase Prompt" button (disabled placeholder for future)

**Notes:**
- Two states: no plan selected (ContentUnavailableView) or plan selected
- Handles dangling symlinks gracefully
- View Card navigation switches to Cards section and selects the card

## AddCardToPlanSheet

**File:** `Sources/Hieroglyphs/Views/PlanDetail/AddCardToPlanSheet.swift`

**Purpose:** Modal sheet for adding a card to a plan with search and filter capabilities.

**Features:**

1. **Search:** `.searchable()` modifier filters cards by title (case-insensitive substring match)
2. **Filter Menus:** Toolbar provides three filter menus for status, type, and priority (multi-select toggles)
3. **Available Cards:** Lists cards not already linked to the plan
4. **Selection:** Single-select list with Add button
5. **Filter State:** Local to sheet (independent from main card list filters)

**Behavior:**
- Lists available cards (cards not already linked to plan)
- Apply search text and active filters to available cards
- Select card and click Add
- Calls `viewModel.addCardToPlan(cardSlug:planSlug:)`
- Dismisses sheet on success

**Notes:**
- Loads cards on appear
- Filters out cards already linked to selected plan
- Filter and search state is local to the sheet (not shared with CardList)

## PhasesPlaceholder

**File:** `Sources/Hieroglyphs/Views/PhasesPlaceholder.swift`

**Purpose:** Placeholder view for Phases section.

**Structure:**

```swift
struct PhasesPlaceholder: View {
    var body: some View {
        ContentUnavailableView(
            "Phases",
            systemImage: "folder.badge.gearshape",
            description: Text("Phases view coming soon")
        )
    }
}
```

**Notes:**
- Displayed when Phases section is selected in sidebar
- Phases functionality is planned for a future phase
- Uses `folder.badge.gearshape` SF Symbol

## Future View Components

**Planned components not yet implemented:**

1. **ProjectSettingsSheet:** Form for editing project metadata (already exists as EditProjectSheet)
2. **WorkspaceOnboardingView:** Onboarding flow for creating initial workspace
3. **Filter/Sort Toolbar Integration:** Integrate CardFilterBar and CardSortPopover into CardList toolbar
4. **Search Results View:** Display SpotlightService results with navigation to matched items
5. **Phase Prompt Generation UI:** Functional "Generate Phase Prompt" button for Plans

## View Testing Strategy

**Current Approach:** Views are not unit tested (SwiftUI views lack meaningful testable API).

**Verification Methods:**

1. **Manual Testing:** Run app and interact with UI
2. **Visual Inspection:** Verify layout, colors, fonts match TakeNote patterns
3. **Behavior Testing:** Verify selection, creation, and navigation work correctly

**Future:** May add UI tests using XCTest for critical workflows (e.g., project creation, card editing).

## PhaseList

**File:** `Sources/Hieroglyphs/Views/PhaseList/PhaseList.swift`

**Purpose:** Middle-column view displaying phases from a project's source directory.

**State Management:**

```swift
@Environment(HieroglyphsVM.self) private var viewModel
```

**Structure:**

PhaseList has three states:

1. **No sourceDirectory configured:** Shows ContentUnavailableView with message "Configure a source directory to view Ushabti phases"
2. **No phases found:** Shows ContentUnavailableView with message "No Ushabti phases found"
3. **Phases exist:** List with selection binding to `viewModel.selectedPhase`

**Behavior:**

- Automatically loads phases when selectedProject changes (`.onChange(of: viewModel.selectedProject)`)
- Calls `viewModel.loadPhases()` which reads from `{sourceDirectory}/.ushabti/phases/`
- Phases sorted by number ascending (1, 2, 3...)
- Selecting a phase updates `viewModel.selectedPhase` and shows PhaseDetail

**Notes:**

- Read-only view (no creation, editing, or deletion)
- No file watching (users must re-select Phases section to refresh)
- No search or filter (shows all phases)

## PhaseListEntry

**File:** `Sources/Hieroglyphs/Views/PhaseList/PhaseListEntry.swift`

**Purpose:** Individual phase row showing number, title, and status indicator.

**Layout:**

```
[status icon] Phase Title
              Phase NNNN
```

**Status Icons:**

- Planned: gray circle
- Active: blue filled circle
- Green: green checkmark
- Yellow: yellow warning triangle
- Red: red X mark

**Notes:**

- Follows CardListEntry pattern
- Uses SF Symbols for status icons
- Status color-coded for quick visual scanning

## PhaseDetail

**File:** `Sources/Hieroglyphs/Views/PhaseDetail/PhaseDetail.swift`

**Purpose:** Detail-column view for displaying selected phase.

**Structure:**

PhaseDetail has two states:

1. **No phase selected:** ContentUnavailableView with message "No Phase Selected"
2. **Phase selected:** ScrollView with four sections:
   - **Header:** Phase title, status badge, phase number
   - **Intent:** Rendered markdown from phase.md `## Intent` section
   - **Steps:** Checklist of implementation steps with completion indicators
   - **Review:** Rendered markdown from review.md (hidden if empty)

**Step Display:**

Each step shows:
- Completion icon (circle → filled circle → checkmark)
- Step title
- Step ID (e.g., "S001")
- "Implemented" label (green) if implemented
- "Reviewed" label (blue) if reviewed

**Status Badge:**

- Capsule-shaped badge with status icon and label
- Color-coded background (20% opacity of status color)
- Foreground color matches status (gray, blue, green, yellow, red)

**Notes:**

- Read-only view (no editing)
- Uses MarkdownUI for rendering intent and review notes
- Follows CardDetail pattern for empty state and ScrollView layout

## PharaohView

**File:** `Sources/Hieroglyphs/Views/Pharaoh/PharaohView.swift`

**Purpose:** Middle-column view for Pharaoh process management and status monitoring.

**Structure:**

PharaohView has two states:

1. **Not Running:** Start button, description text, error display if start failed
2. **Running:** Status badge, enriched metrics, model picker (idle only), Stop button

**Not Running State:**
- Large "Start Pharaoh" button with play icon
- Description text explaining Pharaoh functionality
- Error banner (orange) if process start failed

**Running State:**
- Status badge (color-coded: red/green/orange/blue for notRunning/idle/busy/done/blocked)
- Model picker (segmented): Visible only when idle, options for Opus/Sonnet/Haiku
- Enriched status display:
  - **Busy:** Phase name, turns elapsed, running cost ($0.4f), live elapsed time (Text(style: .relative))
  - **Done:** Phase name, final cost, turns
  - **Blocked:** Phase name, error message (red banner), final cost, turns
- Stop button (destructive role, red)

**Auto-Complete Logic:**
- Tracks `previousStatus` to detect busy → done transition
- Calls `autoCompletePlan(phase:)` to find matching plan by slug with `inProgress` status
- Updates plan status to `done` via `viewModel.updatePlanStatus()`
- Logs completion to console

**Error Alert:**
- Detects busy → blocked transition
- Shows alert with title "Phase Failed" and error message
- Alert dismissed via OK button

**Update Strategy:**
- Polls status every 2 seconds via `monitorStatus()` async task
- Status updates trigger auto-completion and error detection

**Notes:**
- Removed log viewer section (replaced by PharaohActivityStreamView in detail column)
- Model selection binds to `viewModel.pharaohModel`
- Process management (start/stop) tied to project's `sourceDirectory`

## PharaohActivityStreamView

**File:** `Sources/Hieroglyphs/Views/Pharaoh/PharaohActivityStreamView.swift`

**Purpose:** Detail-column view displaying real-time Pharaoh event stream.

**Structure:**

1. **Empty State:** ContentUnavailableView with "No Events" message when events array is empty
2. **Event List:** ScrollView with LazyVStack of PharaohEventRow components

**Event List Implementation:**
- ScrollViewReader wraps ScrollView for programmatic scrolling
- LazyVStack contains ForEach(events) rendering PharaohEventRow
- Color.clear anchor at bottom with id="bottom" for auto-scroll
- `.onChange(of: events)` triggers auto-scroll to bottom with animation

**Polling Strategy:**
- Polls events every 2 seconds via `pollEvents()` async task
- Calls `pharaohService.readEvents(from: sourceDirectory)` to read `.pharaoh/events.jsonl`
- Updates `events` state on each poll
- Auto-scroll enabled by default (could be configurable in future)

**Notes:**
- Navigation title: "Activity"
- Loads project's `sourceDirectory` from environment
- Gracefully handles missing file (service returns empty array)
- LazyVStack for performance with large event streams

## PharaohEventRow

**File:** `Sources/Hieroglyphs/Views/Pharaoh/PharaohEventRow.swift`

**Purpose:** Individual event row displaying timestamp, icon, summary, and inline detail when available.

**Structure:**

Two rendering modes:

1. **Standard Event Row:** HStack with timestamp, icon, and summary, followed by inline detail if `event.hasDetail` is true
2. **Turn Separator:** VStack with Divider and small "Turn N" label (for turn events)

**Standard Event Layout:**
- Relative timestamp: `Text(style: .relative)` in caption2 monospaced font, tertiary color, 60pt fixed width, trailing alignment
- Type icon: SF Symbol in 16pt fixed-width frame, color-coded by event type
- Summary: Truncated text with font varying by event type (callout or callout.monospaced() or callout.bold())
- **Inline Detail:** When `event.hasDetail` is true, PharaohEventDetailView renders detail content directly inline below summary with 76pt leading padding, `.caption2` font, `.tertiary` color

**Event Type Icons and Colors:**
- `toolCall`: wrench.fill, accent color, monospaced font
- `toolProgress`: clock.arrow.circlepath, secondary
- `toolSummary`: checkmark.circle, green
- `text`: text.bubble, secondary
- `turn`: separator (Divider + label, no icon)
- `status`: info.circle, blue
- `result`: checkmark.seal.fill, green, bold
- `error`: exclamationmark.triangle.fill, red, bold

**Turn Event Rendering:**
- Renders as subtle separator to reduce visual clutter
- VStack with Divider and small "Turn N" label (caption2, tertiary)
- No icon or timestamp

**Inline Detail Rendering:**
- No DisclosureGroup or expand/collapse interaction
- Detail content shown directly inline when `event.hasDetail` is true
- Indented 76pt from leading edge (aligned with summary text column)
- Uses `.caption2` font and `.tertiary` foreground for all detail text
- Empty/nil detail fields omitted gracefully (no blank rows)

**Notes:**
- Vertical padding: 2pt for standard rows, 4pt for turn separators
- Summary text limited to single line with tail truncation
- Icons follow TakeNote SF Symbol patterns
- Detail content includes: tool name, tool input, turn metrics, full text, result metrics as appropriate for event type

## PharaohMenuBar

**File:** `Sources/Hieroglyphs/Views/MenuBar/PharaohMenuBar.swift`

**Purpose:** Menu bar extra displaying running Pharaoh plans across all projects.

**Structure:**

MenuBarExtra with conditional content:

1. **Empty State:** "No Devel Jobs Running" (secondary text) when no plans with `inProgress` status exist
2. **Running Plans List:** ForEach over running plans rendering PharaohMenuBarEntry for each

**Running Plan Discovery:**
- Iterates `viewModel.projects` on each poll cycle
- For each project with non-nil `sourceDirectory`:
  - Calls `planService.loadPlans(projectPath:)` to load all plans
  - Filters to only plans with `status == .inProgress`
  - Enriches plan with stats via `pharaohService.readStatus(from: sourceDirectory)`
  - Extracts `turnsElapsed` and `runningCostUsd` from `.busy` status case
- Skips projects with nil `sourceDirectory` or failed `loadPlans()` calls (error logged, continues to next project)

**Polling Strategy:**
- Timer publishes every 3 seconds on main thread
- `loadRunningPlans()` method called on `.onAppear` and on each timer tick
- **Content comparison:** Only assigns `runningPlans` state when count changes (prevents unnecessary redraws when data unchanged)
- Polling ensures menu stays current even if file watching misses events

**Integration:**
- Added to App.swift as MenuBarExtra scene
- Conditional rendering: only shown when `viewModel.workspacePath != nil`
- Uses `.menuBarExtraStyle(.menu)` for dropdown appearance
- Label: "Pharaoh" with "chart.line.uptrend.xyaxis" SF Symbol

**Notes:**
- Guards against nil `planService` and `pharaohService` (returns early if missing)
- Tuple type: `[(project: Project, plan: Plan, turns: Int?, cost: Double?)]`
- Stats are optional (nil when Pharaoh status is not `.busy`)

## PharaohMenuBarEntry

**File:** `Sources/Hieroglyphs/Views/MenuBar/PharaohMenuBarEntry.swift`

**Purpose:** Individual row view for a running plan in menu bar dropdown.

**Structure:**

Button with VStack layout:

1. Plan title (headline font)
2. Project title (caption font, secondary color)
3. Stats line (if available): "Turn N • $X.XXXX" (caption2 font, secondary color)

**Navigation Action:**
- Button action calls `viewModel.selectSection(.pharaoh(project))`
- Guards against deleted projects — checks if project still exists in `viewModel.projects` before navigating
- Logs warning if project no longer exists: "Warning: Cannot navigate to deleted project {slug}"
- Calls `dismiss()` via `@Environment(\.dismiss)` to close menu bar dropdown
- Navigation opens Pharaoh view for the plan's project (middle column shows PharaohView, detail column shows PharaohActivityStreamView)

**Button Style:**
- Uses `.buttonStyle(.plain)` to avoid default button appearance
- VStack has `.frame(maxWidth: .infinity, alignment: .leading)` to fill available width and left-align content

**Stats Display:**
- Only shown when both `turns` and `cost` are non-nil
- Turn count formatted as integer, cost formatted as "$0.XXXX" (4 decimal places)
- Bullet separator ("•") between turn count and cost

**Notes:**
- Accepts `project`, `plan`, `turns`, `cost` as init parameters
- Stats enrichment happens in PharaohMenuBar (this view only displays)
- Menu dismissal is automatic on macOS when button clicked (dismiss() ensures compatibility)

## Accessibility

**Current State:** Basic accessibility via SwiftUI defaults (labels, semantic elements).

**Future Enhancements:**

1. Add `.accessibilityLabel()` and `.accessibilityHint()` to buttons and controls
2. Add `.accessibilityValue()` to selection state
3. Test with VoiceOver and Keyboard navigation
