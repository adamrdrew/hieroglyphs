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
- `Project`: Represents a project with title, description, tags, timestamps, and slug
- `Card`: Represents a work item with type, status, priority, tags, and markdown body
- `WorkspaceConfig`: Holds workspace directory path
- `CardStatus`, `CardType`, `Priority`: Enums defining structured metadata options
- `CardSortOption`: Enum defining sort criteria for card lists (created, updated, priority, status, title)

**Dependencies:** Foundation only (for UUID, Date, Codable protocols)

**Notes:** Models have no business logic, no I/O, no UI knowledge. They are pure data structures.

### Services Layer

**Location:** `Sources/Hieroglyphs/Services/`

**Responsibility:** Handle all filesystem I/O, configuration loading, project/card discovery, and CRUD operations.

**Components:**
- `WorkspaceProviding`: Protocol defining the service contract
- `WorkspaceService`: Concrete implementation reading/writing files via FileManager and Yams
- `WorkspaceServiceEnvironmentKey`: SwiftUI environment key for dependency injection
- `FileWatching`: Protocol defining file system monitoring contract
- `FileWatcherService`: Concrete implementation using FSEventStream to monitor workspace
- `FileWatcherServiceEnvironmentKey`: SwiftUI environment key for FileWatcher injection

**Dependencies:** Foundation, Yams, FrontmatterParser, SlugGenerator

**Notes:** Services are stateless. They read from disk on every call and write atomically. No caching. This supports L01 (filesystem as truth) and L05 (external changes are first-class). FileWatcherService monitors workspace for external changes and triggers ViewModel reloads.

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

**Dependencies:** SwiftUI, Observation, WorkspaceProviding, FileWatching

**Notes:** ViewModel is a thin coordination layer. It does not perform I/O directly—it delegates to WorkspaceService. It holds transient UI state (selection) and cached data loaded from services. ViewModel starts file watching after workspace loads and handles file change events by triggering appropriate reloads.

### Views Layer

**Location:** `Sources/Hieroglyphs/Views/`

**Responsibility:** Render UI using SwiftUI, bind to ViewModel state, and handle user interactions.

**Components:**
- `MainWindow`: Root three-column NavigationSplitView
- `Sidebar/`: Project list UI with selection and creation sheets
  - `Sidebar`: List of projects with toolbar
  - `SidebarProjectEntry`: Individual project row with title and card count summary
  - `NewProjectSheet`: Form for creating new projects
- `CardList/`: Card list UI with search, filter, sort, and creation sheets
  - `CardList`: List of cards with search, filter, sort, and toolbar
  - `CardListEntry`: Individual card row with type icon, status, and priority indicator
  - `CardFilterBar`: Multi-select filter UI for status, type, and priority
  - `CardSortPopover`: Sort UI for criteria and order
  - `NewCardSheet`: Form for creating new cards

**Dependencies:** SwiftUI, HieroglyphsVM, WorkspaceProviding

**Notes:** Views are small, focused, and composable. They read state from ViewModel via `@Environment` and trigger actions via ViewModel methods. Views do not directly call services.

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
  ├─> HieroglyphsVM (created with WorkspaceService injected)
  └─> MainWindow
       └─> Sidebar (accesses ViewModel and WorkspaceService via @Environment)
            └─> SidebarProjectEntry (accesses WorkspaceService via @Environment)
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
- **Extended Attributes:** (Planned) For one-way tag projection from frontmatter
- **Spotlight (NSMetadataQuery):** (Planned) For search

## Future Architecture Extensions

- **Tag Reconciliation:** One-way projection of frontmatter tags to extended attributes
- **Spotlight Search:** NSMetadataQuery integration for fast search across workspace
- **Filter/Sort Persistence:** Persist filter and sort state to UserDefaults
- **Debounced Reloads:** Add debouncing to file watcher to reduce reload frequency on rapid changes
- **Granular Updates:** Diff file changes and update only affected items instead of reloading lists
