# Steps: Phase 0003

## S001: Define WorkspaceProviding Protocol

**Intent:** Establish the service interface that defines how workspace data is loaded from disk.

**Work:**
- Create `Sources/Hieroglyphs/Services/WorkspaceProviding.swift`
- Define protocol with three methods:
  - `loadWorkspaceConfig() throws -> WorkspaceConfig`
  - `loadProjects(from workspacePath: String) throws -> [Project]`
  - `loadCards(from projectPath: String, for project: Project) throws -> [Card]`
- Add documentation comments explaining each method's purpose and error conditions

**Done when:**
- File exists at correct path with protocol definition
- All three methods declared with correct signatures
- `swift build` succeeds

---

## S002: Create WorkspaceService Implementation Scaffold

**Intent:** Create the concrete service type that will implement the protocol.

**Work:**
- Create `Sources/Hieroglyphs/Services/WorkspaceService.swift`
- Define `WorkspaceService` class conforming to `WorkspaceProviding`
- Stub out all three protocol methods with `fatalError("Not implemented")`
- Add dependency on `FileManager` (injected or default)

**Done when:**
- File exists with class declaration
- Class conforms to `WorkspaceProviding`
- All protocol methods stubbed
- `swift build` succeeds

---

## S003: Implement loadWorkspaceConfig()

**Intent:** Read and parse `~/.hieroglyphs/config.yaml` to determine workspace path.

**Work:**
- Expand home directory (`~`) to absolute path
- Read file contents using `FileManager`
- Parse YAML using Yams
- Map to `WorkspaceConfig` model
- Throw descriptive errors if file missing or parse fails

**Done when:**
- Method reads from `~/.hieroglyphs/config.yaml`
- Returns `WorkspaceConfig` instance on success
- Throws appropriate error on failure
- `swift build` succeeds

---

## S004: Implement loadProjects() - Directory Scanning

**Intent:** Discover all project folders in the workspace directory.

**Work:**
- Use `FileManager.contentsOfDirectory(at:includingPropertiesForKeys:)` to list workspace subdirectories
- Filter for directories (not files)
- Filter for directories containing `project.md`
- Return list of project directory URLs

**Done when:**
- Method scans workspace directory
- Returns only directories containing `project.md`
- Skips files and directories without `project.md`
- `swift build` succeeds

---

## S005: Implement loadProjects() - File Parsing

**Intent:** Parse each `project.md` file and map frontmatter to `Project` model.

**Work:**
- Read `project.md` file contents using `String(contentsOf:)`
- Parse with `FrontmatterParser.parse()`
- Extract frontmatter fields: `id`, `title`, `description`, `tags`, `created`, `updated`
- Parse ISO8601 date strings to `Date` objects
- Extract slug from directory name (not frontmatter)
- Construct `Project` instance
- Handle parse errors gracefully: log and skip file

**Done when:**
- Method parses frontmatter and maps to `Project` fields
- Uses ISO8601DateFormatter for date parsing
- Extracts slug from directory name
- Skips unparseable files with error logging
- Returns array of `Project` instances
- `swift build` succeeds

---

## S006: Implement loadCards() - Directory Scanning

**Intent:** Discover all card folders in a project's `cards/` subdirectory.

**Work:**
- Construct path to `cards/` subdirectory within project path
- Check if `cards/` directory exists
- Use `FileManager.contentsOfDirectory(at:includingPropertiesForKeys:)` to list card folders
- Filter for directories (not files)
- Filter for directories containing `card.md`
- Return list of card directory URLs

**Done when:**
- Method scans `cards/` subdirectory of project
- Returns only directories containing `card.md`
- Returns empty array if `cards/` directory missing
- `swift build` succeeds

---

## S007: Implement loadCards() - File Parsing

**Intent:** Parse each `card.md` file and map frontmatter to `Card` model.

**Work:**
- Read `card.md` file contents using `String(contentsOf:)`
- Parse with `FrontmatterParser.parse()`
- Extract frontmatter fields: `id`, `title`, `type`, `status`, `priority`, `tags`, `created`, `updated`
- Parse ISO8601 date strings to `Date` objects
- Parse enum fields (`type`, `status`, `priority`) from raw strings
- Extract slug from directory name (not frontmatter)
- Extract body from parser result
- Construct `Card` instance
- Handle parse errors gracefully: log and skip file

**Done when:**
- Method parses frontmatter and maps to `Card` fields
- Uses ISO8601DateFormatter for date parsing
- Parses enums from rawValue strings
- Extracts slug from directory name
- Body content included in `Card` instance
- Skips unparseable files with error logging
- Returns array of `Card` instances
- `swift build` succeeds

---

## S008: Add Error Handling and Logging

**Intent:** Ensure service handles errors gracefully and provides useful diagnostics.

**Work:**
- Define custom error types for service (e.g., `WorkspaceError.configNotFound`, `WorkspaceError.invalidDirectory`)
- Add logging statements for skipped files or parsing failures
- Use `print()` for logging (structured logging deferred to future phase)
- Ensure no method crashes on malformed input

**Done when:**
- Custom error types defined
- Logging added for parse failures and skipped files
- Service never crashes on bad input
- `swift build` succeeds

---

## S009: Create Test Fixture Workspace Structure

**Intent:** Build a fixture workspace directory on disk for testing.

**Work:**
- In test file, create helper method `createFixtureWorkspace(at:)` that builds:
  - Workspace root directory
  - `~/.hieroglyphs/config.yaml` pointing to fixture workspace
  - One project directory with `project.md` and `cards/` subdirectory
  - Two card directories inside `cards/` with `card.md` files
- Use `FileManager` to create directories and write files
- Create helper method `cleanupFixture(at:)` to remove fixture after test

**Done when:**
- Test helper methods exist
- Fixture creates valid workspace structure on disk
- Cleanup helper removes fixture
- `swift test` runs (may fail until tests implemented)

---

## S010: Test loadWorkspaceConfig()

**Intent:** Verify config file loading and parsing.

**Work:**
- Write test that creates `~/.hieroglyphs/config.yaml` fixture
- Call `loadWorkspaceConfig()`
- Assert returned `WorkspaceConfig` has expected `workspacePath`
- Test error case: missing config file

**Done when:**
- Test exists and passes
- Both success and failure cases covered
- `swift test` passes for this test

---

## S011: Test loadProjects() - Discovery

**Intent:** Verify project directory scanning.

**Work:**
- Write test that creates fixture workspace with multiple project folders
- Call `loadProjects(from:)` with fixture workspace path
- Assert correct number of projects returned
- Assert projects have expected titles and slugs
- Test edge case: workspace with no projects

**Done when:**
- Test exists and passes
- Multiple projects discovered correctly
- Empty workspace handled gracefully
- `swift test` passes for this test

---

## S012: Test loadProjects() - Parsing

**Intent:** Verify project frontmatter parsing and model mapping.

**Work:**
- Write test that creates fixture `project.md` with complete frontmatter
- Call `loadProjects(from:)`
- Assert `Project` instance has all fields correctly populated
- Assert dates parsed correctly
- Assert tags array populated
- Test edge case: project with malformed frontmatter (should skip)

**Done when:**
- Test exists and passes
- All `Project` fields verified
- Malformed file skipped gracefully
- `swift test` passes for this test

---

## S013: Test loadCards() - Discovery

**Intent:** Verify card directory scanning within projects.

**Work:**
- Write test that creates fixture project with `cards/` subdirectory containing multiple card folders
- Call `loadCards(from:for:)` with project path
- Assert correct number of cards returned
- Assert cards have expected titles and slugs
- Test edge case: project with no `cards/` directory

**Done when:**
- Test exists and passes
- Multiple cards discovered correctly
- Missing `cards/` directory handled gracefully
- `swift test` passes for this test

---

## S014: Test loadCards() - Parsing

**Intent:** Verify card frontmatter parsing and model mapping.

**Work:**
- Write test that creates fixture `card.md` with complete frontmatter and body
- Call `loadCards(from:for:)`
- Assert `Card` instance has all fields correctly populated
- Assert enums parsed from rawValue strings
- Assert body content preserved
- Assert dates parsed correctly
- Test edge case: card with malformed frontmatter (should skip)

**Done when:**
- Test exists and passes
- All `Card` fields verified including body
- Enums parsed correctly
- Malformed file skipped gracefully
- `swift test` passes for this test

---

## S015: Test Error Handling and Edge Cases

**Intent:** Verify robust error handling across all service methods.

**Work:**
- Test missing workspace directory
- Test workspace directory with no permissions
- Test project with missing `project.md`
- Test card with missing `card.md`
- Test files with invalid YAML
- Test files with missing required frontmatter fields
- Assert service returns empty arrays or skips files rather than crashing

**Done when:**
- All error cases tested
- Service never crashes on malformed input
- `swift test` passes for all error tests

---

## S016: Verify All Tests Pass

**Intent:** Ensure complete test coverage and green build.

**Work:**
- Run `swift test` and verify all tests pass
- Run `swift build` and verify no errors or warnings
- Review test coverage to ensure all public protocol methods tested

**Done when:**
- `swift test` completes with 100% pass rate
- `swift build` completes with zero errors and zero warnings
- All acceptance criteria verified
