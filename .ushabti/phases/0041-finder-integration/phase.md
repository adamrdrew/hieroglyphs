# Phase 0041: Finder Integration for Projects

## Intent

Add context menu options to project entries in the sidebar to open project directories and source directories in Finder. This provides quick access to project files for users working with external tools, text editors, or command-line workflows.

All projects get "Open in Finder" to reveal their project directory. Projects with a configured sourceDirectory also get "Open Source in Finder" to reveal that directory.

## Scope

**In scope:**
- Add "Open in Finder" menu item to SidebarProjectEntry.contextMenu that opens the project directory
- Add "Open Source in Finder" menu item (conditional on sourceDirectory != nil) that opens the source directory
- Use NSWorkspace.shared.open() to reveal directories in Finder
- Handle errors gracefully (missing directories, permission issues)
- Use appropriate SF Symbols for menu items

**Out of scope:**
- Opening individual cards in Finder
- Opening plans in Finder
- Keyboard shortcuts for Finder operations
- Toolbar buttons for Finder operations

## Constraints

- L06: Platform leverage over reinvention — use NSWorkspace for Finder integration
- L09: Sandi Metz principles — small focused methods
- L17: UI state correctness — disabled/hidden controls for unavailable actions
- L18: Design is how it works — controls communicate state and availability
- Style: SF Symbols for icons, clear naming, graceful error handling

## Acceptance Criteria

- "Open in Finder" menu item appears in project context menu for all projects
- Clicking "Open in Finder" reveals the project directory in Finder
- "Open Source in Finder" menu item appears only when project.sourceDirectory != nil
- Clicking "Open Source in Finder" reveals the source directory in Finder
- Menu items use appropriate SF Symbols (folder icon variants)
- Operations handle missing directories gracefully (no crash, user-visible error if needed)
- Menu items are ordered logically in the context menu

## Risks / Notes

- NSWorkspace.open() may fail silently if the directory doesn't exist or the user lacks permissions. We should verify directory existence before calling it and provide feedback on failure.
- The context menu in SidebarProjectEntry already has "Edit Project" and "Delete" — need to maintain logical grouping (Finder actions first, then Edit, then destructive Delete).
