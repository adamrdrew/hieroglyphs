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
- [View Layer and UI](views-ui.md) — Three-column NavigationSplitView, Sidebar, CardList, and CardDetail with markdown editing
- [File Watching System](file-watching.md) — FSEvents-based monitoring for external changes and automatic UI refresh
- [Spotlight Search](spotlight-search.md) — NSMetadataQuery integration for content, title, and tag search
- [Tag Reconciliation](tag-reconciliation.md) — One-way tag projection from frontmatter to extended attributes
- [Phases View](phases-view.md) — Read-only Ushabti phase integration showing phase status, intent, steps, and review notes
- [Plans System](plans-system.md) — Plans group cards via symlinks and generate Ushabti phase prompts
- [Docs Integration](docs-integration.md) — Read-only documentation browser for .ushabti/docs/ markdown files
- [Pharaoh Integration](pharaoh-integration.md) — AI-driven phase execution workflow with dispatch queue and activity monitoring
- [Testing Strategy](testing.md) — Test organization, coverage requirements, and running tests
- [Filesystem Structure](filesystem-structure.md) — On-disk layout, file formats, and naming conventions
