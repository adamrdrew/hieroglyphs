# Review for Phase 0014

## Status

Status: GREEN

## Findings

### Acceptance Criteria Verification

All 12 acceptance criteria have been verified as met:

1. **Project model includes optional `sourceDirectory: String?` field** — VERIFIED. Field added at line 12 of Project.swift.

2. **WorkspaceService.parseProject reads `source_directory` from frontmatter, defaulting to nil if absent** — VERIFIED. Line 152 reads field, passes to Project initializer. Test coverage confirms nil default behavior.

3. **WorkspaceService.createProject writes `source_directory` to frontmatter when non-nil** — VERIFIED. Lines 418-420 conditionally include field in frontmatter dictionary. Test confirms field written when present, omitted when nil.

4. **WorkspaceService.updateProject writes `source_directory` to frontmatter when non-nil, preserving unknown fields** — VERIFIED. Lines 549-553 write field when non-nil, remove when nil. Test confirms unknown field preservation.

5. **NewProjectSheet includes "Select Source Folder" button with NSOpenPanel that sets optional source directory** — VERIFIED. Lines 30-56 implement Source Directory section with picker UI. Lines 94-107 implement NSOpenPanel integration.

6. **Creating a project without selecting a source folder omits `source_directory` from frontmatter** — VERIFIED. Test `testCreateProjectWithoutSourceDirectory` confirms field is omitted when nil.

7. **Existing projects without `source_directory` load successfully** — VERIFIED. Test `testLoadProjectWithoutSourceDirectory` confirms nil default handling per L02.

8. **Right-clicking a project in Sidebar shows "Edit Project" context menu option** — VERIFIED. Lines 31-37 of SidebarProjectEntry.swift implement contextMenu with "Edit Project" option.

9. **EditProjectSheet displays pre-populated fields (title, description, tags, source directory if set)** — VERIFIED. Lines 75-87 implement `populateFields()` method called in `.onAppear`. All fields including sourceDirectory are populated.

10. **EditProjectSheet allows changing all fields including adding/removing source directory** — VERIFIED. Directory picker identical to NewProjectSheet. Clear button present when sourceDirectory is set. Save logic handles nil and non-nil values.

11. **Saving EditProjectSheet calls WorkspaceService.updateProject and refreshes project list** — VERIFIED. Line 107 calls `viewModel.updateProject()`. ViewModel implementation (lines 131-149 of HieroglyphsVM.swift) calls WorkspaceService, reloads projects, and updates selection state.

12. **All tests pass and new tests cover `source_directory` handling** — VERIFIED. All 157 tests pass (0 failures). Seven new tests added covering create with/without sourceDirectory, load with/without sourceDirectory, update to add/remove sourceDirectory, and preservation with unknown fields.

### Law Compliance

**L02 (Opinionated on Write, Laissez-Faire on Read)** — COMPLIANT. Existing projects without `source_directory` load successfully with nil default. Unknown fields are preserved during updates. Test `testUpdateProjectPreservesSourceDirectoryWithUnknownFields` explicitly verifies this behavior.

**L09 (Sandi Metz Principles)** — COMPLIANT. EditProjectSheet is focused and composable (127 lines including whitespace). Mirrors NewProjectSheet structure. Protocol-based service injection maintained throughout.

**L10 (Design Language Consistency with TakeNote)** — COMPLIANT. EditProjectSheet mirrors NewProjectSheet layout patterns. Uses Form with Sections, NavigationStack, toolbar buttons, and NSOpenPanel for directory selection (consistent with WelcomeView). Source directory picker UI is identical between NewProjectSheet and EditProjectSheet.

**All other laws** — No violations detected.

### Style Compliance

**Small, focused components** — EditProjectSheet is 127 lines, NewProjectSheet is 109 lines. Both components are within acceptable bounds with clear single responsibility.

**No regex** — Confirmed. No regex usage introduced.

**Protocol-based services** — WorkspaceProviding protocol signature updated correctly. All service calls use protocol, not concrete type.

**Naming** — All names are clear and descriptive. `sourceDirectory` follows Swift naming conventions. Frontmatter field `source_directory` uses snake_case per workspace data conventions.

**Composition over inheritance** — EditProjectSheet and NewProjectSheet are independent structs sharing patterns, not inheritance hierarchy.

**Sandi Metz guidelines** — Methods are short and focused. Parameters are limited. Classes/structs are small. Rules followed with good judgment.

**No dead code** — All touched files contain only active code. No commented-out blocks. No unused imports.

### Test Coverage

Seven new tests added to WorkspaceServiceTests.swift:

1. `testCreateProjectWithSourceDirectory` — Creates project with sourceDirectory, verifies field in model and frontmatter
2. `testCreateProjectWithoutSourceDirectory` — Creates project without sourceDirectory, verifies nil and field omitted from frontmatter
3. `testLoadProjectWithSourceDirectory` — Loads project with source_directory in frontmatter, verifies field parsed
4. `testLoadProjectWithoutSourceDirectory` — Loads project without source_directory, verifies nil default per L02
5. `testUpdateProjectToAddSourceDirectory` — Updates project from nil to non-nil sourceDirectory, verifies field written
6. `testUpdateProjectToRemoveSourceDirectory` — Updates project from non-nil to nil sourceDirectory, verifies field removed
7. `testUpdateProjectPreservesSourceDirectoryWithUnknownFields` — Updates project with sourceDirectory and custom_field, verifies both updated field and unknown field preserved

All tests pass. Coverage includes create, read, and update operations. Round-trip preservation verified per L02.

Existing Project initializations throughout test suite updated to include `sourceDirectory: nil` parameter (23 locations total). All tests continue to pass.

### Documentation Reconciliation

Documentation fully reconciled per L14-L16:

**models.md** — Updated with sourceDirectory field documentation (lines 36-37). Example frontmatter added showing source_directory (lines 47-64). Note added explaining field is optional and only appears when set.

**workspace-service.md** — Updated createProject signature to include sourceDirectory parameter (lines 201-212). Behavior section documents conditional inclusion in frontmatter (line 225). Updated updateProject documentation to describe source_directory write/remove logic (lines 287-292).

**views-ui.md** — EditProjectSheet documented as new view (lines 392-516). NewProjectSheet documentation updated to include source directory picker (lines 599-658). SidebarProjectEntry context menu documented (lines 371-390).

All documentation changes are accurate and complete. No stale references detected.

### Code Quality

**EditProjectSheet implementation** — Clean implementation mirroring NewProjectSheet patterns. Directory picker UI matches exactly. Save logic correctly creates new Project instance preserving immutable fields (id, created, slug) while updating editable fields. No validation beyond non-empty title (consistent with NewProjectSheet).

**WorkspaceService changes** — Minimal, focused changes. createProject conditionally adds field to frontmatter dictionary only when non-nil. updateProject writes field when non-nil, removes when nil. parseProject reads field with nil default. All changes follow existing patterns.

**ViewModel changes** — createProject method signature updated with default parameter value `sourceDirectory: String? = nil`. updateProject method added with proper error handling and state refresh logic. Selection state correctly updated after project update.

**Test implementation** — Tests follow existing patterns. Use helper method `createProject` updated to support sourceDirectory parameter. Verify both model state and serialized frontmatter. Cover all execution paths.

### Build and Lint

`swift build` succeeds with no errors or warnings.

`swift test` executes 157 tests with 0 failures.

No lint violations detected in touched files.

### Completeness

All 11 steps marked implemented and verified:

- S001-S004: Model and service changes complete and tested
- S005-S007: UI changes complete and functional
- S008-S009: ViewModel integration complete
- S010: Comprehensive test coverage added
- S011: Documentation fully reconciled

No deferred work. No missing functionality. No scope creep detected.

### Behavior Verification

Manual verification of UI behavior confirmed:

- Creating project without selecting source directory omits field from project.md
- Creating project with source directory writes source_directory to project.md
- Right-clicking project shows "Edit Project" context menu
- EditProjectSheet pre-populates all fields including sourceDirectory
- Adding source directory via EditProjectSheet writes source_directory to project.md
- Clearing source directory via EditProjectSheet removes source_directory from project.md
- Unknown frontmatter fields preserved during updates
- Project list refreshes after edit
- Selection state remains consistent after edit

All behavior matches acceptance criteria and design intent.

## Verdict

Phase 0014 is GREEN.

All acceptance criteria met. All laws complied with. Style followed throughout. Tests comprehensive and passing. Documentation reconciled. No defects detected. Implementation is correct, complete, and ready for production.

The phase successfully adds optional sourceDirectory field to Project model, implements directory picker in NewProjectSheet, creates EditProjectSheet view for editing existing projects, integrates context menu for project editing, and provides full test coverage. Unknown field preservation (L02) is maintained. Design consistency with TakeNote (L10) is upheld. Sandi Metz principles (L09) are followed.

This phase is weighed and found true.
