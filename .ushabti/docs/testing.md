# Testing Strategy

## Overview

Hieroglyphs follows strict test coverage requirements per L11 (Test Coverage): every public API method must have tests, and all tests must pass for a phase to be marked GREEN.

**Location:** `Tests/HieroglyphsTests/`

**Framework:** XCTest

**Strategy:** Unit tests for models, utilities, services, and ViewModel. Views are not unit tested (tested manually or via future UI tests).

## Test Coverage Requirements (L11)

### What Must Be Tested

1. **All Public Methods:** Every public method in every module must have at least one test
2. **All Execution Paths:** Tests must cover all execution paths through public methods (success, failure, edge cases)
3. **Private Methods:** Tested implicitly through public API (no direct tests)
4. **Views:** Not unit tested (SwiftUI views lack meaningful testable API)

### Coverage Gate

- Tests and lint must pass for every phase
- Overseer cannot mark a phase GREEN if tests fail or lint violations exist
- L11 is an absolute requirement

## Test Organization

```
Tests/HieroglyphsTests/
├── ModelTests.swift                  # Tests for all model types
├── FrontmatterParserTests.swift      # Tests for FrontmatterParser
├── SlugGeneratorTests.swift          # Tests for SlugGenerator
├── WorkspaceServiceTests.swift       # Tests for WorkspaceService
├── TagReconcilerServiceTests.swift   # Tests for TagReconcilerService
├── SpotlightServiceTests.swift       # Tests for SpotlightService
└── HieroglyphsVMTests.swift          # Tests for HieroglyphsVM
```

**Organization:** One test file per module or logical grouping. Test file names match source file names with `Tests` suffix.

## ModelTests.swift

**Purpose:** Test model encoding, decoding, equality, and hashing.

**Coverage:**
- `Project`: Codable encoding/decoding, Equatable, Hashable
- `Card`: Codable encoding/decoding, Equatable
- `WorkspaceConfig`: Codable encoding/decoding, Equatable
- `CardStatus`, `CardType`, `Priority`: CaseIterable, raw values

**Example Test:**

```swift
func testProjectCodable() throws {
    let project = Project(
        id: UUID(),
        title: "Test Project",
        description: "Description",
        tags: ["tag1", "tag2"],
        created: Date(),
        updated: Date(),
        slug: "test-project"
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(project)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(Project.self, from: data)

    XCTAssertEqual(project, decoded)
}
```

**Notes:**
- Models have no complex logic, so tests focus on protocol conformances
- Enum tests verify raw values match expected strings

## FrontmatterParserTests.swift

**Purpose:** Test frontmatter parsing and serialization, including round-trips and error handling.

**Coverage:**
- Parse markdown with frontmatter
- Parse markdown without frontmatter
- Parse malformed frontmatter (missing closing delimiter)
- Parse invalid YAML
- Serialize frontmatter and body
- Round-trip preservation of frontmatter fields
- Serialize empty frontmatter (should return body only)

**Example Test:**

```swift
func testParseMarkdownWithFrontmatter() throws {
    let markdown = """
    ---
    title: Test
    tags:
      - work
    ---

    Body content here.
    """

    let parsed = try FrontmatterParser.parse(markdown)

    XCTAssertEqual(parsed.frontmatter["title"] as? String, "Test")
    XCTAssertEqual(parsed.frontmatter["tags"] as? [String], ["work"])
    XCTAssertEqual(parsed.body.trimmingCharacters(in: .whitespacesAndNewlines), "Body content here.")
}
```

**Round-Trip Test:**

```swift
func testRoundTrip() throws {
    let frontmatter: [String: Any] = ["title": "Test", "count": 42]
    let body = "Body content"

    let serialized = try FrontmatterParser.serialize(frontmatter: frontmatter, body: body)
    let parsed = try FrontmatterParser.parse(serialized)

    XCTAssertEqual(parsed.frontmatter["title"] as? String, "Test")
    XCTAssertEqual(parsed.frontmatter["count"] as? Int, 42)
    XCTAssertEqual(parsed.body.trimmingCharacters(in: .whitespacesAndNewlines), body)
}
```

**Notes:**
- Round-trip tests verify L02 (Preserve Unknown Fields)
- Error tests verify proper error types are thrown

## SlugGeneratorTests.swift

**Purpose:** Test slug generation with various input patterns and edge cases.

**Coverage:**
- Simple titles (spaces, lowercase, alphanumeric)
- Titles with punctuation
- Titles with non-ASCII characters
- Titles with consecutive spaces or hyphens
- Titles with leading/trailing hyphens
- Empty titles

**Example Tests:**

```swift
func testSimpleTitle() {
    XCTAssertEqual(SlugGenerator.generateSlug(from: "My Project"), "my-project")
}

func testPunctuation() {
    XCTAssertEqual(SlugGenerator.generateSlug(from: "Bug #42: Fix crash"), "bug-42-fix-crash")
}

func testNonASCII() {
    XCTAssertEqual(SlugGenerator.generateSlug(from: "Café Menu"), "caf-menu")
}

func testConsecutiveSpaces() {
    XCTAssertEqual(SlugGenerator.generateSlug(from: "Multiple  Spaces"), "multiple-spaces")
}

func testLeadingTrailingHyphens() {
    XCTAssertEqual(SlugGenerator.generateSlug(from: "---test---"), "test")
}
```

**Notes:**
- Slug generation is deterministic and has no side effects
- Tests verify consistency across various input patterns

## WorkspaceServiceTests.swift

**Purpose:** Test WorkspaceService I/O operations using temporary directories.

**Coverage:**
- Load workspace config (success and failure)
- Load projects (success, missing fields, malformed frontmatter)
- Load cards (success, missing fields, defaults)
- Create workspace and config
- Initialize workspace files
- Create project (success, directory creation)
- Create card (success, create cards directory if missing)
- Update project (success, preserve unknown fields)
- Update card (success, preserve unknown fields)
- Delete project (trash operation)
- Delete card (trash operation)
- Error cases (config not found, invalid directory, file not found)

**Test Pattern:**

```swift
func testLoadProjects() throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let projectDir = tempDir.appendingPathComponent("test-project")
    try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)

    let frontmatter: [String: Any] = [
        "id": UUID().uuidString,
        "title": "Test Project",
        "description": "Description",
        "tags": ["tag1"],
        "created": "2026-01-15T10:30:00Z",
        "updated": "2026-01-15T10:30:00Z",
        "slug": "test-project"
    ]
    let markdown = try FrontmatterParser.serialize(frontmatter: frontmatter, body: "")
    try markdown.write(to: projectDir.appendingPathComponent("project.md"), atomically: true, encoding: .utf8)

    let service = WorkspaceService()
    let projects = try service.loadProjects(from: tempDir.path)

    XCTAssertEqual(projects.count, 1)
    XCTAssertEqual(projects[0].title, "Test Project")
}
```

**Notes:**
- Tests use `FileManager.temporaryDirectory` to create isolated test directories
- `defer` blocks clean up temporary files after tests
- Tests verify both success and failure cases
- Unknown field preservation tested via update methods

## HieroglyphsVMTests.swift

**Purpose:** Test ViewModel coordination logic using mock WorkspaceService.

**Coverage:**
- `loadWorkspace()` success (config and projects loaded)
- `loadWorkspace()` config error (workspacePath nil, projects empty)
- `loadWorkspace()` projects error (projects empty)
- `createProject()` success (project created, list reloaded)
- `createProject()` with nil workspacePath (fails gracefully)
- `selectProject()` updates selectedProject state

**Mock Service Pattern:**

```swift
class MockWorkspaceService: WorkspaceProviding {
    var configToReturn: WorkspaceConfig?
    var projectsToReturn: [Project] = []
    var cardsToReturn: [Card] = []
    var shouldThrowError = false
    var errorToThrow: Error = WorkspaceError.configNotFound

    func loadWorkspaceConfig(from configPath: String?) throws -> WorkspaceConfig {
        if shouldThrowError { throw errorToThrow }
        guard let config = configToReturn else {
            throw WorkspaceError.configNotFound
        }
        return config
    }

    func loadProjects(from workspacePath: String) throws -> [Project] {
        if shouldThrowError { throw errorToThrow }
        return projectsToReturn
    }

    // ... other methods
}
```

**Example Test:**

```swift
@MainActor
func testLoadWorkspaceSuccess() throws {
    let mockService = MockWorkspaceService()
    mockService.configToReturn = WorkspaceConfig(workspacePath: "/test/path")
    mockService.projectsToReturn = [
        Project(
            id: UUID(),
            title: "Project 1",
            description: "",
            tags: [],
            created: Date(),
            updated: Date(),
            slug: "project-1"
        )
    ]

    let viewModel = HieroglyphsVM(workspaceService: mockService)
    viewModel.loadWorkspace()

    XCTAssertEqual(viewModel.workspacePath, "/test/path")
    XCTAssertEqual(viewModel.projects.count, 1)
    XCTAssertEqual(viewModel.projects[0].title, "Project 1")
}
```

**Notes:**
- Tests use `@MainActor` annotation to match ViewModel's main-thread isolation
- Mock service enables testing coordination logic without filesystem I/O
- Tests verify error handling (workspacePath nil, projects empty on error)

## Running Tests

**Command Line:**

```bash
swift test
```

**Xcode:**

1. Open Package.swift in Xcode (generate Xcode project temporarily with `open Package.swift`)
2. Select HieroglyphsTests scheme
3. Press Cmd+U to run tests

**Notes:**
- Tests must pass for every phase per L11
- `swift test` runs all tests and reports pass/fail
- Tests run in parallel by default (XCTest behavior)

## Test Coverage Reporting

**Current:** No automated coverage reporting (future enhancement).

**Manual Verification:** Review test files to ensure all public methods have tests.

**Future:** Add `swift test --enable-code-coverage` and generate coverage reports with `xcrun llvm-cov`.

## Lint and Code Quality

**Current:** No automated linting (future enhancement).

**Manual Verification:** Code review for dead code, unused imports, style violations.

**Future:** Add SwiftLint or similar tool to enforce style guide (L12: No Dead Code).

## Testing Anti-Patterns

**Avoid these patterns:**

1. **Testing Private Methods:** Test public API only. Private methods are implicitly tested.
2. **Testing SwiftUI Views:** SwiftUI views lack testable API. Use manual testing or UI tests.
3. **Testing Implementation Details:** Test behavior, not implementation. Mocks should verify results, not method call counts.
4. **Flaky Tests:** Tests must be deterministic. Avoid date/time dependencies (use fixed dates).
5. **Global State:** Each test must be isolated. Use temporary directories, reset mocks between tests.

## Future Testing Enhancements

**Planned additions not yet implemented:**

1. **UI Tests:** Add XCTest UI tests for critical workflows (project creation, card editing)
2. **Coverage Reporting:** Add `--enable-code-coverage` and generate HTML reports
3. **Linting:** Add SwiftLint to enforce L12 (No Dead Code) and style guide
4. **Performance Tests:** Add performance tests for large workspaces (1000+ projects/cards)
5. **Integration Tests:** Add tests that exercise full stack (service + ViewModel + views)
6. **Continuous Integration:** Run tests on every commit via GitHub Actions or similar
