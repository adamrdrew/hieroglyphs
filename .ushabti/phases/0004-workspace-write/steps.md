# Steps for Phase 0004

## S001 — Extend WorkspaceProviding Protocol

**Intent:** Define protocol interface for write operations.

**Work:** Add method signatures to `WorkspaceProviding.swift` for workspace creation, project creation, card creation, updates, and deletions. Include documentation comments for each method specifying parameters, return values, and error conditions.

**Done when:** Protocol includes all write operation signatures with clear documentation.

---

## S002 — Implement createWorkspace

**Intent:** Create workspace directory structure and config.yaml.

**Work:** Add `createWorkspace(at:)` method to `WorkspaceService`. Create workspace directory at specified path. Create `~/.hieroglyphs/` directory if needed. Write `config.yaml` with workspace path using Yams YAMLEncoder.

**Done when:** Method creates workspace directory and config file. Returns successfully or throws on failure.

---

## S003 — Implement initializeWorkspaceFiles

**Intent:** Generate stub CLAUDE.md and AGENT.md in workspace root.

**Work:** Add `initializeWorkspaceFiles(at:)` method to `WorkspaceService`. Write minimal instructional content to `CLAUDE.md` (project overview and collaboration guidelines) and `AGENT.md` (agent-specific workspace instructions). Content should be concise and actionable.

**Done when:** Method creates both stub files with instructional content in workspace root directory.

---

## S004 — Implement createProject

**Intent:** Create new project with slugified directory and frontmatter.

**Work:** Add `createProject(title:description:tags:at:)` method to `WorkspaceService`. Generate slug from title using `SlugGenerator`. Create project directory at `workspacePath/slug/`. Generate UUID for project ID. Set created and updated timestamps to current date. Serialize frontmatter and empty body using `FrontmatterParser.serialize`. Write project.md atomically.

**Done when:** Method creates project directory and project.md with correct frontmatter. Returns created Project model.

---

## S005 — Implement createCard

**Intent:** Create new card with slugified directory and frontmatter.

**Work:** Add `createCard(title:type:status:priority:tags:body:projectPath:)` method to `WorkspaceService`. Generate slug from title using `SlugGenerator`. Create cards directory if needed at `projectPath/cards/`. Create card directory at `projectPath/cards/slug/`. Generate UUID for card ID. Set created and updated timestamps to current date. Serialize frontmatter and body using `FrontmatterParser.serialize`. Write card.md atomically.

**Done when:** Method creates card directory and card.md with correct frontmatter and body. Returns created Card model.

---

## S006 — Implement updateProject

**Intent:** Update existing project while preserving unknown frontmatter fields.

**Work:** Add `updateProject(_:at:)` method to `WorkspaceService`. Read existing project.md. Parse frontmatter using `FrontmatterParser.parse`. Merge known fields from updated Project model into frontmatter dictionary, preserving unknown fields. Update `updated` timestamp to current date. Serialize merged frontmatter and body. Write atomically.

**Done when:** Method updates project.md with new values, preserves unknown fields, updates timestamp. Returns successfully or throws if project not found.

---

## S007 — Implement updateCard

**Intent:** Update existing card while preserving unknown frontmatter fields.

**Work:** Add `updateCard(_:projectPath:)` method to `WorkspaceService`. Read existing card.md from `projectPath/cards/{slug}/card.md`. Parse frontmatter using `FrontmatterParser.parse`. Merge known fields from updated Card model into frontmatter dictionary, preserving unknown fields. Update `updated` timestamp to current date. Serialize merged frontmatter and body. Write atomically.

**Done when:** Method updates card.md with new values, preserves unknown fields, updates timestamp. Returns successfully or throws if card not found.

---

## S008 — Implement deleteProject

**Intent:** Move project folder to Trash safely.

**Work:** Add `deleteProject(at:)` method to `WorkspaceService`. Verify project directory exists. Use `fileManager.trashItem(at:resultingItemURL:)` to move project folder to Trash. Throw error if item not found or trash operation fails.

**Done when:** Method moves project directory to Trash using NSFileManager API. Returns successfully or throws on failure.

---

## S009 — Implement deleteCard

**Intent:** Move card folder to Trash safely.

**Work:** Add `deleteCard(slug:projectPath:)` method to `WorkspaceService`. Build path to card directory at `projectPath/cards/{slug}/`. Verify card directory exists. Use `fileManager.trashItem(at:resultingItemURL:)` to move card folder to Trash. Throw error if item not found or trash operation fails.

**Done when:** Method moves card directory to Trash using NSFileManager API. Returns successfully or throws on failure.

---

## S010 — Add Date Formatting Helpers

**Intent:** Centralize ISO8601 date formatting for frontmatter serialization.

**Work:** Add private helper methods to `WorkspaceService` for formatting dates to ISO8601 strings and parsing from ISO8601 strings. Use ISO8601DateFormatter. These helpers used in create and update operations.

**Done when:** Helper methods exist for date formatting/parsing. Used consistently across create and update operations.

---

## S011 — Test createWorkspace and initializeWorkspaceFiles

**Intent:** Verify workspace initialization creates correct structure and files.

**Work:** Add tests to `WorkspaceServiceTests` for workspace creation. Verify workspace directory created. Verify config.yaml exists and contains correct workspace path. Verify CLAUDE.md and AGENT.md created with non-empty content. Test error handling for invalid paths.

**Done when:** Tests verify workspace creation, config writing, and stub file generation. All tests pass.

---

## S012 — Test createProject

**Intent:** Verify project creation produces correct directory and file structure.

**Work:** Add tests to `WorkspaceServiceTests` for project creation. Verify project directory created with slugified name. Verify project.md exists with correct frontmatter fields (id, title, description, tags, created, updated, slug). Verify slug matches directory name. Test error handling for duplicate projects.

**Done when:** Tests verify project creation, frontmatter correctness, and error handling. All tests pass.

---

## S013 — Test createCard

**Intent:** Verify card creation produces correct directory and file structure.

**Work:** Add tests to `WorkspaceServiceTests` for card creation. Verify cards directory created if needed. Verify card directory created with slugified name. Verify card.md exists with correct frontmatter fields (id, title, type, status, priority, tags, created, updated, slug) and body content. Test error handling for duplicate cards.

**Done when:** Tests verify card creation, frontmatter correctness, body content, and error handling. All tests pass.

---

## S014 — Test updateProject and updateCard

**Intent:** Verify updates preserve unknown frontmatter fields and update timestamps.

**Work:** Add tests to `WorkspaceServiceTests` for update operations. Create project/card with known and unknown frontmatter fields. Update known fields. Parse updated file. Verify known fields changed, unknown fields preserved, updated timestamp changed, created timestamp unchanged. Test error handling for non-existent items.

**Done when:** Tests verify field updates, preservation of unknown fields, timestamp updates, and error handling. All tests pass.

---

## S015 — Test deleteProject and deleteCard

**Intent:** Verify deletion moves items to Trash rather than permanent deletion.

**Work:** Add tests to `WorkspaceServiceTests` for delete operations. Create project/card. Delete item. Verify item no longer exists at original path. Verify trash operation succeeded (check return value). Test error handling for non-existent items.

**Done when:** Tests verify deletion via Trash API. All tests pass.

---

## S016 — Verify Build and Test Suite

**Intent:** Ensure all code builds cleanly and tests pass.

**Work:** Run `swift build` and verify no errors or warnings. Run `swift test` and verify all tests pass (existing 55 + new write operation tests). Check test coverage for all new public methods.

**Done when:** Build completes with zero errors/warnings. All tests pass. Coverage verified for all write operation methods.
