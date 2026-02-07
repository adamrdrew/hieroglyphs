# Hieroglyphs Documentation

## Project Name

Hieroglyphs

## Description

A macOS-native markdown-based project management tool built with SwiftUI. Manages structured markdown files with YAML frontmatter, enabling transparent, version-controlled project workflows that integrate seamlessly with AI assistants, command-line tools, and text editors.

## Table of Contents

- [Architecture Overview](architecture.md) — High-level system architecture, layers, and design principles
- [Domain Models](models.md) — Project, Card, WorkspaceConfig, and metadata enums
- [Workspace Service](workspace-service.md) — Protocol-based filesystem I/O for workspace, projects, and cards
- [Frontmatter Parsing](frontmatter-parsing.md) — YAML frontmatter parsing, serialization, and slug generation
- [ViewModel Layer](viewmodel.md) — HieroglyphsVM coordination, state management, and service delegation
- [View Layer and UI](views-ui.md) — Three-column NavigationSplitView, Sidebar, project list, and creation UI
- [Testing Strategy](testing.md) — Test organization, coverage requirements, and running tests
- [Filesystem Structure](filesystem-structure.md) — On-disk layout, file formats, and naming conventions
