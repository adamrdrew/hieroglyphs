# Implementation Steps

## S001: Add Yams dependency to Package.swift

**Intent:** Enable YAML parsing for frontmatter by adding the Yams package dependency.

**Work:**
- Open `Package.swift`
- Add Yams dependency: `.package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")`
- Add Yams to Hieroglyphs target dependencies
- Run `swift build` to verify dependency resolution

**Done when:**
- Yams appears in Package.swift dependencies array
- Yams appears in Hieroglyphs target dependencies
- `swift build` succeeds without dependency errors

## S002: Define CardStatus enum

**Intent:** Provide typed representation of card workflow states.

**Work:**
- Create `Sources/Hieroglyphs/Models/CardStatus.swift`
- Define enum with cases: `backlog`, `todo`, `inProgress`, `done`, `archived`
- Conform to `String`, `Codable`, `CaseIterable`
- Add `rawValue` for frontmatter serialization (lowercase with hyphens)

**Done when:**
- CardStatus.swift exists with all five cases
- Enum conforms to String, Codable, CaseIterable
- `swift build` succeeds

## S003: Define CardType enum

**Intent:** Provide typed representation of card categories.

**Work:**
- Create `Sources/Hieroglyphs/Models/CardType.swift`
- Define enum with cases: `task`, `bug`, `feature`, `note`
- Conform to `String`, `Codable`, `CaseIterable`
- Add `rawValue` for frontmatter serialization

**Done when:**
- CardType.swift exists with all four cases
- Enum conforms to String, Codable, CaseIterable
- `swift build` succeeds

## S004: Define Priority enum

**Intent:** Provide typed representation of task priority levels.

**Work:**
- Create `Sources/Hieroglyphs/Models/Priority.swift`
- Define enum with cases: `low`, `medium`, `high`, `critical`
- Conform to `String`, `Codable`, `CaseIterable`
- Add `rawValue` for frontmatter serialization

**Done when:**
- Priority.swift exists with all four cases
- Enum conforms to String, Codable, CaseIterable
- `swift build` succeeds

## S005: Define Project model

**Intent:** Represent a project with metadata and timestamps.

**Work:**
- Create `Sources/Hieroglyphs/Models/Project.swift`
- Define struct with: `id: UUID`, `title: String`, `description: String`, `tags: [String]`, `created: Date`, `updated: Date`, `slug: String`
- Conform to `Identifiable`, `Codable`, `Equatable`
- No methods beyond init (plain data container)

**Done when:**
- Project.swift exists with all specified properties
- Struct conforms to Identifiable, Codable, Equatable
- `swift build` succeeds

## S006: Define Card model

**Intent:** Represent a card with type, status, priority, and markdown body.

**Work:**
- Create `Sources/Hieroglyphs/Models/Card.swift`
- Define struct with: `id: UUID`, `title: String`, `type: CardType`, `status: CardStatus`, `priority: Priority`, `tags: [String]`, `created: Date`, `updated: Date`, `slug: String`, `body: String`
- Conform to `Identifiable`, `Codable`, `Equatable`
- No methods beyond init

**Done when:**
- Card.swift exists with all specified properties
- Struct conforms to Identifiable, Codable, Equatable
- `swift build` succeeds

## S007: Define WorkspaceConfig model

**Intent:** Represent workspace configuration with file path.

**Work:**
- Create `Sources/Hieroglyphs/Models/WorkspaceConfig.swift`
- Define struct with: `workspacePath: String`
- Conform to `Codable`, `Equatable`
- No methods beyond init

**Done when:**
- WorkspaceConfig.swift exists with workspacePath property
- Struct conforms to Codable, Equatable
- `swift build` succeeds

## S008: Implement SlugGenerator utility

**Intent:** Convert arbitrary title strings to filesystem-safe slugs.

**Work:**
- Create `Sources/Hieroglyphs/Utilities/SlugGenerator.swift`
- Implement `generateSlug(from title: String) -> String`
- Algorithm: lowercase, replace spaces with hyphens, remove non-alphanumeric/non-hyphen characters, collapse consecutive hyphens, trim leading/trailing hyphens
- Pure function, no side effects

**Done when:**
- SlugGenerator.swift exists with public generateSlug method
- Method produces lowercase alphanumeric + hyphen output
- `swift build` succeeds

## S009: Implement FrontmatterParser utility

**Intent:** Parse and serialize markdown files with YAML frontmatter, preserving unknown fields.

**Work:**
- Create `Sources/Hieroglyphs/Utilities/FrontmatterParser.swift`
- Import Yams
- Implement `parse(_ markdown: String) throws -> (frontmatter: [String: Any], body: String)`
  - Split on `---` delimiters
  - Parse YAML frontmatter into dictionary
  - Return frontmatter dictionary and markdown body
- Implement `serialize(frontmatter: [String: Any], body: String) throws -> String`
  - Convert dictionary to YAML using Yams
  - Wrap in `---` delimiters
  - Append body
- Handle edge cases: missing frontmatter, malformed YAML, empty body

**Done when:**
- FrontmatterParser.swift exists with parse and serialize methods
- Methods handle valid frontmatter + body correctly
- Methods preserve unknown frontmatter fields
- `swift build` succeeds

## S010: Test SlugGenerator

**Intent:** Verify slug generation handles all expected inputs correctly.

**Work:**
- Create `Tests/HieroglyphsTests/SlugGeneratorTests.swift`
- Test cases:
  - Simple title: "Hello World" → "hello-world"
  - Special characters: "Add @mentions & #tags!" → "add-mentions-tags"
  - Consecutive spaces: "Too    Many     Spaces" → "too-many-spaces"
  - Leading/trailing spaces: "  Trim Me  " → "trim-me"
  - Already lowercase: "already-done" → "already-done"
  - Numbers: "Plan 2024" → "plan-2024"
  - Empty string: "" → ""
  - Unicode: "Café René" → "cafe-rene" (if ASCII-only) or preserve (if Unicode allowed)

**Done when:**
- SlugGeneratorTests.swift exists with at least 8 test methods
- All test cases pass
- `swift test` succeeds

## S011: Test FrontmatterParser parse method

**Intent:** Verify frontmatter parsing handles valid and invalid inputs.

**Work:**
- Create `Tests/HieroglyphsTests/FrontmatterParserTests.swift`
- Test cases for parse:
  - Valid frontmatter with body
  - Frontmatter with unknown fields
  - Missing frontmatter (only body)
  - Empty frontmatter
  - Malformed YAML (should throw)
  - Empty string
  - Frontmatter with nested structures (arrays, dictionaries)

**Done when:**
- FrontmatterParserTests.swift exists with at least 7 parse test methods
- All test cases pass
- `swift test` succeeds

## S012: Test FrontmatterParser serialize method

**Intent:** Verify frontmatter serialization produces valid markdown.

**Work:**
- Add serialize test cases to `Tests/HieroglyphsTests/FrontmatterParserTests.swift`
- Test cases:
  - Valid frontmatter dictionary + body
  - Empty frontmatter + body
  - Frontmatter + empty body
  - Round-trip: parse then serialize produces equivalent output
  - Unknown fields preserved in round-trip

**Done when:**
- At least 5 serialize test methods added
- Round-trip preservation test passes
- All test cases pass
- `swift test` succeeds

## S013: Test model enum types

**Intent:** Verify enums have correct cases and conform to required protocols.

**Work:**
- Create `Tests/HieroglyphsTests/ModelTests.swift`
- Test CardStatus: verify all 5 cases exist, rawValue correctness, Codable round-trip
- Test CardType: verify all 4 cases exist, rawValue correctness, Codable round-trip
- Test Priority: verify all 4 cases exist, rawValue correctness, Codable round-trip

**Done when:**
- ModelTests.swift exists with tests for all three enums
- All test cases pass
- `swift test` succeeds

## S014: Test Project model

**Intent:** Verify Project initializes and encodes correctly.

**Work:**
- Add Project tests to `Tests/HieroglyphsTests/ModelTests.swift`
- Test cases:
  - Initialization with all properties
  - Equatable conformance
  - Codable round-trip (encode to JSON, decode back, verify equality)
  - Identifiable conformance (id property)

**Done when:**
- At least 4 Project test methods added
- All test cases pass
- `swift test` succeeds

## S015: Test Card model

**Intent:** Verify Card initializes and encodes correctly.

**Work:**
- Add Card tests to `Tests/HieroglyphsTests/ModelTests.swift`
- Test cases:
  - Initialization with all properties
  - Equatable conformance
  - Codable round-trip
  - Identifiable conformance
  - Body property stores markdown correctly

**Done when:**
- At least 5 Card test methods added
- All test cases pass
- `swift test` succeeds

## S016: Test WorkspaceConfig model

**Intent:** Verify WorkspaceConfig initializes and encodes correctly.

**Work:**
- Add WorkspaceConfig tests to `Tests/HieroglyphsTests/ModelTests.swift`
- Test cases:
  - Initialization with workspacePath
  - Equatable conformance
  - Codable round-trip

**Done when:**
- At least 3 WorkspaceConfig test methods added
- All test cases pass
- `swift test` succeeds

## S017: Verify build and test suite

**Intent:** Ensure entire phase builds cleanly and all tests pass.

**Work:**
- Run `swift build` from repository root
- Run `swift test` from repository root
- Verify no warnings or errors
- Verify all tests green

**Done when:**
- `swift build` exits with status 0, no warnings
- `swift test` exits with status 0, all tests pass
- Console output shows green test results
