# Workspace Service

## Overview

The Workspace Service is a protocol-based, stateless service layer responsible for all filesystem I/O operations. It reads and writes workspace configuration, discovers projects and cards, and handles CRUD operations while preserving unknown frontmatter fields.

**Protocol:** `WorkspaceProviding`
**Implementation:** `WorkspaceService`
**Location:** `Sources/Hieroglyphs/Services/`

The service supports L01 (Filesystem as Source of Truth), L02 (Preserve Unknown Fields), L06 (Platform Leverage with FileManager and Trash), and L09 (Protocol-Based Design).

## WorkspaceProviding Protocol

**Purpose:** Define the contract for workspace I/O operations.

**Methods:** See sections below.

**Notes:** Protocol enables dependency injection and testing with mocks. Views and ViewModel depend on the protocol, not the concrete implementation.

## WorkspaceService Implementation

**Purpose:** Concrete implementation of `WorkspaceProviding` using FileManager and Yams.

**Dependencies:**
- `FileManager` — For directory scanning, file I/O, and Trash operations
- `Yams` — For YAML parsing and serialization
- `FrontmatterParser` — For parsing and serializing markdown with frontmatter
- `SlugGenerator` — For generating filesystem-safe slugs from titles

**State:** Stateless. All methods read from or write to disk on every call. No caching.

**Error Handling:** Throws typed errors from `WorkspaceError` enum. Caller (typically ViewModel) logs errors or presents them to UI.

### WorkspaceError Enum

**Cases:**
- `configNotFound` — Workspace config file does not exist
- `configInvalid` — Config file is not valid YAML or missing required fields
- `invalidDirectory` — Specified directory does not exist or is not accessible
- `yamlParsingFailed(Error)` — YAML parsing failed (wraps underlying error)
- `directoryCreationFailed(Error)` — Directory creation failed
- `fileWriteFailed(Error)` — File write operation failed
- `projectNotFound` — Project directory or file does not exist
- `cardNotFound` — Card directory or file does not exist

## Configuration Methods

### loadWorkspaceConfig(from:)

**Signature:** `func loadWorkspaceConfig(from configPath: String?) throws -> WorkspaceConfig`

**Purpose:** Load workspace configuration from `~/.hieroglyphs/config.yaml`.

**Parameters:**
- `configPath` — Optional custom config path (used for testing). Defaults to `~/.hieroglyphs/config.yaml`.

**Returns:** `WorkspaceConfig` containing workspace path.

**Throws:**
- `configNotFound` if config file does not exist
- `yamlParsingFailed` if YAML is invalid or missing `workspacePath` field

**Behavior:**
1. Resolve config path (custom or default `~/.hieroglyphs/config.yaml`)
2. Check file exists
3. Read YAML content
4. Decode to `WorkspaceConfig` using `YAMLDecoder`
5. Return config

**Example config file:**

```yaml
workspacePath: /Users/alice/Hieroglyphs
```

## Read Methods

### loadProjects(from:)

**Signature:** `func loadProjects(from workspacePath: String) throws -> [Project]`

**Purpose:** Load all projects from the workspace directory.

**Parameters:**
- `workspacePath` — Absolute path to workspace directory

**Returns:** Array of `Project` objects (may be empty if no projects exist).

**Throws:**
- `invalidDirectory` if workspace path does not exist or is not accessible

**Behavior:**
1. Check workspace directory exists
2. Scan directory for subdirectories containing `project.md`
3. For each project directory:
   - Read `project.md`
   - Parse frontmatter via `FrontmatterParser`
   - Construct `Project` model from frontmatter fields
   - Use directory name as `slug`
   - Use ISO8601DateFormatter to parse `created` and `updated` dates
4. Skip projects with missing required fields (log warning)
5. Skip projects with parsing errors (log warning)
6. Return array of successfully parsed projects

**Required frontmatter fields:**
- `id` (UUID string)
- `title` (string)

**Optional frontmatter fields (with defaults):**
- `description` (defaults to `""`)
- `tags` (defaults to `[]`)
- `created` (defaults to current date if missing or invalid)
- `updated` (defaults to current date if missing or invalid)
- `slug` (derived from directory name, not read from frontmatter)

### loadCards(from:for:)

**Signature:** `func loadCards(from projectPath: String, for project: Project) throws -> [Card]`

**Purpose:** Load all cards for a given project.

**Parameters:**
- `projectPath` — Absolute path to project directory
- `project` — The project these cards belong to (used for context, not I/O)

**Returns:** Array of `Card` objects (may be empty if no cards exist or `cards/` directory does not exist).

**Throws:** Rarely throws (returns empty array if `cards/` directory missing).

**Behavior:**
1. Construct path to `{projectPath}/cards/`
2. If `cards/` directory does not exist, return empty array
3. Scan `cards/` directory for subdirectories containing `card.md`
4. For each card directory:
   - Read `card.md`
   - Parse frontmatter and body via `FrontmatterParser`
   - Construct `Card` model from frontmatter fields
   - Use directory name as `slug`
   - Parse enum fields (`type`, `status`, `priority`) with defaults if invalid
   - Use ISO8601DateFormatter to parse dates
5. Skip cards with missing required fields (log warning)
6. Skip cards with parsing errors (log warning)
7. Return array of successfully parsed cards

**Required frontmatter fields:**
- `id` (UUID string)
- `title` (string)

**Optional frontmatter fields (with defaults):**
- `type` (defaults to `task` if missing or invalid)
- `status` (defaults to `backlog` if missing or invalid)
- `priority` (defaults to `medium` if missing or invalid)
- `tags` (defaults to `[]`)
- `created` (defaults to current date if missing or invalid)
- `updated` (defaults to current date if missing or invalid)
- `slug` (derived from directory name, not read from frontmatter)
- `body` (defaults to `""` if only frontmatter exists)

## Write Methods

### createWorkspace(at:configDirectory:)

**Signature:** `func createWorkspace(at path: String, configDirectory: String?) throws`

**Purpose:** Create a new workspace directory and write config file.

**Parameters:**
- `path` — Absolute path where workspace directory should be created
- `configDirectory` — Optional custom config directory (defaults to `~/.hieroglyphs`)

**Throws:**
- `directoryCreationFailed` if directory creation fails
- `fileWriteFailed` if config file write fails

**Behavior:**
1. Create workspace directory at `path` (with intermediate directories)
2. Create config directory at `~/.hieroglyphs` (or custom path)
3. Write `config.yaml` to config directory with `workspacePath: {path}`
4. Use `YAMLEncoder` to serialize `WorkspaceConfig`

### initializeWorkspaceFiles(at:)

**Signature:** `func initializeWorkspaceFiles(at workspacePath: String) throws`

**Purpose:** Create instructional files for users and AI assistants.

**Parameters:**
- `workspacePath` — Absolute path to workspace directory

**Throws:**
- `fileWriteFailed` if file write fails

**Behavior:**
1. Write `CLAUDE.md` to workspace root with AI assistant instructions
2. Write `AGENT.md` to workspace root with agent workflow instructions

**Notes:** These files document workspace structure and frontmatter schema for external tools and LLMs.

### createProject(title:description:tags:at:)

**Signature:** `func createProject(title: String, description: String, tags: [String], at workspacePath: String) throws -> Project`

**Purpose:** Create a new project with directory and frontmatter file.

**Parameters:**
- `title` — Project title
- `description` — Project description
- `tags` — Array of tag strings
- `workspacePath` — Absolute path to workspace directory

**Returns:** The created `Project` model.

**Throws:**
- `directoryCreationFailed` if directory creation fails
- `fileWriteFailed` if file write fails

**Behavior:**
1. Generate slug from title via `SlugGenerator`
2. Create project directory at `{workspacePath}/{slug}/`
3. Generate new UUID for `id`
4. Set `created` and `updated` to current date
5. Build frontmatter dictionary with all fields
6. Serialize frontmatter + empty body via `FrontmatterParser`
7. Write to `{workspacePath}/{slug}/project.md`
8. Return `Project` model

**Notes:** Uses atomic write (`atomically: true`) to ensure file is written completely or not at all.

### createCard(title:type:status:priority:tags:body:projectPath:)

**Signature:** `func createCard(title: String, type: CardType, status: CardStatus, priority: Priority, tags: [String], body: String, projectPath: String) throws -> Card`

**Purpose:** Create a new card with directory and frontmatter file.

**Parameters:**
- `title` — Card title
- `type` — Card type
- `status` — Card status
- `priority` — Card priority
- `tags` — Array of tag strings
- `body` — Markdown body content
- `projectPath` — Absolute path to parent project directory

**Returns:** The created `Card` model.

**Throws:**
- `directoryCreationFailed` if directory creation fails
- `fileWriteFailed` if file write fails

**Behavior:**
1. Generate slug from title via `SlugGenerator`
2. Construct path to `{projectPath}/cards/`
3. If `cards/` directory does not exist, create it
4. Create card directory at `{projectPath}/cards/{slug}/`
5. Generate new UUID for `id`
6. Set `created` and `updated` to current date
7. Build frontmatter dictionary with all fields (use enum raw values for type/status/priority)
8. Serialize frontmatter + body via `FrontmatterParser`
9. Write to `{projectPath}/cards/{slug}/card.md`
10. Return `Card` model

**Notes:** Uses atomic write. Creates `cards/` directory if it does not exist.

### updateProject(_:at:)

**Signature:** `func updateProject(_ project: Project, at workspacePath: String) throws`

**Purpose:** Update an existing project, preserving unknown frontmatter fields.

**Parameters:**
- `project` — Updated project model
- `workspacePath` — Absolute path to workspace directory

**Throws:**
- `projectNotFound` if project file does not exist
- `fileWriteFailed` if file write fails

**Behavior:**
1. Construct path to `{workspacePath}/{project.slug}/project.md`
2. Check file exists (throw `projectNotFound` if missing)
3. Read existing file
4. Parse frontmatter via `FrontmatterParser`
5. Merge updated fields into existing frontmatter dictionary (preserving unknown fields)
6. Update `updated` timestamp to current date
7. Serialize frontmatter + body via `FrontmatterParser`
8. Write atomically to file

**Notes:** This method implements L02 (Preserve Unknown Fields) by reading existing frontmatter, merging updated fields, and keeping unknown fields intact.

### updateCard(_:projectPath:)

**Signature:** `func updateCard(_ card: Card, projectPath: String) throws`

**Purpose:** Update an existing card, preserving unknown frontmatter fields.

**Parameters:**
- `card` — Updated card model
- `projectPath` — Absolute path to parent project directory

**Throws:**
- `cardNotFound` if card file does not exist
- `fileWriteFailed` if file write fails

**Behavior:**
1. Construct path to `{projectPath}/cards/{card.slug}/card.md`
2. Check file exists (throw `cardNotFound` if missing)
3. Read existing file
4. Parse frontmatter and body via `FrontmatterParser`
5. Merge updated fields into existing frontmatter dictionary (preserving unknown fields)
6. Update `updated` timestamp to current date
7. Serialize frontmatter + body via `FrontmatterParser`
8. Write atomically to file

**Notes:** Preserves unknown frontmatter fields per L02. Updates both frontmatter and body.

## Delete Methods

### deleteProject(at:)

**Signature:** `func deleteProject(at projectPath: String) throws`

**Purpose:** Delete a project by moving it to macOS Trash.

**Parameters:**
- `projectPath` — Absolute path to project directory

**Throws:**
- `projectNotFound` if project directory does not exist
- Underlying NSFileManager errors if trash operation fails

**Behavior:**
1. Check project directory exists
2. Use `FileManager.trashItem(at:resultingItemURL:)` to move to Trash
3. Trash operation is reversible (user can restore from Trash)

**Notes:** Uses system Trash per L06 (Platform Leverage). Provides user safety and undo capability.

### deleteCard(slug:projectPath:)

**Signature:** `func deleteCard(slug: String, projectPath: String) throws`

**Purpose:** Delete a card by moving it to macOS Trash.

**Parameters:**
- `slug` — Card slug identifier
- `projectPath` — Absolute path to parent project directory

**Throws:**
- `cardNotFound` if card directory does not exist
- Underlying NSFileManager errors if trash operation fails

**Behavior:**
1. Construct path to `{projectPath}/cards/{slug}/`
2. Check card directory exists
3. Use `FileManager.trashItem(at:resultingItemURL:)` to move to Trash

**Notes:** Uses system Trash per L06. Provides user safety and undo capability.

## Environment Injection

**File:** `WorkspaceServiceEnvironmentKey.swift`

**Purpose:** Define SwiftUI environment key for injecting WorkspaceProviding service.

**Usage:**

```swift
// In App.swift:
let service = WorkspaceService()
.environment(\.workspaceService, service)

// In views:
@Environment(\.workspaceService) private var workspaceService
```

**Notes:** Environment injection decouples views from concrete service implementation, enabling testability and flexibility.

## Testing

WorkspaceService is tested via `WorkspaceServiceTests.swift` using temporary directories and mock filesystem operations. Tests cover:

- Config loading (success and failure cases)
- Project loading (including malformed frontmatter handling)
- Card loading (including missing fields and defaults)
- CRUD operations (create, update, delete)
- Unknown field preservation (round-trip tests)
- Trash operations (verifying files are moved, not deleted)

Tests use `FileManager.default` with temporary directories created via `FileManager.temporaryDirectory`.
