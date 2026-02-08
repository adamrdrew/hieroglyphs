# Hieroglyphs

A macOS-native markdown-based project management tool built with SwiftUI. Hieroglyphs manages structured markdown files with YAML frontmatter, enabling transparent, version-controlled project workflows that integrate seamlessly with AI assistants, command-line tools, and text editors.

## Features

- **Filesystem as source of truth** -- All data lives in plain text markdown files. No databases, no hidden state. Every project and card is a readable, editable `.md` file.
- **Three-column UI** -- NavigationSplitView with project sidebar, card list, and detail editor. Follows macOS design conventions.
- **Click-to-edit markdown** -- Card bodies render as formatted Markdown. Click to switch to a syntax-highlighted code editor. Press Escape to return to preview.
- **Real-time file watching** -- FSEvents monitors the workspace directory. External edits from text editors, AI assistants, or CLI tools appear in the UI within ~500ms.
- **Tag reconciliation** -- Frontmatter tags project one-way to macOS extended attributes. Cards and projects are tagged in Finder and searchable via Spotlight.
- **Spotlight search** -- NSMetadataQuery backend searches file content, titles, and tags across the workspace.
- **AI-first workflows** -- External changes are first-class, not edge cases. Unknown frontmatter fields are preserved on read/write. Workspace includes `CLAUDE.md` and `AGENT.md` for AI assistant context.

## Requirements

- macOS 26 (Tahoe) or later
- Swift 6.2+

## Building

Hieroglyphs is a Swift Package Manager project. No Xcode project files are used.

```bash
# Build the app bundle (release)
./Scripts/build-app.sh

# Launch it
open .build/Hieroglyphs.app

# Run tests
swift test
```

`build-app.sh` compiles a release build and assembles a proper macOS `.app` bundle at `.build/Hieroglyphs.app` with Info.plist and the correct bundle structure. You can also use `swift build` and `swift run` for quick debug iterations, but `swift run` launches as a bare executable without a menu bar or dock icon.

## Workspace Structure

Hieroglyphs stores configuration at `~/.hieroglyphs/config.yaml`:

```yaml
workspacePath: /path/to/your/workspace
```

The workspace directory contains projects and cards as plain markdown files:

```
workspace/
  my-project/
    project.md                # Project metadata (YAML frontmatter)
    cards/
      implement-feature/
        card.md               # Card metadata + markdown body
      fix-login-bug/
        card.md
  another-project/
    project.md
    cards/
      ...
```

### Project frontmatter

```yaml
---
id: 123e4567-e89b-12d3-a456-426614174000
title: My Project
description: A sample project
tags:
  - work
  - planning
created: 2026-01-15T10:30:00Z
updated: 2026-01-20T14:22:00Z
slug: my-project
---
```

### Card frontmatter

```yaml
---
id: 987fcdeb-51a2-43f1-8d0e-123456789abc
title: Implement Feature
type: feature          # task | bug | feature | note
status: in-progress    # backlog | todo | in-progress | done | archived
priority: high         # low | medium | high | critical
tags:
  - backend
  - api
created: 2026-01-16T09:00:00Z
updated: 2026-01-17T11:45:00Z
slug: implement-feature
---

Markdown body content goes here. Supports headings, lists, code blocks,
links, images, and all standard markdown formatting.
```

## Architecture

Hieroglyphs follows a layered MVVM architecture with protocol-based services:

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Models** | `Sources/Hieroglyphs/Models/` | Plain Swift structs and enums. No dependencies. |
| **Services** | `Sources/Hieroglyphs/Services/` | Protocol-based I/O (filesystem, FSEvents, Spotlight, xattr). Stateless. |
| **Utilities** | `Sources/Hieroglyphs/Utilities/` | Pure functions (frontmatter parsing, slug generation, markdown config). |
| **ViewModel** | `Sources/Hieroglyphs/HieroglyphsVM.swift` | Single `@Observable` coordinator. Delegates to services. |
| **Views** | `Sources/Hieroglyphs/Views/` | Small, composable SwiftUI views organized by feature. |

### Services

| Protocol | Implementation | Purpose |
|----------|---------------|---------|
| `WorkspaceProviding` | `WorkspaceService` | Filesystem I/O: config, project/card CRUD, Trash |
| `FileWatching` | `FileWatcherService` | FSEventStream monitoring for external changes |
| `TagReconciling` | `TagReconcilerService` | One-way tag projection to extended attributes |
| `SearchProviding` | `SpotlightService` | NSMetadataQuery content/title/tag search |

All services are injected via SwiftUI environment keys.

### Dependencies

| Package | Purpose |
|---------|---------|
| [CodeEditorView](https://github.com/mchakravarty/CodeEditorView) | Syntax-highlighted markdown editor |
| [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui) | Markdown rendering in SwiftUI |
| [Yams](https://github.com/jpsim/Yams) | YAML parsing and serialization |

## Working with External Tools

Hieroglyphs is designed for external editing. Any tool that can read and write markdown files works:

- **Text editors** (VS Code, Vim, etc.) -- Edit `card.md` or `project.md` directly. Changes appear in the UI automatically.
- **AI assistants** (Claude, etc.) -- Read `CLAUDE.md` in the workspace root for structure documentation. Create or edit cards by writing markdown files with YAML frontmatter.
- **CLI tools** -- Parse frontmatter with any YAML library. Create cards by writing files to the correct directory structure.
- **Version control** -- The workspace is plain text and Git-friendly. Track changes, branch, merge, and collaborate.

Unknown frontmatter fields are preserved on read/write. You can add custom fields (e.g., `owner: alice`, `estimate: 3d`) and Hieroglyphs will leave them intact.

## Testing

```bash
swift test
```

Tests cover all public APIs across models, utilities, services, and ViewModel. Services are tested via protocol interfaces with mock implementations. Views are not unit tested (SwiftUI limitation).

## License

All rights reserved.
