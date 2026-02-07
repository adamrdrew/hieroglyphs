# View Layer and UI

## Overview

Hieroglyphs uses SwiftUI to build a three-column NavigationSplitView UI following TakeNote design patterns. The View layer is organized by feature with small, composable, focused components.

**Location:** `Sources/Hieroglyphs/Views/`

**Pattern:** Three-column NavigationSplitView (sidebar, list, detail)

**Current Implementation:** Sidebar (project list) and CardList (card list) are complete. Detail (card editor) is a placeholder for Phase 7.

Views follow L10 (Design Language Consistency with TakeNote), L09 (Small, Focused Components), and SwiftUI best practices.

## Directory Structure

```
Sources/Hieroglyphs/Views/
├── MainWindow.swift          # Root three-column NavigationSplitView
├── Sidebar/                  # Sidebar feature components
│   ├── Sidebar.swift         # Project list with toolbar
│   ├── SidebarProjectEntry.swift  # Individual project row
│   └── NewProjectSheet.swift # Project creation form
└── CardList/                 # CardList feature components
    ├── CardList.swift        # Card list with search, filter, sort
    ├── CardListEntry.swift   # Individual card row
    ├── CardFilterBar.swift   # Filter UI for status/type/priority
    ├── CardSortPopover.swift # Sort UI for criteria and order
    └── NewCardSheet.swift    # Card creation form
```

**Organization:** Views are grouped by feature (Sidebar, CardList, Detail). Each view is in its own file with focused responsibility.

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
            Text("Detail")  // Placeholder for card editor (Phase 7)
        }
    }
}
```

**Notes:**
- Three-column layout per L10 (TakeNote consistency)
- Sidebar column displays project list
- Content column will display card list (future phase)
- Detail column will display card editor (future phase)
- `preferredCompactColumn` controls which column shows on small windows (defaults to sidebar)

## Sidebar

**File:** `Sources/Hieroglyphs/Views/Sidebar/Sidebar.swift`

**Purpose:** Display project list with selection support and New Project button.

**Structure:**

```swift
struct Sidebar: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.workspaceService) private var workspaceService

    @State private var showingNewProjectSheet = false

    var body: some View {
        @Bindable var bindableViewModel = viewModel

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewProjectSheet = true
                } label: {
                    Label("New Project", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheet()
        }
    }
}
```

**Key Features:**

1. **List with Selection:** `List(selection:)` binds to `viewModel.selectedProject` for two-way selection state
2. **ForEach Projects:** Iterates over `viewModel.projects` to render project rows
3. **SidebarProjectEntry:** Renders each project row with title and card count
4. **Toolbar Button:** "New Project" button with SF Symbol `plus` icon
5. **Sheet Presentation:** Shows `NewProjectSheet` modal when button clicked

**Environment Dependencies:**
- `HieroglyphsVM` — For accessing projects and selected project state
- `workspaceService` — Passed to `SidebarProjectEntry` for loading cards

**Notes:**
- Uses `.sidebar` list style for macOS-native appearance
- `@Bindable` wrapper enables binding to `@Observable` properties
- `.tag(project)` enables selection tracking by project identity

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
6. **Toolbar Button:** "New Card" button opens NewCardSheet (disabled when no project selected)

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
3. **SF Symbols for Icons:** `folder.fill`, `plus`, etc.
4. **Click-to-Edit Pattern:** (Planned) Click card to show editor in detail column
5. **Toolbar Buttons:** Primary actions in toolbar (e.g., New Project)
6. **Sheet Presentation:** Modal forms for creation workflows
7. **Form-Based Input:** Sectioned forms with TextField and labeled inputs

**Visual Consistency:**

- Font sizes: `.body`, `.caption`
- Colors: `.secondary` for supporting text and icons
- Spacing: Consistent use of `VStack(alignment:spacing:)` and `HStack`
- Layout: Leading-aligned text, icon-text pairs

## Empty States

**Current Behavior:**

- If `viewModel.projects` is empty, Sidebar shows empty `List`
- No special empty state UI

**Future Enhancement:**

Add `ContentUnavailableView` for empty states:

```swift
if viewModel.projects.isEmpty {
    ContentUnavailableView(
        "No Projects",
        systemImage: "folder",
        description: Text("Create a project to get started.")
    )
} else {
    List { ... }
}
```

## Future View Components

**Planned components not yet implemented:**

1. **CardDetail (Detail Column):** Card editor with CodeEditorView and Markdown preview (Phase 7)
2. **ProjectSettingsSheet:** Form for editing project metadata
3. **WorkspaceOnboardingView:** Onboarding flow for creating initial workspace
4. **Filter/Sort Toolbar Integration:** Integrate CardFilterBar and CardSortPopover into CardList toolbar

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
4. Add keyboard shortcuts for common actions (e.g., Cmd+N for New Project)
