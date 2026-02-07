# View Layer and UI

## Overview

Hieroglyphs uses SwiftUI to build a three-column NavigationSplitView UI following TakeNote design patterns. The View layer is organized by feature with small, composable, focused components.

**Location:** `Sources/Hieroglyphs/Views/`

**Pattern:** Three-column NavigationSplitView (sidebar, list, detail)

**Current Implementation:** Sidebar (project list) is complete. List (card list) and Detail (card editor) are placeholders for future phases.

Views follow L10 (Design Language Consistency with TakeNote), L09 (Small, Focused Components), and SwiftUI best practices.

## Directory Structure

```
Sources/Hieroglyphs/Views/
├── MainWindow.swift          # Root three-column NavigationSplitView
└── Sidebar/                  # Sidebar feature components
    ├── Sidebar.swift         # Project list with toolbar
    ├── SidebarProjectEntry.swift  # Individual project row
    └── NewProjectSheet.swift # Project creation form
```

**Organization:** Views are grouped by feature (Sidebar, List, Detail). Each view is in its own file with focused responsibility.

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
            Text("List")  // Placeholder for card list (Phase 6)
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

1. **CardList (Middle Column):** Display cards for selected project with status grouping
2. **CardListEntry:** Individual card row with title, type icon, and priority indicator
3. **CardDetail (Detail Column):** Card editor with CodeEditorView and Markdown preview
4. **NewCardSheet:** Form for creating cards
5. **ProjectSettingsSheet:** Form for editing project metadata
6. **WorkspaceOnboardingView:** Onboarding flow for creating initial workspace

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
