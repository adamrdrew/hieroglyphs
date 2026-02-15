# Architecture Overview

## Overview

Hieroglyphs follows a clean, layered architecture using the MVVM pattern with protocol-based services. The application is built with SwiftUI for macOS 26 (Tahoe) and prioritizes filesystem transparency, testability, and AI-first workflows.

## Core Design Principles

1. **Filesystem as Source of Truth** (L01): All state lives in plain text markdown files with YAML frontmatter. No databases, no hidden state. The app reconstructs all state from disk on demand.

2. **Protocol-Based Services** (L09): All I/O operations are abstracted behind protocols (`WorkspaceProviding`) for testability and flexibility. Services are stateless and injected via SwiftUI's environment system.

3. **Plain Data Models** (L09): Models are pure Swift structs and enums with no persistence logic. They conform to `Codable`, `Identifiable`, and other standard protocols but have no framework dependencies.

4. **MVVM with Single ViewModel** (Style): `HieroglyphsVM` is the single shared coordinator between services and views. It is `@Observable` and `@MainActor`, injected via `.environment()`.

5. **Three-Column NavigationSplitView** (L10): Follows TakeNote design patterns with sidebar (projects), list (cards), and detail (editor) columns.

## Layer Architecture

### Models Layer

**Location:** `Sources/Hieroglyphs/Models/`

**Responsibility:** Define domain entities as plain Swift types.

**Components:**
- `Project`: Represents a project with title, description, tags, timestamps, slug, optional sourceDirectory, and optional docsDirectory
- `Card`: Represents a work item with type, status, priority, tags, and markdown body
- `Plan`: Represents a development plan with number, title, status, linked cards, and phase prompt
- `Doc`: Represents a documentation file with title, slug, filename, and markdown content
- `WorkspaceConfig`: Holds workspace directory path
- `CardStatus`, `CardType`, `Priority`, `PlanStatus`: Enums defining structured metadata options
- `CardSortOption`: Enum defining sort criteria for card lists (created, updated, priority, status, title)
- `Phase`, `PhaseStatus`, `PhaseStep`: Read-only models for Ushabti phase data
- `PharaohStatus`: Enum representing Pharaoh server state (notRunning, idle, busy, done, blocked)

**Dependencies:** Foundation only (for UUID, Date, Codable protocols)

**Notes:** Models have no business logic, no I/O, no UI knowledge. They are pure data structures.

### Services Layer

**Location:** `Sources/Hieroglyphs/Services/`

**Responsibility:** Handle all filesystem I/O, configuration loading, project/card discovery, and CRUD operations.

**Components:**
- `WorkspaceProviding` / `WorkspaceService`: Filesystem I/O (config, project/card CRUD, Trash)
- `FileWatching` / `FileWatcherService`: FSEventStream monitoring for external changes
- `TagReconciling` / `TagReconcilerService`: One-way tag projection to extended attributes via xattr
- `SearchProviding` / `SpotlightService`: NSMetadataQuery search across content, titles, and tags
- `PhaseProviding` / `PhaseService`: Read-only Ushabti phase data loading from `.ushabti/phases/`
- `PlanProviding` / `PlanService`: Plan CRUD operations and card status synchronization
- `PharaohProviding` / `PharaohService`: Pharaoh server process management and status monitoring
- `DocsProviding` / `DocsService`: Read-only documentation file loading from `.ushabti/docs/`
- `PromptGenerating` / `PromptGenerator`: On-device phase prompt generation using FoundationModels
- Environment keys for each service (SwiftUI dependency injection)

**Dependencies:** Foundation, Yams, FrontmatterParser, SlugGenerator

**Notes:** Services are stateless (except FileWatcherService and PharaohService which manage process lifecycle). They read from disk on every call and write atomically. No caching. This supports L01 (filesystem as truth) and L05 (external changes are first-class). All services are injected via SwiftUI environment keys. PharaohService manages Pharaoh server process lifecycle via Foundation.Process and reads status/logs from `.pharaoh/` directory.

### Utilities Layer

**Location:** `Sources/Hieroglyphs/Utilities/`

**Responsibility:** Provide pure functions for parsing, formatting, and slug generation.

**Components:**
- `FrontmatterParser`: Parses and serializes markdown with YAML frontmatter
- `SlugGenerator`: Converts titles to filesystem-safe slugs

**Dependencies:** Foundation, Yams

**Notes:** Utilities have no side effects. They are pure functions that transform inputs to outputs.

### ViewModel Layer

**Location:** `Sources/Hieroglyphs/HieroglyphsVM.swift`

**Responsibility:** Coordinate workspace state, project list, and UI selection. Delegate all I/O to WorkspaceService. Coordinate file watching lifecycle.

**Components:**
- `HieroglyphsVM`: Single `@Observable` `@MainActor` class holding workspace state, project/card lists, selection state, and filter/sort state

**Dependencies:** SwiftUI, Observation, WorkspaceProviding, FileWatching, TagReconciling, SearchProviding, PhaseProviding

**Notes:** ViewModel is a thin coordination layer. It does not perform I/O directly—it delegates to services. It holds transient UI state (selection, filter, sort) and cached data loaded from services. ViewModel starts file watching after workspace loads, triggers tag reconciliation on file changes, coordinates Spotlight search, and loads phases when a project with a sourceDirectory is selected.

### Views Layer

**Location:** `Sources/Hieroglyphs/Views/`

**Responsibility:** Render UI using SwiftUI, bind to ViewModel state, and handle user interactions.

**Components:**
- `MainWindow`: Root three-column NavigationSplitView
- `Sidebar/`: Project list UI with selection and creation sheets
  - `Sidebar`: List of projects with toolbar and empty state
  - `SidebarProjectEntry`: Individual project row with title and card count summary
  - `NewProjectSheet`: Form for creating new projects
- `CardList/`: Card list UI with search, filter, sort, and creation sheets
  - `CardList`: List of cards with search, filter, sort, empty states, and toolbar
  - `CardListEntry`: Individual card row with type icon, status, and priority indicator
  - `CardFilterBar`: Multi-select filter UI for status, type, and priority
  - `CardSortPopover`: Sort UI for criteria and order
  - `NewCardSheet`: Form for creating new cards
- `CardDetail/`: Card editor with metadata and markdown body
  - `CardDetail`: Two-section layout with metadata editor and body editor
  - `CardMetadataEditor`: Form for title, type, status, priority, tag chips
  - `CardBodyEditor`: Click-to-edit markdown with preview/edit toggle
- `Shared/`: Reusable components
  - `TagChipView`: Pill-shaped tag chip with delete button

**Dependencies:** SwiftUI, HieroglyphsVM, WorkspaceProviding, CodeEditorView, MarkdownUI

**Notes:** Views are small, focused, and composable. They read state from ViewModel via `@Environment` and trigger actions via ViewModel methods. Views do not directly call services except SidebarProjectEntry (loads card counts).

### Application Entry Point

**Location:** `Sources/Hieroglyphs/App.swift`

**Responsibility:** Initialize services, create ViewModel, inject dependencies, and configure window scene.

**Components:**
- `HieroglyphsApp`: `@main` struct with Window scene

**Dependencies:** SwiftUI, HieroglyphsVM, WorkspaceService

**Notes:** App.swift is the dependency injection root. It creates concrete instances (WorkspaceService, HieroglyphsVM) and injects them via `.environment()`.

## Dependency Flow

```
App.swift
  ├─> WorkspaceService (created)
  ├─> FileWatcherService (created)
  ├─> TagReconcilerService (created)
  ├─> SpotlightService (created)
  ├─> PhaseService (created)
  ├─> PlanService (created)
  ├─> PharaohService (created)
  ├─> DocsService (created)
  ├─> PromptGenerator (created)
  ├─> HieroglyphsVM (created with all services injected)
  └─> MainWindow
       ├─> Sidebar (ViewModel + WorkspaceService via @Environment)
       │    ├─> SidebarProjectEntry (WorkspaceService for card counts)
       │    └─> SidebarPharaohItem (PharaohService for status)
       ├─> CardList (ViewModel, searchable, filter/sort)
       ├─> CardDetail (ViewModel, CodeEditorView, MarkdownUI)
       ├─> PlanList (ViewModel)
       ├─> PlanDetail (ViewModel, PharaohService, PromptGenerator)
       ├─> PhaseList (ViewModel)
       ├─> PhaseDetail (ViewModel)
       ├─> DocsList (ViewModel, DocsService)
       ├─> DocsDetail (ViewModel)
       └─> PharaohView (PharaohService for process management)
```

All dependencies flow downward. Views depend on ViewModel and services. Services depend on utilities. Models depend on nothing.

## State Management

- **Persistent State:** Lives in markdown files on disk. Workspace config at `~/.hieroglyphs/config.yaml`, projects in workspace directory.
- **Transient State:** Held in ViewModel (selected project, loaded project list). Not persisted across app launches.
- **Derived State:** Computed in views (card count summaries computed on demand by loading cards).

## Testing Strategy

- **Models:** Tested via encoding/decoding and equality checks.
- **Utilities:** Tested with input/output pairs (parse/serialize roundtrips).
- **Services:** Tested via protocol with mock implementations (no real filesystem I/O in tests).
- **ViewModel:** Tested with mock services to verify coordination logic.
- **Views:** Not unit tested (SwiftUI views tested manually or via UI tests).

Tests live in `Tests/HieroglyphsTests/` and cover all public APIs per L11 (Test Coverage).

## Platform Leverage

Hieroglyphs uses macOS-specific capabilities per L06 (Platform Leverage):

- **FileManager:** For directory scanning, file I/O, and Trash operations
- **FSEvents:** For detecting external file changes via FSEventStream
- **Extended Attributes:** One-way tag projection from frontmatter via xattr (TagReconcilerService)
- **Spotlight (NSMetadataQuery):** Content, title, and tag search across workspace (SpotlightService)
- **FoundationModels:** On-device AI for phase prompt generation (PromptGenerator)

## Future Architecture Extensions

- **Search UI:** Wire SpotlightService to `.searchable()` modifier and search results view
- **Filter/Sort Persistence:** Persist filter and sort state to UserDefaults
- **Debounced Reloads:** Add debouncing to file watcher to reduce reload frequency on rapid changes
- **Granular Updates:** Diff file changes and update only affected items instead of reloading lists
