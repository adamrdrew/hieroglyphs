# Phase 0014: Project Source Directory Field and Edit Capability

## Intent

Add an optional `sourceDirectory` field to the Project model and enable editing of existing projects. This field will store the absolute path to a project's source code directory, specifically its `.ushabti/phases/` directory, enabling future phases to integrate Hieroglyphs with Ushabti-managed codebases.

This Phase also addresses the missing capability to edit existing projects after creation, which is a fundamental gap in the current UI.

## Scope

**In Scope:**
- Add `sourceDirectory: String?` field to Project model
- Update WorkspaceService to read/write `source_directory` from/to frontmatter
- Add NSOpenPanel-based directory picker to NewProjectSheet for source folder selection
- Create EditProjectSheet view mirroring NewProjectSheet but pre-populated with existing values
- Add context menu to SidebarProjectEntry with "Edit Project" option
- Use existing WorkspaceService.updateProject method for saves
- Gracefully handle existing project.md files lacking `source_directory` field (default to nil)

**Out of Scope:**
- Validation of source directory contents (whether it contains `.ushabti/phases/`)
- Auto-detection or inference of source directories
- UI for browsing phase directories within the source
- Integration with Ushabti phase workflows (reserved for future phases)
- Renaming projects or handling slug changes

## Constraints

**Laws:**
- L02 (Opinionated on Write, Laissez-Faire on Read) — Existing projects without `source_directory` must load without error
- L09 (Sandi Metz Principles) — Small, focused components; protocol-based services
- L10 (Design Language Consistency with TakeNote) — EditProjectSheet mirrors NewProjectSheet patterns

**Style:**
- Use NSOpenPanel for directory selection (no SwiftUI equivalent)
- Follow existing patterns in NewProjectSheet for form layout and validation
- Keep EditProjectSheet composable and focused (single responsibility)

## Acceptance Criteria

1. Project model includes optional `sourceDirectory: String?` field
2. WorkspaceService.parseProject reads `source_directory` from frontmatter, defaulting to nil if absent
3. WorkspaceService.createProject writes `source_directory` to frontmatter when non-nil
4. WorkspaceService.updateProject writes `source_directory` to frontmatter when non-nil, preserving unknown fields
5. NewProjectSheet includes "Select Source Folder" button with NSOpenPanel that sets optional source directory
6. Creating a project without selecting a source folder omits `source_directory` from frontmatter
7. Existing projects without `source_directory` load successfully
8. Right-clicking a project in Sidebar shows "Edit Project" context menu option
9. EditProjectSheet displays pre-populated fields (title, description, tags, source directory if set)
10. EditProjectSheet allows changing all fields including adding/removing source directory
11. Saving EditProjectSheet calls WorkspaceService.updateProject and refreshes project list
12. All tests pass and new tests cover `source_directory` handling

## Risks / Notes

**Deferred Work:**
- Source directory validation (checking for `.ushabti/` structure) is intentionally omitted. The field stores an arbitrary path. Future phases will validate or use the path as needed.
- Slug changes and project renaming are not in scope. Slug remains immutable after creation.

**Known Tradeoffs:**
- Storing absolute paths may cause portability issues if workspace is moved. Future phases may address relative path resolution if needed.
