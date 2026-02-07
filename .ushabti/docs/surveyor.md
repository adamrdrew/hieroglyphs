# Surveyor Working Document

## Observations

### Architecture Overview

- **Type:** system
- **Location:** Entire codebase
- **Purpose:** Hieroglyphs is a macOS-native markdown-based project management tool following clean architecture principles
- **Key patterns:** MVVM with protocol-based services, plain data models, SwiftUI views, filesystem-first persistence
- **Dependencies:** SPM package targeting macOS 26 (Tahoe), uses CodeEditorView, swift-markdown-ui, Yams

### Domain Models

- **Type:** subsystem
- **Location:** Sources/Hieroglyphs/Models/
- **Purpose:** Plain Swift types representing workspace, project, and card entities with enum-based metadata
- **Key files:** Project.swift, Card.swift, WorkspaceConfig.swift, CardStatus.swift, CardType.swift, Priority.swift
- **Dependencies:** Foundation only (Identifiable, Codable, Equatable, Hashable protocols)
- **Notes:** Models are pure data structures with no business logic, supporting L09 (Sandi Metz)

### Workspace Service Layer

- **Type:** subsystem
- **Location:** Sources/Hieroglyphs/Services/
- **Purpose:** Protocol-based filesystem I/O for reading/writing workspace config, projects, and cards
- **Key files:** WorkspaceProviding.swift (protocol), WorkspaceService.swift (implementation), WorkspaceServiceEnvironmentKey.swift
- **Dependencies:** Foundation, Yams, FrontmatterParser, SlugGenerator
- **Notes:** Stateless service reads/writes files on demand, supports L01 (filesystem as truth) and L09 (protocol-based design)

### Parsing and Formatting Utilities

- **Type:** subsystem
- **Location:** Sources/Hieroglyphs/Utilities/
- **Purpose:** Parse and serialize markdown with YAML frontmatter, generate filesystem-safe slugs
- **Key files:** FrontmatterParser.swift, SlugGenerator.swift
- **Dependencies:** Foundation, Yams
- **Notes:** Pure utility functions with no side effects, support L02 (preserve unknown frontmatter)

### ViewModel Layer

- **Type:** subsystem
- **Location:** Sources/Hieroglyphs/HieroglyphsVM.swift
- **Purpose:** @Observable coordinator managing workspace state, project list, and selection for UI binding
- **Key files:** HieroglyphsVM.swift
- **Dependencies:** SwiftUI, Observation, WorkspaceProviding
- **Notes:** Single shared ViewModel injected via @Environment, delegates all I/O to WorkspaceService

### View Layer - Sidebar

- **Type:** subsystem
- **Location:** Sources/Hieroglyphs/Views/Sidebar/
- **Purpose:** Three-column NavigationSplitView sidebar displaying project list with selection and creation UI
- **Key files:** Sidebar.swift, SidebarProjectEntry.swift, NewProjectSheet.swift
- **Dependencies:** SwiftUI, HieroglyphsVM, WorkspaceProviding
- **Notes:** Follows TakeNote design patterns (L10), uses SF Symbols, small composable views

### View Layer - Main Window

- **Type:** subsystem
- **Location:** Sources/Hieroglyphs/Views/MainWindow.swift
- **Purpose:** Root window view with three-column NavigationSplitView scaffold
- **Key files:** MainWindow.swift
- **Dependencies:** SwiftUI
- **Notes:** Currently has placeholder "List" and "Detail" columns (to be implemented in future phases)

### Application Entry Point

- **Type:** subsystem
- **Location:** Sources/Hieroglyphs/App.swift
- **Purpose:** @main entry point initializing services, ViewModel, and window scene
- **Key files:** App.swift
- **Dependencies:** SwiftUI, HieroglyphsVM, WorkspaceService
- **Notes:** Dependency injection root, creates WorkspaceService and ViewModel, injects via .environment()

### Test Suite

- **Type:** subsystem
- **Location:** Tests/HieroglyphsTests/
- **Purpose:** Unit tests for models, utilities, services, and ViewModel
- **Key files:** ModelTests.swift, FrontmatterParserTests.swift, SlugGeneratorTests.swift, WorkspaceServiceTests.swift, HieroglyphsVMTests.swift
- **Dependencies:** XCTest
- **Notes:** Tests cover all public APIs per L11, use mocks for service protocols

## Plan

### Step 1: Architecture Overview

- **Status:** complete
- **Target doc:** architecture.md
- **Covers:** High-level system architecture, layer responsibilities, dependency flow, design principles
- **Notes:** Explains MVVM pattern, protocol-based services, filesystem-first approach, three-column UI

### Step 2: Domain Models

- **Status:** complete
- **Target doc:** models.md
- **Covers:** Project, Card, WorkspaceConfig, CardStatus, CardType, Priority models and their fields
- **Notes:** Documents data structures, field meanings, enum values, relationships

### Step 3: Workspace Service

- **Status:** complete
- **Target doc:** workspace-service.md
- **Covers:** WorkspaceProviding protocol, WorkspaceService implementation, read/write operations, error handling
- **Notes:** Documents all protocol methods, file paths, directory structure, frontmatter preservation

### Step 4: Frontmatter and Parsing

- **Status:** complete
- **Target doc:** frontmatter-parsing.md
- **Covers:** FrontmatterParser parse/serialize, YAML format, slug generation, unknown field preservation
- **Notes:** Documents markdown file format, frontmatter schema, parsing rules

### Step 5: ViewModel Layer

- **Status:** complete
- **Target doc:** viewmodel.md
- **Covers:** HieroglyphsVM responsibilities, state management, service delegation, environment injection
- **Notes:** Documents ViewModel methods, selection state, workspace loading, project creation flow

### Step 6: View Layer and UI

- **Status:** complete
- **Target doc:** views-ui.md
- **Covers:** MainWindow, Sidebar, SidebarProjectEntry, NewProjectSheet, TakeNote design patterns
- **Notes:** Documents three-column layout, project list display, card count computation, creation sheets

### Step 7: Testing Strategy

- **Status:** complete
- **Target doc:** testing.md
- **Covers:** Test organization, coverage requirements, mocking strategy, running tests
- **Notes:** Documents testing patterns per L11, mock usage, test file organization

### Step 8: Filesystem Structure

- **Status:** complete
- **Target doc:** filesystem-structure.md
- **Covers:** Workspace directory layout, config file location, project/card file structure, frontmatter format
- **Notes:** Documents on-disk format, file naming, directory conventions, example files
