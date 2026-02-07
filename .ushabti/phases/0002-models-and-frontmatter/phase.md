# Phase 0002: Models and Frontmatter Parser

## Intent

Define the core data model types and implement a pure frontmatter parser utility. This phase establishes the fundamental data structures that represent projects, cards, and workspace configuration, along with the parser that bridges markdown files with YAML frontmatter and these typed models.

Models are plain Swift structs with no I/O dependencies. The frontmatter parser is a pure utility that reads and writes markdown files with YAML frontmatter, preserving unknown fields to honor L02 (Opinionated on Write, Laissez-Faire on Read). The slug generator provides filesystem-safe naming.

This phase provides the foundation for all future file I/O, UI binding, and workspace management.

## Scope

**In scope:**
- Model types: `Project`, `Card`, `WorkspaceConfig`
- Enum types: `CardStatus`, `CardType`, `Priority`
- `FrontmatterParser` utility (parse, serialize, preserve unknown fields)
- `SlugGenerator` utility (title to filesystem-safe slug)
- Comprehensive test coverage for all public APIs
- Models placed in `Sources/Hieroglyphs/Models/`
- Utilities placed in `Sources/Hieroglyphs/Utilities/`

**Out of scope:**
- File I/O services (reading/writing actual files on disk)
- Workspace loading or project/card discovery
- UI views or bindings
- File watching or change detection
- Tag reconciliation with extended attributes

## Constraints

**Laws:**
- L01 — Filesystem as Source of Truth: Models reflect what will be on disk, but this phase does not perform I/O
- L02 — Opinionated on Write, Laissez-Faire on Read: FrontmatterParser must preserve unknown fields
- L04 — No SwiftData: Models are plain Swift types with no persistence framework
- L09 — Sandi Metz Principles: Models are plain data types with no dependencies
- L11 — Test Coverage: Every public method must have tests

**Style:**
- Models are plain structs/enums in `Models/` directory
- Utilities are pure functions with no side effects
- One primary type per file, file name matches type name
- Clarity over brevity in naming
- No regex usage in string parsing

## Acceptance Criteria

1. `Card.swift` exists with: `id` (UUID), `title`, `type` (CardType), `status` (CardStatus), `priority` (Priority), `tags` ([String]), `created` (Date), `updated` (Date), `slug` (String), `body` (String)
2. `Project.swift` exists with: `id` (UUID), `title`, `description`, `tags` ([String]), `created` (Date), `updated` (Date), `slug` (String)
3. `WorkspaceConfig.swift` exists with: `workspacePath` (String)
4. `CardStatus.swift` exists as enum: `backlog`, `todo`, `inProgress`, `done`, `archived`
5. `CardType.swift` exists as enum: `task`, `bug`, `feature`, `note`
6. `Priority.swift` exists as enum: `low`, `medium`, `high`, `critical`
7. `FrontmatterParser.swift` exists with public methods: `parse(_ markdown: String) throws -> (frontmatter: [String: Any], body: String)` and `serialize(frontmatter: [String: Any], body: String) throws -> String`
8. FrontmatterParser preserves unknown frontmatter fields when round-tripping
9. `SlugGenerator.swift` exists with public method: `generateSlug(from title: String) -> String`
10. SlugGenerator produces lowercase, hyphen-separated, alphanumeric slugs
11. All public methods have corresponding tests in `Tests/HieroglyphsTests/`
12. Tests cover happy paths, edge cases, and error conditions
13. `swift test` passes with 100% success
14. `swift build` completes without errors or warnings

## Risks / Notes

**Models are intentionally simple:** These are data containers. No business logic beyond computed properties. All mutation and persistence logic deferred to services in future phases.

**Frontmatter parser uses Yams dependency:** YAML parsing requires a library. Yams is the de facto Swift YAML parser and is anticipated in style.md dependencies. If not already in Package.swift, Builder must add it.

**Unknown field preservation:** The parser must read YAML into `[String: Any]`, allow callers to extract known fields, and serialize the entire dictionary back out. This ensures external tools can extend frontmatter without data loss.

**Slug generation is deterministic:** Given the same title, always produce the same slug. No timestamps or random suffixes. Collision handling is deferred to filesystem services in future phases.

**Date handling:** Models use `Date` for created/updated timestamps. Serialization to ISO8601 strings is handled by FrontmatterParser, not models.

**No validation logic in models:** Models accept whatever values are provided. Validation (if any) happens at service layer or UI layer in future phases.
