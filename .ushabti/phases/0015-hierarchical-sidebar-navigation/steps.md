# Implementation Steps

## S001: Define SidebarSection enum and update ViewModel selection model

**Intent:** Establish the new two-dimensional selection type and replace the flat project selection in the ViewModel. This is the foundation for hierarchical navigation.

**Work:**
1. Create `SidebarSection` enum in `HieroglyphsVM.swift` with three cases: `.cards(Project)`, `.plans(Project)`, `.phases(Project)`. Mark as `Hashable` for List selection support.
2. Replace `var selectedProject: Project?` with `var selectedSection: SidebarSection?` in `HieroglyphsVM`.
3. Add computed property `var selectedProject: Project?` that extracts the project from any `selectedSection` variant, returning `nil` if `selectedSection` is `nil`.
4. Update any direct references to the old `selectedProject` stored property within `HieroglyphsVM` to work with `selectedSection` instead.

**Done when:**
- `SidebarSection` enum exists with three cases, all associated with `Project`
- `HieroglyphsVM` has `selectedSection: SidebarSection?` as the primary selection state
- `HieroglyphsVM` has computed `selectedProject: Project?` that returns the project from any section case
- ViewModel compiles without errors

## S002: Refactor Sidebar to use DisclosureGroup with child items

**Intent:** Transform the flat project list into a hierarchical structure where each project can be expanded to show Cards, Plans, and Phases sections.

**Work:**
1. Replace the flat `ForEach(viewModel.projects)` in `Sidebar.swift` with a structure that wraps each project in a `DisclosureGroup`.
2. Use `SidebarProjectEntry` as the `label` parameter of `DisclosureGroup` (shows project icon + title).
3. Inside each `DisclosureGroup`, add three child items: Text("Cards"), Text("Plans"), Text("Phases").
4. Each child item must be `.tag()`-ed with the appropriate `SidebarSection` case: `.tag(SidebarSection.cards(project))`, etc.
5. Update the `List(selection:)` binding from `$bindableViewModel.selectedProject` to `$bindableViewModel.selectedSection`.
6. Remove card count display from `SidebarProjectEntry` (will move to Cards child in next step).

**Done when:**
- Sidebar displays projects as expandable disclosure groups
- Each disclosure group shows project title and icon as the label
- Expanding a project reveals three child items: Cards, Plans, Phases
- Child items are selectable and update `viewModel.selectedSection`
- `SidebarProjectEntry` no longer displays card count summary

## S003: Add card count summary to Cards child item

**Intent:** Display card count summary next to the "Cards" section item rather than in the disclosure group label, providing clearer visual hierarchy.

**Work:**
1. Replace `Text("Cards")` in the `DisclosureGroup` content with a custom view (inline or extracted) that displays "Cards" and the card count summary.
2. Load cards for the project (similar to the original `SidebarProjectEntry` logic) and compute the card count summary string.
3. Display the summary as secondary text or a badge next to "Cards".
4. Apply appropriate styling (caption font, secondary color) to match existing patterns.
5. Ensure card count loading happens on-demand (`.onAppear` or similar) to avoid loading all project cards upfront.

**Done when:**
- "Cards" item displays card count summary (e.g., "3 todo • 2 in progress")
- Card counts load on-demand when disclosure group is expanded or sidebar is rendered
- Summary formatting matches the original `SidebarProjectEntry` style (bullet-separated status counts)
- "Plans" and "Phases" items remain as plain text (no counts)

## S004: Update MainWindow to switch middle column based on selectedSection

**Intent:** Route the middle column content based on which sidebar section is selected (Cards, Plans, or Phases).

**Work:**
1. Wrap the `content:` parameter of `NavigationSplitView` in conditional logic based on `viewModel.selectedSection`.
2. If `selectedSection` is `.cards(project)`, show `CardList()`.
3. If `selectedSection` is `.plans(project)`, show `PlansPlaceholder()` (to be created).
4. If `selectedSection` is `.phases(project)`, show `PhasesPlaceholder()` (to be created).
5. If `selectedSection` is `nil`, show existing empty state (ContentUnavailableView "Select a Project").
6. Create `PlansPlaceholder.swift` in `Views/` (or `Views/Placeholders/`) as a `ContentUnavailableView` with title "Plans", systemImage "list.bullet.clipboard", and description "Plans view coming soon".
7. Create `PhasesPlaceholder.swift` similarly with title "Phases", systemImage "folder.badge.gearshape", and description "Phases view coming soon" (or "No source directory configured" if applicable).

**Done when:**
- Middle column shows `CardList` when Cards section is selected
- Middle column shows `PlansPlaceholder` when Plans section is selected
- Middle column shows `PhasesPlaceholder` when Phases section is selected
- Middle column shows empty state when no section is selected
- `PlansPlaceholder.swift` and `PhasesPlaceholder.swift` exist and use `ContentUnavailableView`

## S005: Update CardList to read selectedProject from computed property

**Intent:** Ensure `CardList` continues to function with the new selection model by reading the selected project from the computed property.

**Work:**
1. Verify that `CardList.swift` references `viewModel.selectedProject` (the computed property, not the old stored property).
2. Verify that the `.onChange(of: viewModel.selectedProject)` modifier correctly triggers `viewModel.loadCards()` when the project changes.
3. Test that switching between sections of the same project does not reload cards (project hasn't changed).
4. Test that switching from one project's Cards section to another project's Cards section does reload cards (project has changed).
5. No code changes may be needed if `CardList` already uses `viewModel.selectedProject`—this step verifies correct behavior.

**Done when:**
- `CardList` reads from `viewModel.selectedProject` computed property
- `onChange(of: viewModel.selectedProject)` triggers `loadCards()` when project changes
- Switching sections within the same project does not reload cards
- Switching projects reloads cards correctly
- Card list functionality (search, filter, sort) works without regression

## S006: Update tests for new selection model

**Intent:** Ensure test coverage reflects the new selection model and that existing tests pass with the refactored ViewModel.

**Work:**
1. Update `HieroglyphsVMTests.swift` to test `selectedSection` instead of `selectedProject` where applicable.
2. Add tests for the computed `selectedProject` property to verify it correctly extracts the project from all three section cases.
3. Add tests for setting `selectedSection` to each case and verifying the computed `selectedProject` returns the expected project.
4. Update any tests that directly set `selectedProject` to instead set `selectedSection` with an appropriate case.
5. Verify that all tests pass and cover the new selection logic.
6. Add test case for `selectedSection = nil` → `selectedProject = nil`.

**Done when:**
- Tests cover `selectedSection` property and all three cases
- Tests cover computed `selectedProject` property for all section cases
- Tests verify `selectedProject` returns `nil` when `selectedSection` is `nil`
- All existing tests pass (no regressions)
- Test coverage for selection logic is complete

## S007: Manual testing and regression check

**Intent:** Verify that all card management workflows function correctly with the new hierarchical sidebar and that no regressions were introduced.

**Work:**
1. Launch the app and verify projects display as expandable disclosure groups in the sidebar.
2. Expand a project and verify Cards, Plans, Phases items appear.
3. Select Cards section and verify card list appears in the middle column.
4. Select Plans section and verify placeholder appears.
5. Select Phases section and verify placeholder appears.
6. Create a new card from the Cards view and verify it appears in the list.
7. Edit a card and verify changes persist.
8. Delete a card and verify it is removed.
9. Test search, filter, and sort functionality in card list.
10. Switch between projects and verify card list updates correctly.
11. Switch between sections within a project and verify appropriate content appears.
12. Verify card count summary displays correctly in the Cards item.
13. Verify no dead code or commented-out code remains from the refactor.

**Done when:**
- All manual tests pass
- Card creation, editing, deletion work correctly
- Search, filter, sort work correctly
- Section switching shows correct content
- Card counts display correctly
- No regressions observed in card management workflow
- Code is clean (no dead code or comments)
