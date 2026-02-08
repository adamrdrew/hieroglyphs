# Phase 0015: Hierarchical Sidebar Navigation

## Intent

Transform the sidebar from a flat project list into a hierarchical structure where each project expands to reveal three sections: Cards, Plans, and Phases. This enables future support for Plans and Phases views while maintaining the current card management workflow.

Currently the sidebar displays a flat list of projects and selection is one-dimensional (project selection). This Phase introduces two-dimensional selection: project + section (Cards/Plans/Phases). The middle column will switch content based on which section is selected, with Cards showing the existing card list, and Plans/Phases showing placeholder views.

This Phase prepares navigation structure for future phases that will implement actual Plans and Phases content.

## Scope

**In Scope:**
- Define new selection type `SidebarSection` enum with cases for cards, plans, and phases (each associated with a Project)
- Refactor `HieroglyphsVM` to replace `selectedProject: Project?` with `selectedSection: SidebarSection?`
- Add computed `selectedProject: Project?` property to extract project from any section variant
- Update `Sidebar.swift` to render projects as `DisclosureGroup` with three child items (Cards, Plans, Phases)
- Update `SidebarProjectEntry` to serve as disclosure group label (project title + icon)
- Move card count summary from `SidebarProjectEntry` to the "Cards" child item
- Refactor `MainWindow.swift` middle column to switch on `selectedSection` (cards → CardList, plans → placeholder, phases → placeholder)
- Update `CardList.swift` to read selected project from the new selection model
- Maintain existing `onChange(of: viewModel.selectedProject)` logic to trigger `loadCards()` when project changes
- Create placeholder views (`PlansPlaceholder`, `PhasesPlaceholder`) using `ContentUnavailableView`
- Projects without `sourceDirectory` still show all three sections (Phases placeholder explains "No source directory configured")
- Preserve all existing card management functionality (create, edit, delete, filter, sort, search)

**Out of Scope:**
- Implementing actual Plans view content (future phase)
- Implementing actual Phases view content (future phase)
- Reading or displaying files from `sourceDirectory` (future phase)
- Any changes to card management functionality beyond adapting to new selection model
- Persistence of section selection across app launches
- Edit project functionality changes (already complete in Phase 0014)

## Constraints

**Laws:**
- **L09 (Sandi Metz Principles):** Keep views small and focused. Selection state changes must follow protocol patterns.
- **L10 (Design Language Consistency):** Maintain three-column NavigationSplitView pattern. Sidebar disclosure groups follow macOS native patterns.
- **L11 (Test Coverage):** All public methods have tests. ViewModel selection logic must be tested.
- **L12 (No Dead Code):** Remove any unused selection logic. No commented-out code.

**Style:**
- Selection model changes must be clear and explicit (no magic)
- Computed properties preferred over duplicated logic
- Placeholder views use `ContentUnavailableView` pattern already established
- Bindings use `@Bindable` wrapper on `@Observable` properties
- Minimize disruption to existing card workflow (avoid regressions)

## Acceptance Criteria

- [ ] `SidebarSection` enum is defined with three cases: `.cards(Project)`, `.plans(Project)`, `.phases(Project)`
- [ ] `HieroglyphsVM.selectedSection: SidebarSection?` replaces `selectedProject: Project?`
- [ ] `HieroglyphsVM.selectedProject: Project?` exists as computed property extracting project from `selectedSection`
- [ ] `Sidebar` renders projects as `DisclosureGroup` with three child items
- [ ] Expanding a project reveals "Cards", "Plans", "Phases" as selectable items
- [ ] Card count summary appears next to "Cards" child item (not in disclosure group label)
- [ ] `SidebarProjectEntry` serves as disclosure group label (icon + project title only)
- [ ] Selecting "Cards" shows `CardList` in middle column
- [ ] Selecting "Plans" shows `PlansPlaceholder` in middle column
- [ ] Selecting "Phases" shows `PhasesPlaceholder` in middle column
- [ ] `PlansPlaceholder` and `PhasesPlaceholder` use `ContentUnavailableView` with appropriate icons and text
- [ ] `MainWindow` middle column switches based on `selectedSection` value
- [ ] `CardList` continues to work correctly with new selection model
- [ ] `onChange(of: viewModel.selectedProject)` triggers `loadCards()` when project changes (even if section changes within same project)
- [ ] All existing card functionality works without regression (create, edit, delete, filter, sort, search)
- [ ] Selection behavior is intuitive (selecting a project section updates both project and section state)
- [ ] Tests updated to reflect new selection model
- [ ] No dead code remains from old selection model

## Risks / Notes

**Risks:**
- Selection model change touches ViewModel (core coordination layer). Thorough testing required to prevent regressions.
- `onChange` monitoring must correctly detect when the underlying project changes, even when switching between sections of different projects.

**Notes:**
- This Phase is purely structural. No actual Plans or Phases content is implemented.
- Future phases will replace placeholder views with real content.
- Projects without `sourceDirectory` will still show Phases section (placeholder explains limitation).
- Card count summary moves from disclosure label to "Cards" item for clarity and proper hierarchy.
- Computed `selectedProject` property maintains compatibility with existing code that needs only the project (not the section).
