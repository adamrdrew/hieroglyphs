# Steps

## S001: Add context menu to SidebarProjectEntry

**Intent:** Enable right-click deletion from project list entries.

**Work:**
- Open `Sources/Hieroglyphs/Views/Sidebar/SidebarProjectEntry.swift`
- Add `.contextMenu` modifier to the HStack view body
- Add "Delete" button with trash icon and `.destructive` role
- Button sets `projectPendingDeletion` state variable
- Add `@State private var projectPendingDeletion: Project?` to SidebarProjectEntry

**Done when:** Right-clicking a project entry shows "Delete" option with red text and trash icon.

## S002: Add confirmation alert to SidebarProjectEntry

**Intent:** Require explicit confirmation before deleting a project.

**Work:**
- Add `.alert()` modifier to SidebarProjectEntry view body
- Alert title: "Delete Project"
- Alert message: "Are you sure you want to delete '\(project.title)'? This will move the project and all its cards to Trash."
- Alert presenting binding derives from `projectPendingDeletion != nil`
- Two buttons: "Cancel" (cancel role, clears state) and "Delete" (destructive role, calls deletion)
- On Delete confirmation: call `viewModel.deleteProject(project)`

**Done when:** Selecting "Delete" from context menu shows confirmation alert with project title. Confirming calls ViewModel, canceling dismisses.

## S003: Add toolbar delete button to Sidebar

**Intent:** Provide toolbar access to project deletion.

**Work:**
- Open `Sources/Hieroglyphs/Views/Sidebar/Sidebar.swift`
- Add new ToolbarItem with `.destructive` placement (or `.automatic` with destructive styling)
- Button label: trash icon with "Delete Project" label
- Button is visible only when `viewModel.selectedProject != nil`
- Button sets local `@State private var projectPendingDeletion: Project?` to `viewModel.selectedProject`
- Add confirmation alert to Sidebar view (same structure as S002)

**Done when:** Toolbar shows delete button only when a project is selected. Clicking shows confirmation alert.

## S004: Implement deleteProject method in ViewModel

**Intent:** Coordinate project deletion via WorkspaceService.

**Work:**
- Open `Sources/Hieroglyphs/HieroglyphsVM.swift`
- Add method: `func deleteProject(_ project: Project)`
- Guard check `workspacePath != nil` (log error and return if nil)
- Construct project path: `"\(workspacePath)/\(project.slug)"`
- Call `workspaceService.deleteProject(at: projectPath)`
- Set `selectedSection = nil` to clear selection
- Call `loadProjects()` to reload project list
- Catch errors and log to console

**Done when:** ViewModel has `deleteProject(_:)` method that trashes project directory, clears selection, and reloads projects.

## S005: Update deleteSelectedItem to support projects

**Intent:** Extend existing keyboard shortcut to support project deletion.

**Work:**
- Open `Sources/Hieroglyphs/HieroglyphsVM.swift`
- Locate `deleteSelectedItem()` method
- Update logic to check `selectedCard` first, then fall back to `selectedProject`
- If `selectedCard != nil`: delete card (existing logic)
- Else if `selectedProject != nil`: call `deleteProject(selectedProject)`
- This enables Cmd+Delete to work for both cards and projects

**Done when:** Cmd+Delete deletes selected card if card is selected, otherwise deletes selected project if project is selected.

## S006: Test project deletion workflow

**Intent:** Verify all interaction paths work correctly.

**Work:**
- Build and run app
- Create test project
- Test context menu deletion:
  - Right-click project → Select Delete → Confirm → Verify project is trashed and list refreshes
  - Right-click project → Select Delete → Cancel → Verify no action
- Test toolbar deletion:
  - Select project → Click toolbar delete button → Confirm → Verify project is trashed
  - Click toolbar delete button → Cancel → Verify no action
- Test keyboard shortcut:
  - Select project → Press Cmd+Delete → Confirm → Verify project is trashed
- Verify selection clears after deletion
- Verify empty state shows when last project is deleted
- Verify errors are logged for missing workspace path

**Done when:** All deletion paths work correctly with confirmation. Selection clears. List refreshes. Empty state shows when appropriate.

## S007: Add deleteProject method documentation to viewmodel.md

**Intent:** Document the new deleteProject coordination method in ViewModel.

**Work:**
- Open `.ushabti/docs/viewmodel.md`
- Locate the section after `updateProject(_:)` method documentation
- Add new section documenting `deleteProject(_:)` method
- Include signature, purpose, behavior steps, error handling, and usage examples
- Follow the same documentation pattern as other ViewModel mutation methods
- Note that it clears selection state and reloads project list

**Done when:** `deleteProject(_:)` method is fully documented in viewmodel.md with signature, purpose, behavior, error handling, and usage.

## S008: Update SidebarProjectEntry docs in views-ui.md

**Intent:** Document the deletion context menu and confirmation alert in SidebarProjectEntry.

**Work:**
- Open `.ushabti/docs/views-ui.md`
- Locate the SidebarProjectEntry section
- Update the structure example to show both Edit and Delete context menu items
- Update the state variables to include `projectPendingDeletion`
- Add documentation for the confirmation alert
- Update Key Features section to note deletion functionality
- Follow the same documentation pattern as CardListEntry (which has similar delete functionality)

**Done when:** SidebarProjectEntry docs show the current implementation including Edit and Delete context menu items and confirmation alert.

## S009: Update Sidebar docs in views-ui.md

**Intent:** Document the toolbar delete button in Sidebar view.

**Work:**
- Open `.ushabti/docs/views-ui.md`
- Locate the Sidebar section
- Find the Toolbar subsection
- Add documentation for the delete button
- Note that it is visible only when a project is selected
- Document the confirmation alert structure
- Include the state variable `projectPendingDeletion`

**Done when:** Sidebar toolbar documentation includes delete button with visibility conditions and confirmation alert.
