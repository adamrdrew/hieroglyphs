# Phase 0004: Workspace Service (Write)

## Intent

Extend WorkspaceService with write operations to create, update, and delete projects and cards on disk. The service gains the ability to create slugified directories with markdown files containing YAML frontmatter, update existing files while preserving unknown frontmatter fields, delete items by moving them to Trash using NSFileManager.trashItem, and initialize workspace configuration files.

This phase completes the workspace service contract, enabling the app to both read from and write to the filesystem. It honors L01 (filesystem as truth) and L08 (frontmatter as tag source of truth) while ensuring L02 (laissez-faire on read, opinionated on write) through preservation of unknown frontmatter fields.

## Scope

**In scope:**
- Extend `WorkspaceProviding` protocol with write operation methods
- `createWorkspace(at:)` — Create workspace directory structure and config.yaml
- `initializeWorkspaceFiles(at:)` — Generate stub CLAUDE.md and AGENT.md in workspace root
- `createProject(title:description:tags:at:)` — Create slugified project folder with project.md
- `createCard(title:type:status:priority:tags:body:projectPath:)` — Create slugified card folder with card.md
- `updateProject(_:at:)` — Update project.md, preserving unknown frontmatter fields
- `updateCard(_:projectPath:)` — Update card.md, preserving unknown frontmatter fields
- `deleteProject(at:)` — Move project folder to Trash via NSFileManager.trashItem
- `deleteCard(slug:projectPath:)` — Move card folder to Trash via NSFileManager.trashItem
- Use `FrontmatterParser.serialize` for writing frontmatter + body to markdown files
- Use `SlugGenerator.generateSlug` for creating filesystem-safe directory names
- Update timestamps (created/updated) when creating and updating
- Preserve unknown frontmatter fields when updating (use round-trip parse + merge)
- Comprehensive test coverage using fixture workspaces in temp directory

**Out of scope:**
- File watching or change detection (Phase 5+)
- Tag reconciliation with extended attributes (Phase 5+)
- UI integration or ViewModel wiring (Phase 6+)
- Conflict resolution or merge strategies for concurrent edits
- Validation of frontmatter values (UI responsibility)
- Undo/redo mechanisms

## Constraints

**Laws:**
- L01 — Filesystem as Source of Truth: All state changes write directly to disk
- L02 — Opinionated on Write, Laissez-Faire on Read: UI provides structured options, preserve unknown fields on update
- L05 — External Changes Are First-Class: Writing must be atomic and safe for concurrent access
- L06 — Platform Leverage Over Reinvention: Use NSFileManager.trashItem for deletion
- L08 — Frontmatter Is Tag Source of Truth: Tags written to frontmatter only (extended attributes deferred)
- L09 — Sandi Metz Principles: Protocol-based service, small focused methods, dependency injection
- L11 — Test Coverage: All public protocol methods must have tests

**Style:**
- Protocol methods added to `WorkspaceProviding.swift`
- Implementation added to `WorkspaceService.swift`
- Error handling follows "do your best" philosophy (throw on critical failures, log on recoverable issues)
- Tests use fixture workspaces on disk (per L01)
- One primary responsibility per method
- Clear naming (clarity over brevity)

## Acceptance Criteria

1. `WorkspaceProviding` protocol extended with write operation method signatures
2. `createWorkspace(at:)` creates workspace directory and writes config.yaml with workspace path
3. `initializeWorkspaceFiles(at:)` creates stub CLAUDE.md and AGENT.md in workspace root
4. `createProject(title:description:tags:at:)` creates slugified folder and project.md with frontmatter
5. `createCard(title:type:status:priority:tags:body:projectPath:)` creates slugified folder and card.md with frontmatter
6. `updateProject(_:at:)` updates project.md, preserving unknown frontmatter fields from existing file
7. `updateCard(_:projectPath:)` updates card.md, preserving unknown frontmatter fields from existing file
8. `deleteProject(at:)` moves project folder to Trash using NSFileManager.trashItem
9. `deleteCard(slug:projectPath:)` moves card folder to Trash using NSFileManager.trashItem
10. Created timestamps set to current date when creating new items
11. Updated timestamps set to current date when creating or updating items
12. Slugs generated from titles using `SlugGenerator.generateSlug`
13. Frontmatter serialized using `FrontmatterParser.serialize`
14. All write operations are atomic (write to temp file, then move)
15. All public protocol methods have corresponding tests
16. Tests verify creation, update, deletion, preservation of unknown fields, and error handling
17. `swift test` passes with 100% success (all existing + new tests)
18. `swift build` completes without errors or warnings

## Risks / Notes

**Atomic writes:** File writing uses atomic operations (write to temp file, then move) to prevent corruption if write is interrupted. FileManager.createDirectory and String.write both support atomic options.

**Unknown field preservation:** When updating, the service reads the existing file, parses frontmatter, merges known fields from the updated model, preserves unknown fields, then serializes back to disk. This honors L02.

**Date handling:** Dates serialized to frontmatter as ISO8601 strings. ISO8601DateFormatter used for formatting. Created timestamp set once on creation. Updated timestamp set on both creation and update.

**Trash vs permanent delete:** Per L06, deletion uses NSFileManager.trashItem (moves to Trash) rather than permanent removal. This provides user safety and aligns with macOS conventions.

**Slug uniqueness:** The service does not enforce slug uniqueness. If two projects have the same title (and thus same slug), the second write will fail. This is intentional — slug collisions are user errors, not service errors. Future phases may add validation in the UI layer.

**Config.yaml location:** Config lives at `~/.hieroglyphs/config.yaml` (user home directory, not workspace). `createWorkspace` writes this config file with the workspace path.

**Stub files:** CLAUDE.md and AGENT.md are placeholder files generated during workspace initialization to provide guidance to users and LLMs. Content is minimal and instructional. These are created only when initializing a new workspace.

**Error conditions:**
- Write fails if directory already exists (project/card creation)
- Update fails if file does not exist
- Delete fails if item not found
- Throw on critical failures, return successfully on no-ops (e.g., deleting non-existent item logs but doesn't throw)

**Test strategy:** Tests use temp directories created in test setup, cleaned up in teardown. Verify files written to disk, verify content correctness, verify preservation of unknown fields, verify atomic behavior.
