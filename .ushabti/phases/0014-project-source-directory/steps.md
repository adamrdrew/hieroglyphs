# Steps for Phase 0014

## S001: Add sourceDirectory to Project model

**Intent:** Extend Project model to store optional source directory path.

**Work:**
- Add `let sourceDirectory: String?` field to Project struct in `Sources/Hieroglyphs/Models/Project.swift`
- Update all Project initializers to include sourceDirectory parameter

**Done when:**
- Project struct compiles with new field
- All existing Project initializations compile (passing nil for sourceDirectory where needed)

## S002: Update WorkspaceService.parseProject to read source_directory

**Intent:** Enable reading source_directory from project.md frontmatter.

**Work:**
- Modify `parseProject(from:)` in WorkspaceService to read optional `source_directory` field from frontmatter
- Default to nil if field is absent
- Pass sourceDirectory to Project initializer

**Done when:**
- parseProject successfully reads source_directory when present
- parseProject defaults to nil when source_directory is absent
- Existing projects without source_directory load without error

## S003: Update WorkspaceService.createProject to write source_directory

**Intent:** Enable writing source_directory to project.md frontmatter when creating projects.

**Work:**
- Add `sourceDirectory: String?` parameter to createProject method signature in WorkspaceProviding protocol
- Update WorkspaceService.createProject implementation to accept sourceDirectory parameter
- Include `source_directory` in frontmatter dictionary only when sourceDirectory is non-nil
- Pass sourceDirectory to Project initializer
- Update ViewModel.createProject to accept and pass sourceDirectory parameter

**Done when:**
- createProject method signature includes sourceDirectory parameter in protocol and implementation
- Creating project with nil sourceDirectory omits source_directory from frontmatter
- Creating project with non-nil sourceDirectory writes source_directory to frontmatter
- Project model returned from createProject includes sourceDirectory value

## S004: Update WorkspaceService.updateProject to write source_directory

**Intent:** Enable updating source_directory when editing projects.

**Work:**
- Modify WorkspaceService.updateProject to write `source_directory` to frontmatter when project.sourceDirectory is non-nil
- Omit source_directory from frontmatter when project.sourceDirectory is nil
- Ensure unknown fields remain preserved per L02

**Done when:**
- updateProject writes source_directory when non-nil
- updateProject omits source_directory when nil
- Round-trip test confirms unknown fields preserved

## S005: Add directory picker to NewProjectSheet

**Intent:** Allow users to optionally select a source directory when creating projects.

**Work:**
- Add `@State private var sourceDirectory: String?` to NewProjectSheet
- Add "Select Source Folder" button below Tags section using NSOpenPanel
- Configure NSOpenPanel for directory selection (canChooseFiles=false, canChooseDirectories=true)
- Display selected path or "None" in UI
- Add "Clear" button when source directory is set
- Pass sourceDirectory to viewModel.createProject in saveProject method

**Done when:**
- NewProjectSheet displays source directory picker
- Clicking "Select Source Folder" opens NSOpenPanel
- Selecting directory updates UI and internal state
- Clear button removes source directory selection
- Creating project passes sourceDirectory to ViewModel

## S006: Create EditProjectSheet view

**Intent:** Provide UI for editing existing projects.

**Work:**
- Create `Sources/Hieroglyphs/Views/Sidebar/EditProjectSheet.swift`
- Mirror NewProjectSheet structure with NavigationStack and Form
- Add `let project: Project` initializer parameter
- Pre-populate @State fields from project (title, description, tags, sourceDirectory)
- Include same directory picker as NewProjectSheet
- Call viewModel.updateProject on save
- Dismiss sheet on save or cancel

**Done when:**
- EditProjectSheet file exists and compiles
- Sheet displays pre-populated fields from project
- Directory picker works identically to NewProjectSheet
- Save button calls viewModel.updateProject with edited values
- Sheet dismisses after save or cancel

## S007: Add context menu to SidebarProjectEntry

**Intent:** Provide access to EditProjectSheet from Sidebar.

**Work:**
- Add `.contextMenu` modifier to SidebarProjectEntry body
- Add "Edit Project" menu item with pencil.circle icon
- Add `@State private var showingEditSheet = false` to SidebarProjectEntry
- Add `.sheet(isPresented:)` modifier presenting EditProjectSheet
- Pass current project to EditProjectSheet

**Done when:**
- Right-clicking project in Sidebar shows context menu
- "Edit Project" option appears in context menu
- Clicking "Edit Project" presents EditProjectSheet
- EditProjectSheet displays with current project data

## S008: Update ViewModel.createProject signature

**Intent:** Thread sourceDirectory parameter through ViewModel layer.

**Work:**
- Add `sourceDirectory: String?` parameter to HieroglyphsVM.createProject method
- Pass sourceDirectory to workspaceService.createProject
- Ensure project list refreshes after creation

**Done when:**
- ViewModel.createProject accepts sourceDirectory parameter
- Parameter is passed to WorkspaceService
- Project creation with source directory succeeds end-to-end

## S009: Add ViewModel.updateProject method

**Intent:** Provide ViewModel method for updating existing projects.

**Work:**
- Add `updateProject(_:)` method to HieroglyphsVM accepting updated Project
- Call workspaceService.updateProject with project and workspacePath
- Refresh projects list after update
- Update selectedProject if it matches the updated project
- Handle errors by logging to console

**Done when:**
- ViewModel.updateProject method exists
- Calling updateProject persists changes to disk
- Project list refreshes showing updated values
- Selection state remains consistent after update

## S010: Write tests for source_directory handling

**Intent:** Verify source_directory field works correctly in all scenarios.

**Work:**
- Add test for creating project with sourceDirectory non-nil
- Add test for creating project with sourceDirectory nil
- Add test for loading project with source_directory in frontmatter
- Add test for loading project without source_directory in frontmatter
- Add test for updating project to add sourceDirectory
- Add test for updating project to remove sourceDirectory
- Add test for round-tripping unknown fields with source_directory

**Done when:**
- All new tests pass
- Tests cover create, read, and update operations
- Tests verify nil handling and unknown field preservation

## S011: Update documentation

**Intent:** Reconcile docs with code changes per L14-L16.

**Work:**
- Update `.ushabti/docs/models.md` to document sourceDirectory field
- Update `.ushabti/docs/workspace-service.md` to document source_directory frontmatter handling
- Update `.ushabti/docs/views-ui.md` to document EditProjectSheet

**Done when:**
- models.md includes sourceDirectory field documentation
- workspace-service.md describes source_directory serialization
- views-ui.md describes EditProjectSheet structure and behavior
