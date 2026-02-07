# Phase 0003: Workspace Service (Read)

## Intent

Implement a workspace reading service that discovers and loads projects and cards from the filesystem. The service reads configuration from `~/.hieroglyphs/config.yaml`, scans the workspace directory tree for `project.md` and `card.md` files, parses them using `FrontmatterParser`, and returns typed `Project` and `Card` model instances.

This phase bridges the gap between filesystem structure and in-memory models, enabling the app to load and display workspace data. It is strictly read-only — file writing, watching, and modification are deferred to future phases.

## Scope

**In scope:**
- `WorkspaceProviding` protocol defining the service interface
- `WorkspaceService` concrete implementation conforming to the protocol
- Reading and parsing `~/.hieroglyphs/config.yaml` to obtain workspace path
- Scanning workspace directory for project folders containing `project.md`
- Parsing `project.md` files with `FrontmatterParser` and mapping to `Project` models
- Scanning each project's `cards/` subdirectory for card folders containing `card.md`
- Parsing `card.md` files with `FrontmatterParser` and mapping to `Card` models
- Graceful error handling: skip unparseable files, log errors, continue scanning
- Comprehensive test coverage using fixture workspace directories on disk
- Protocol methods: `loadWorkspaceConfig()`, `loadProjects(from:)`, `loadCards(from:for:)`

**Out of scope:**
- File writing, modification, or deletion
- File watching or change detection (deferred to Phase 4+)
- In-memory caching or optimization
- Tag reconciliation with extended attributes (deferred)
- UI integration or ViewModel wiring (deferred)
- Project or card creation workflows

## Constraints

**Laws:**
- L01 — Filesystem as Source of Truth: Service reads only from disk, no divergent state
- L02 — Opinionated on Write, Laissez-Faire on Read: Must handle malformed files gracefully, skip what cannot be parsed
- L05 — External Changes Are First-Class: Service must support re-reading on demand (stateless design)
- L06 — Platform Leverage Over Reinvention: Use Foundation's FileManager for filesystem operations
- L09 — Sandi Metz Principles: Protocol-based service, injected dependencies, small focused methods
- L11 — Test Coverage: All public protocol methods must have tests

**Style:**
- Services are protocol-based with concrete implementations
- Protocol placed in `Sources/Hieroglyphs/Services/WorkspaceProviding.swift`
- Implementation placed in `Sources/Hieroglyphs/Services/WorkspaceService.swift`
- Tests use fixture workspace directories on disk (per user requirement)
- One primary type per file
- Error handling follows "do your best" philosophy: log and skip, never crash

## Acceptance Criteria

1. `WorkspaceProviding.swift` exists in `Sources/Hieroglyphs/Services/` defining protocol interface
2. `WorkspaceService.swift` exists in `Sources/Hieroglyphs/Services/` implementing the protocol
3. Protocol includes method: `loadWorkspaceConfig() throws -> WorkspaceConfig`
4. Protocol includes method: `loadProjects(from workspacePath: String) throws -> [Project]`
5. Protocol includes method: `loadCards(from projectPath: String, for project: Project) throws -> [Card]`
6. Service reads `~/.hieroglyphs/config.yaml` and parses it using YAML parser
7. Service scans workspace directory for subdirectories containing `project.md`
8. Service parses each `project.md` using `FrontmatterParser` and maps frontmatter to `Project` model fields
9. Service scans each project's `cards/` subdirectory for card folders containing `card.md`
10. Service parses each `card.md` using `FrontmatterParser` and maps frontmatter to `Card` model fields
11. Service handles missing or malformed files gracefully: logs errors or warnings, skips file, continues scanning
12. All public protocol methods have corresponding tests in `Tests/HieroglyphsTests/WorkspaceServiceTests.swift`
13. Tests create and use fixture workspace directories on disk (per L01 and user requirement)
14. Tests verify config loading, project discovery, card discovery, and error handling
15. `swift test` passes with 100% success (all existing + new tests)
16. `swift build` completes without errors or warnings

## Risks / Notes

**Fixture-based testing:** Tests will create temporary directories and files on disk to verify filesystem operations. This is intentional and aligns with L01 (filesystem as truth). Fixtures will be created in the test bundle's temporary directory and cleaned up after tests.

**Error handling strategy:** The service uses "do your best" error handling. If a file is unparseable, it logs the issue and skips the file. If a directory is inaccessible, it skips the directory. This honors L02 and ensures the app never crashes on malformed data.

**Date handling:** Frontmatter timestamps (`created`, `updated`) are stored as ISO8601 strings in YAML. The service must parse these strings to `Date` objects when constructing models. ISO8601DateFormatter will be used.

**Stateless design:** The service holds no state. Every method reads from disk. This honors L01 and L05. Future phases may introduce caching, but Phase 3 is deliberately stateless.

**Directory structure assumptions:**
- Workspace root contains project folders (e.g., `workspace/project-alpha/`)
- Each project folder contains `project.md` at root
- Each project folder contains a `cards/` subdirectory
- Each card lives in its own folder inside `cards/` (e.g., `cards/fix-bug-123/card.md`)

**Slug extraction:** Project and card slugs are derived from their folder names, not computed from titles. The folder name IS the slug. This ensures filesystem and model slugs stay synchronized.

**Unknown fields:** FrontmatterParser already preserves unknown fields. The service extracts only the fields it knows (title, status, etc.) and ignores the rest. This honors L02.

**No validation:** The service does not validate frontmatter values. If status is "invalid-status", it reads it as-is. Validation (if any) is the responsibility of UI or future validation layers.
