# Phase 0005: Sidebar and Project List

## Intent

Build the sidebar UI layer for displaying projects with card count summaries grouped by status. The HieroglyphsVM (ViewModel) coordinates between the WorkspaceService and UI, holding selection state and navigation preferences. The Sidebar view displays a list of projects with each entry showing the project title and card counts by status (e.g., "3 todo, 2 in-progress, 1 done"). Selecting a project updates the ViewModel's selected project state. A New Project button triggers project creation through WorkspaceService.

This phase establishes the first interactive UI component following TakeNote design patterns, connects the service layer to the view layer through a protocol-injected ViewModel, and enables basic project selection and creation workflows.

## Scope

**In scope:**
- `HieroglyphsVM` — @Observable @MainActor class holding workspace path, projects, selected project, and workspace service reference
- `HieroglyphsVM.loadWorkspace()` — Loads config and projects from WorkspaceService on app launch
- `HieroglyphsVM.createProject(title:description:tags:)` — Delegates to WorkspaceService, reloads projects
- `HieroglyphsVM.selectProject(_:)` — Updates selected project state
- `HieroglyphsVM` injected via `.environment()` in App.swift
- `Sidebar.swift` view displaying project list with selection binding
- `SidebarProjectEntry.swift` view showing project title and card count summary by status
- New Project button in Sidebar toolbar that presents sheet for project creation
- `NewProjectSheet.swift` — Simple form for entering project title, description, tags
- Card count computation: load cards for each project via WorkspaceService, group by status, display counts
- Integration with MainWindow's NavigationSplitView sidebar column
- Tests for HieroglyphsVM public methods (loadWorkspace, createProject, selectProject)

**Out of scope:**
- Card list view (middle column) — Phase 6
- Card detail editor (detail column) — Phase 7
- File watching or real-time refresh (Phase 8+)
- Project editing/deletion UI
- Sort/filter for project list (projects shown in load order)
- Tag reconciliation with extended attributes
- Error UI for workspace loading failures (errors logged to console for now)
- Rename project, delete project UI
- Spotlight search integration

## Constraints

**Laws:**
- L01 — Filesystem as Source of Truth: ViewModel reads state from WorkspaceService on demand, does not cache stale data
- L09 — Sandi Metz Principles: Small classes/methods, protocol-based service injection, single responsibility
- L10 — Design Language Consistency with TakeNote: NavigationSplitView, List with selection binding, SF Symbols, click patterns
- L11 — Test Coverage: All public ViewModel methods must have tests

**Style:**
- ViewModel is @Observable @MainActor class, single shared instance
- Services injected via @Environment
- Views organized by feature: Views/Sidebar/, Views/Shared/
- Small composable SwiftUI views (one view per file, focused responsibility)
- SF Symbols for icons (folder.fill, plus, etc.)
- Clear naming (clarity over brevity)

**TakeNote Patterns:**
- Three-column NavigationSplitView (MainWindow.swift)
- Sidebar uses `List(selection: $binding)` for selection tracking
- Toolbar button for New Project
- Sheet presentation for creation forms
- Project entry follows TakeNote's three-row entry pattern (adapted: title + count summary)

## Acceptance Criteria

1. `HieroglyphsVM.swift` exists in Sources/Hieroglyphs/ with @Observable @MainActor annotations
2. HieroglyphsVM holds workspace path (String), projects ([Project]), selectedProject (Project?), and WorkspaceService reference
3. `loadWorkspace()` method loads config via WorkspaceService.loadWorkspaceConfig, then loads projects via WorkspaceService.loadProjects
4. `createProject(title:description:tags:)` method calls WorkspaceService.createProject, then reloads projects via loadProjects
5. `selectProject(_:)` method updates selectedProject state
6. HieroglyphsVM initialized in App.swift and injected via `.environment(viewModel)`
7. WorkspaceService instance created in App.swift and passed to HieroglyphsVM initializer
8. `Sidebar.swift` view displays List of projects with selection binding to ViewModel.selectedProject
9. Sidebar integrated into MainWindow's NavigationSplitView sidebar column
10. `SidebarProjectEntry.swift` view displays project title and card count summary (e.g., "3 todo • 2 in-progress • 1 done")
11. Card counts computed by loading cards via WorkspaceService.loadCards and grouping by status
12. Counts only display for statuses with non-zero cards (e.g., if no "done" cards, omit "done" from summary)
13. New Project toolbar button in Sidebar presents NewProjectSheet
14. `NewProjectSheet.swift` has text fields for title, description, and tags (comma-separated)
15. NewProjectSheet calls ViewModel.createProject on save, dismisses on cancel/save
16. Sidebar uses SF Symbols for icons (e.g., folder.fill for projects, plus for new project button)
17. Tests for HieroglyphsVM cover: loadWorkspace (success/failure), createProject, selectProject
18. Tests use mock WorkspaceProviding implementation for isolation
19. `swift test` passes with 100% success
20. `swift build` completes without errors or warnings
21. App launches and displays sidebar with placeholder projects if workspace exists

## Risks / Notes

**ViewModel initialization timing:** HieroglyphsVM.loadWorkspace() called in App.init or .onAppear of MainWindow. If config does not exist, app should handle gracefully (show empty state or onboarding UI). For this phase, log error to console and show empty project list.

**Card count performance:** Loading all cards for all projects on every render is expensive. For this phase, compute counts in SidebarProjectEntry.onAppear and cache in @State. Future phases will optimize with incremental loading or caching in ViewModel.

**Workspace path storage:** ViewModel loads workspace path from config on launch. If config missing, workspace path is nil and project list is empty. This is acceptable for Phase 5. Future phases add workspace setup UI.

**Project creation errors:** If createProject throws (e.g., slug collision), error is logged to console. No user-facing error UI in this phase. Future phases add error handling UI.

**Tags input:** NewProjectSheet uses comma-separated text field for tags. Tags split on comma and trimmed. This is simple but sufficient for v1. Future phases may add tag picker UI.

**Selection state persistence:** selectedProject is ephemeral (not persisted). On app relaunch, no project is selected. Future phases may persist selection to UserDefaults.

**Card count display format:** Counts shown as "N status" with bullet separators. E.g., "3 todo • 2 in-progress • 1 done". Use CardStatus.rawValue for display labels, replacing hyphens with spaces for readability.

**Empty states:** If no projects exist, Sidebar shows empty List. Future phases add ContentUnavailableView for empty state messaging.

**Test strategy:** ViewModel tests use mock WorkspaceProviding to isolate from filesystem. Views are not unit tested (SwiftUI views tested via UI tests or manual verification). Focus test coverage on ViewModel public methods.
