# Steps

## S001: Add "Open in Finder" menu item

**Intent:** Allow users to reveal the project directory in Finder from the sidebar context menu.

**Work:**
- Add a new menu item to SidebarProjectEntry.contextMenu above "Edit Project"
- Label: "Open in Finder"
- SF Symbol: "folder"
- Action: Call a helper method openProjectInFinder() that uses NSWorkspace.shared.open() with the project directory URL
- Construct project directory path as workspacePath/project.slug
- Convert path to URL and pass to NSWorkspace.shared.open()

**Done when:** "Open in Finder" menu item appears for all projects and successfully reveals the project directory in Finder.

---

## S002: Add "Open Source in Finder" menu item (conditional)

**Intent:** Allow users to reveal the source directory in Finder when one is configured.

**Work:**
- Add a conditional menu item to SidebarProjectEntry.contextMenu below "Open in Finder"
- Only include this item when project.sourceDirectory != nil
- Label: "Open Source in Finder"
- SF Symbol: "folder.badge.gearshape"
- Action: Call a helper method openSourceInFinder() that uses NSWorkspace.shared.open() with the source directory URL
- Use project.sourceDirectory as the path (already an absolute path)
- Convert path to URL and pass to NSWorkspace.shared.open()

**Done when:** "Open Source in Finder" menu item appears only for projects with a sourceDirectory, and successfully reveals that directory in Finder.

---

## S003: Add error handling for missing directories

**Intent:** Prevent silent failures when directories do not exist or are inaccessible.

**Work:**
- Before calling NSWorkspace.shared.open(), check if directory exists using FileManager.default.fileExists(atPath:)
- If directory does not exist, log an error (print to console is sufficient for now)
- NSWorkspace.shared.open() returns a Bool indicating success — check the result and log on failure
- Defensive programming: normally directories should exist, but external tools may have moved/deleted them

**Done when:** Both helper methods verify directory existence before opening and log errors when operations fail.

---

## S004: Add menu separators for logical grouping

**Intent:** Keep the context menu organized with related actions grouped together.

**Work:**
- Add a Divider() after the Finder-related menu items (before "Edit Project")
- This groups Finder actions (open/reveal) separately from metadata actions (edit) and destructive actions (delete)
- The separator provides visual hierarchy in the context menu

**Done when:** Context menu has a divider between Finder actions and Edit/Delete actions, providing clear visual grouping.

---

## S005: Manual testing

**Intent:** Verify the feature works correctly in all scenarios.

**Work:**
- Test "Open in Finder" on a project without a source directory
- Test "Open in Finder" on a project with a source directory
- Test "Open Source in Finder" on a project with a source directory
- Verify that "Open Source in Finder" does NOT appear for projects without a source directory
- Test error path: rename a project directory externally, then try to open it in Finder (verify graceful failure)
- Verify menu item ordering and visual grouping with separators

**Done when:** All scenarios tested, menu items appear correctly, Finder reveals work as expected, errors are handled gracefully.
