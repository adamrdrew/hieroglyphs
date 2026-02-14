# Phase 0034: Project Deletion

## Intent

Add project deletion functionality accessible via context menu and toolbar. Users can delete projects by right-clicking a project entry in the sidebar or using a toolbar button when a project is selected. All deletions require explicit confirmation via an alert dialog to prevent accidental data loss.

## Scope

**In scope:**
- Context menu "Delete" option on sidebar project entries
- Toolbar delete button in Sidebar view (enabled when a project is selected)
- Confirmation alert with project title displayed
- ViewModel method to handle project deletion via WorkspaceService
- Selection clearing after successful deletion
- Project list refresh after deletion

**Out of scope:**
- Keyboard shortcuts for deletion (already exists as Cmd+Delete)
- Bulk deletion of multiple projects
- Trash restoration UI
- Deletion undo within the app
- Cascade deletion of cards (handled by FileManager when directory is trashed)

## Constraints

- **L06 (Platform Leverage):** Use FileManager.trashItem for reversible deletion
- **L09 (Sandi Metz):** Delete logic belongs in ViewModel coordination layer
- **L17 (UI State Correctness):** Selection must clear after deletion
- **L18 (Design Is How It Works):** Destructive actions require confirmation
- **Style:** Context menu uses `.destructive` role, toolbar button uses `.destructive` button role
- **Style:** Alert shows project title for clarity
- **Style:** Toolbar button shows only when a project is selected (not just disabled)

## Acceptance Criteria

1. **Context menu deletion:**
   - Right-clicking a project entry shows "Delete" option with trash icon
   - Delete option uses `.destructive` role (red text)
   - Selecting Delete shows confirmation alert with project title
   - Confirming moves project directory to macOS Trash via FileManager
   - Canceling dismisses alert without action

2. **Toolbar deletion:**
   - Sidebar toolbar shows delete button with trash icon
   - Button is visible only when a project is selected
   - Clicking button shows same confirmation alert as context menu
   - Confirming deletes the selected project
   - Canceling dismisses alert without action

3. **Confirmation alert:**
   - Title: "Delete Project"
   - Message: "Are you sure you want to delete '{project.title}'? This will move the project and all its cards to Trash."
   - Two buttons: "Cancel" (cancel role) and "Delete" (destructive role)

4. **Post-deletion state:**
   - `selectedSection` is set to nil (clears project and section selection)
   - `projects` array is reloaded from disk
   - Sidebar updates to show remaining projects
   - If no projects remain, empty state is shown

5. **Error handling:**
   - Errors are logged to console
   - Deletion fails gracefully (project remains in list)

## Risks / Notes

- Deletion moves entire project directory to Trash (includes all cards, plans, and subdirectories)
- Trash is reversible via Finder (user can restore if needed)
- No cascade logic needed — directory deletion handles all contained files
- Existing `deleteSelectedItem()` method already handles card deletion; will extend to support projects
- WorkspaceService already has `deleteProject(at:)` method (from workspace-service.md)
- Context menu pattern already exists in CardList for card deletion (can mirror implementation)
