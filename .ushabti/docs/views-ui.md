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
├── CardList/                     # CardList feature components
│   ├── CardList.swift            # Card list with search, filter, sort
│   ├── CardListEntry.swift       # Individual card row
│   ├── CardFilterBar.swift       # Filter UI for status/type/priority
│   ├── CardSortPopover.swift     # Sort UI for criteria and order
│   └── NewCardSheet.swift        # Card creation form
├── CardDetail/                   # CardDetail feature components
│   ├── CardDetail.swift          # Two-section detail with empty state
│   ├── CardMetadataEditor.swift  # Form for card metadata fields
│   └── CardBodyEditor.swift      # Click-to-edit markdown preview/editor
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

**Purpose:** Root view with three-column NavigationSplitView scaffold.

**Structure:**

```swift
struct MainWindow: View {
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            Sidebar()
        } content: {
            CardList()
        } detail: {
            CardDetail()
        }
    }
}
```

**Notes:**
- Three-column layout per L10 (TakeNote consistency)
- Sidebar column displays project list with card count summaries
- Content column displays searchable, filterable card list
- Detail column displays card editor (metadata + click-to-edit markdown)
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

**Purpose:** Display project list with selection support and New Project button.

**Structure:**

```swift
struct Sidebar: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.workspaceService) private var workspaceService

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
                List(selection: $bindableViewModel.selectedProject) {
                    ForEach(viewModel.projects) { project in
                        if let workspacePath = viewModel.workspacePath {
                            SidebarProjectEntry(
                                project: project,
                                workspacePath: workspacePath,
                                workspaceService: workspaceService
                            )
                            .tag(project)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .toolbar {
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
    }
}
```

**Key Features:**

1. **Empty State:** Shows `ContentUnavailableView` when no projects exist
2. **List with Selection:** `List(selection:)` binds to `viewModel.selectedProject` for two-way selection state
3. **ForEach Projects:** Iterates over `viewModel.projects` to render project rows
4. **SidebarProjectEntry:** Renders each project row with title and card count
5. **Toolbar Button:** "New Project" button with SF Symbol `plus` icon
6. **Sheet Presentation:** Shows `NewProjectSheet` modal when button clicked (bound to ViewModel state)

**Environment Dependencies:**
- `HieroglyphsVM` — For accessing projects, selected project state, and sheet state
- `workspaceService` — Passed to `SidebarProjectEntry` for loading cards

**Sheet State Management:**
- Sheet presentation is controlled by `viewModel.showingNewProjectSheet` (not local state)
- Button calls `viewModel.showNewProjectSheet()` to trigger sheet
- Enables menu commands (Cmd+Shift+N) to open sheet from anywhere

**Notes:**
- Uses `.sidebar` list style for macOS-native appearance
- `@Bindable` wrapper enables binding to `@Observable` properties
- `.tag(project)` enables selection tracking by project identity
- Empty state shows when workspace has no projects

## SidebarProjectEntry

**File:** `Sources/Hieroglyphs/Views/Sidebar/SidebarProjectEntry.swift`

**Purpose:** Display single project row with title and card count summary.

**Structure:**

```swift
struct SidebarProjectEntry: View {
    let project: Project
    let workspacePath: String
    let workspaceService: WorkspaceProviding

    @State private var cardCounts: [CardStatus: Int] = [:]

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.title)
                    .font(.body)

                if !cardCountSummary.isEmpty {
                    Text(cardCountSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            loadCardCounts()
        }
    }

    // ... helper methods
}
```

**Key Features:**

1. **Icon:** `folder.fill` SF Symbol with secondary color
2. **Title:** Project title in body font
3. **Card Count Summary:** Card counts grouped by status (e.g., "3 todo • 2 in-progress")
4. **On-Demand Loading:** Loads cards via `workspaceService` in `.onAppear`

**Card Count Computation:**

```swift
private func loadCardCounts() {
    do {
        let projectPath = "\(workspacePath)/\(project.slug)"
        let cards = try workspaceService.loadCards(
            from: projectPath,
            for: project
        )

        var counts: [CardStatus: Int] = [:]
        for card in cards {
            counts[card.status, default: 0] += 1
        }

        cardCounts = counts
    } catch {
        print("Failed to load cards for project \(project.slug): \(error)")
    }
}
```

**Behavior:**
1. Construct project path from workspace path and slug
2. Load cards via `workspaceService.loadCards()`
3. Group cards by status and count
4. Store counts in `@State` variable
5. On error, log to console and leave counts empty

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

**Notes:**
- Card counts are loaded on-demand per project (inefficient but simple; future optimization may cache in ViewModel)
- Counts are stored in `@State` and recomputed on every `.onAppear`
- Errors are logged to console; counts remain empty on error

## NewProjectSheet

**File:** `Sources/Hieroglyphs/Views/Sidebar/NewProjectSheet.swift`

**Purpose:** Modal sheet for creating a new project.

**Structure:**

```swift
struct NewProjectSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var tags = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Tags") {
                    TextField("Comma-separated tags", text: $tags)
                }
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
    }

    // ... saveProject method
}
```

**Key Features:**

1. **NavigationStack:** Wraps Form to provide navigation bar and toolbar
2. **Form Sections:** Grouped input fields with section headers
3. **Title Field:** Required text field (Save button disabled if empty)
4. **Description Field:** Multi-line text field with vertical axis and line limits
5. **Tags Field:** Comma-separated text field for tag input
6. **Cancel Button:** Dismisses sheet without saving
7. **Save Button:** Calls `saveProject()` and dismisses (disabled if title is empty)

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
        tags: parsedTags
    )

    dismiss()
}
```

**Behavior:**
1. Parse tags by splitting on comma, trimming whitespace, and filtering empty strings
2. Call `viewModel.createProject()` with parsed inputs
3. Dismiss sheet (ViewModel handles project creation and list refresh)

**Notes:**
- No error UI (errors logged to console by ViewModel)
- No slug collision detection (future enhancement)
- Tags are simple comma-separated strings (future: tag picker UI)

## CardList

**File:** `Sources/Hieroglyphs/Views/CardList/CardList.swift`

**Purpose:** Display filtered, sorted, searchable card list for selected project.

**Structure:**

```swift
struct CardList: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @State private var showingNewCardSheet = false

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
    }
}
```

**Key Features:**

1. **Empty States:** Shows appropriate message when no project selected or no cards exist
2. **List with Selection:** Binds to `viewModel.selectedCard` for card selection
3. **Search:** `.searchable()` modifier filters cards by title (case-insensitive substring match)
4. **Filtering and Sorting:** Computed property `filteredAndSortedCards` applies all filters and sort criteria
5. **Auto-Load:** `.onChange` modifier calls `loadCards()` when selected project changes
6. **Search Focus:** Menu command (Cmd+F) can focus search field via ViewModel state
7. **Toolbar Button:** "New Card" button opens NewCardSheet (disabled when no project selected)
8. **Sheet Presentation:** Bound to ViewModel state (enables menu commands)

**Filter and Sort Logic:**

Filters are applied in sequence:
1. Search text filter (title contains substring)
2. Status filter (if filterStatus is not empty)
3. Type filter (if filterType is not empty)
4. Priority filter (if filterPriority is not empty)
5. Sort by selected criteria and order

**Empty States:**

- **No Project Selected:** `ContentUnavailableView` with folder icon
- **No Cards:** `ContentUnavailableView` with note.text icon

**Notes:**
- Uses `.plain` list style for clean appearance
- Toolbar button placement follows TakeNote patterns
- Empty states use `ContentUnavailableView` (macOS 14+)

## CardListEntry

**File:** `Sources/Hieroglyphs/Views/CardList/CardListEntry.swift`

**Purpose:** Individual card row showing title, type badge, priority indicator, and status.

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
    }
}
```

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

## NewCardSheet

**File:** `Sources/Hieroglyphs/Views/CardList/NewCardSheet.swift`

**Purpose:** Modal sheet for creating a new card.

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
            Form {
                Section("Card Details") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $type) { /* ... */ }
                    Picker("Status", selection: $status) { /* ... */ }
                    Picker("Priority", selection: $priority) { /* ... */ }
                }

                Section("Tags") {
                    TextField("Comma-separated tags", text: $tags)
                }

                Section("Body") {
                    TextEditor(text: $cardBody)
                        .frame(minHeight: 100)
                        .font(.body)
                }
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
        .frame(minWidth: 500, minHeight: 500)
    }
}
```

**Key Features:**

1. **Form with Sections:** Grouped input fields
2. **Title Field:** Required (Save button disabled if empty)
3. **Type/Status/Priority Pickers:** All enum cases available
4. **Tags Field:** Comma-separated text input
5. **Body TextEditor:** Multi-line markdown input
6. **Cancel/Save Toolbar:** Standard sheet controls
7. **Default Values:** task, todo, medium

**Save Logic:**
1. Parse tags by splitting on comma, trimming whitespace, filtering empty strings
2. Call `viewModel.createCard()` with parsed inputs
3. Dismiss sheet (ViewModel handles card creation and list refresh)

**Notes:**
- Minimum frame size (500x500) for comfortable editing
- Follows NewProjectSheet patterns
- No error UI (errors logged by ViewModel)

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

**Purpose:** Display and edit selected card metadata and markdown body in the detail column.

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

## Future View Components

**Planned components not yet implemented:**

1. **ProjectSettingsSheet:** Form for editing project metadata
2. **WorkspaceOnboardingView:** Onboarding flow for creating initial workspace
3. **Filter/Sort Toolbar Integration:** Integrate CardFilterBar and CardSortPopover into CardList toolbar
4. **Search Results View:** Display SpotlightService results with navigation to matched items

## View Testing Strategy

**Current Approach:** Views are not unit tested (SwiftUI views lack meaningful testable API).

**Verification Methods:**

1. **Manual Testing:** Run app and interact with UI
2. **Visual Inspection:** Verify layout, colors, fonts match TakeNote patterns
3. **Behavior Testing:** Verify selection, creation, and navigation work correctly

**Future:** May add UI tests using XCTest for critical workflows (e.g., project creation, card editing).

## Accessibility

**Current State:** Basic accessibility via SwiftUI defaults (labels, semantic elements).

**Future Enhancements:**

1. Add `.accessibilityLabel()` and `.accessibilityHint()` to buttons and controls
2. Add `.accessibilityValue()` to selection state
3. Test with VoiceOver and Keyboard navigation
