# Docs Integration

## Overview

The Docs integration enables users to browse and view read-only documentation files from `.ushabti/docs/` directly within Hieroglyphs. This completes the development workflow loop by providing in-app access to project documentation maintained by Ushabti agents.

## Architecture

### Models

**Doc** (`Sources/Hieroglyphs/Models/Doc.swift`)

Plain data model representing a documentation file:

```swift
struct Doc: Identifiable, Equatable {
    let id: UUID
    let title: String
    let slug: String
    let filename: String
    let content: String

    var displayTitle: String {
        slug
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}
```

- `id`: Stable UUID generated from filename via namespace hashing
- `title`: Raw slug (filename without .md extension)
- `slug`: Lowercase filename without extension (used for sorting)
- `filename`: Full filename with .md extension
- `content`: Markdown file content as string
- `displayTitle`: Formatted title (hyphens replaced with spaces, capitalized words)

### Services

**DocsProviding Protocol** (`Sources/Hieroglyphs/Services/DocsProviding.swift`)

Defines the contract for loading documentation files:

```swift
protocol DocsProviding {
    func loadDocs(from docsDirectory: String) -> [Doc]
    func loadDocContent(path: String) -> String?
}
```

**DocsService** (`Sources/Hieroglyphs/Services/DocsService.swift`)

Concrete implementation:

- Enumerates `.md` files in the docs directory (non-recursive)
- Filters out hidden files (starting with `.`)
- Filters out non-markdown files
- Loads content for each file
- Sorts docs alphabetically by slug
- Returns empty array if directory doesn't exist

Injected via SwiftUI environment:

```swift
extension EnvironmentValues {
    var docsService: DocsProviding {
        get { self[DocsServiceEnvironmentKey.self] }
        set { self[DocsServiceEnvironmentKey.self] = newValue }
    }
}
```

### View Model Integration

**SidebarSection Enum**

Added `.docs(Project)` case:

```swift
enum SidebarSection: Hashable {
    case overview(Project)
    case cards(Project)
    case plans(Project)
    case phases(Project)
    case pharaoh(Project)
    case docs(Project)  // New
}
```

**HieroglyphsVM**

- `selectedDoc: Doc?` — Currently selected documentation file
- Selection cleared when switching sections or projects via `selectSection(_:)`

### Views

**DocsList** (`Sources/Hieroglyphs/Views/DocsList/DocsList.swift`)

Middle column view displaying documentation files:

- List of docs with `doc.text` SF Symbol (hierarchical rendering)
- Uses `displayTitle` for readable names
- Empty state: "No Documentation"
- Loads docs on appear and when project changes
- Uses `.id(project.id)` to reset state on project change (L17 compliance)

**DocsDetail** (`Sources/Hieroglyphs/Views/DocsDetail/DocsDetail.swift`)

Detail column view rendering markdown:

- Uses `Markdown()` from swift-markdown-ui for read-only rendering
- ScrollView wrapper for variable-length content
- Empty state: "No Documentation Selected"
- Uses `.id(selectedDoc.id)` to reset state on doc change (L17 compliance)
- Navigation title shows `displayTitle`

**Sidebar Integration**

Docs item shown in project disclosure group when `project.hasDocsDirectory == true`:

```swift
if project.hasDocsDirectory {
    Label("Docs", systemImage: "doc.text")
        .tag(SidebarSection.docs(project))
}
```

Positioned after Pharaoh item in sidebar hierarchy.

### Project Model Extension

**docsDirectory Field**

Added optional `docsDirectory: String?` to Project model:

```swift
struct Project: Identifiable, Codable, Equatable, Hashable {
    // ...
    let docsDirectory: String?
    // ...

    var hasDocsDirectory: Bool {
        docsDirectory != nil
    }
}
```

**WorkspaceService Integration**

- Reads `docs_directory` frontmatter field in `loadProjects(from:)`
- Writes `docs_directory` in `createProject(...)` and `updateProject(_:at:)` only when non-nil
- Preserves unknown frontmatter fields (L02 compliance)

## Navigation Flow

1. User selects project with `docsDirectory` set
2. "Docs" item appears in sidebar
3. User clicks "Docs"
4. `selectedSection` becomes `.docs(project)`
5. MainWindow shows `DocsList(project:)` in middle column
6. `DocsList` loads docs from `docsDirectory` via `docsService`
7. User selects a doc
8. `selectedDoc` updates in HieroglyphsVM
9. `DocsDetail` renders markdown content

## Design Decisions

### Read-Only by Design

Docs are managed by Ushabti agents, not Hieroglyphs. The UI is strictly read-only:

- No CodeEditorView for editing
- No save/update operations
- No doc creation or deletion UI
- Changes made externally by Ushabti are reflected on next load

### No Frontmatter Parsing

Unlike cards and projects, docs are treated as plain markdown:

- No YAML frontmatter extraction
- Entire file content rendered as-is
- Simplifies model and reduces complexity

### Directory Path Derivation

The `docsDirectory` path is typically derived as `{sourceDirectory}/.ushabti/docs/`:

- Not configurable separately in UI
- Automatically set when project has `sourceDirectory`
- Checked for existence before showing Docs item

### Top-Level Files Only

Docs directory is scanned non-recursively:

- Only `.md` files in the top level are shown
- Subdirectories are ignored
- Keeps listing simple and predictable

### Alphabetical Sorting

Docs are always sorted alphabetically by slug:

- No user-configurable sort order
- No filters or search within docs
- Future enhancement: integrate with SpotlightService for search

## Testing

**DocsServiceTests** (`Tests/HieroglyphsTests/DocsServiceTests.swift`)

Full test coverage:

- `testLoadDocsFromExistingDirectory` — Multiple docs loaded correctly
- `testLoadDocsFromEmptyDirectory` — Empty array returned
- `testLoadDocsFromMissingDirectory` — Empty array returned
- `testLoadDocsIsSortedAlphabetically` — Docs sorted by slug
- `testLoadDocContentWithExistingFile` — Content loaded correctly
- `testLoadDocContentWithMissingFile` — Nil returned
- `testDisplayTitleFormatsSlugCorrectly` — Hyphens replaced, capitalized
- `testLoadDocsIgnoresHiddenFiles` — `.hidden.md` filtered out
- `testLoadDocsIgnoresNonMarkdownFiles` — `.txt`, `.yaml` filtered out

All tests use temporary directories for isolation.

## Future Enhancements

1. **Search Integration** — Add docs content to SpotlightService indexing
2. **File Watching** — Detect external edits and refresh docs list
3. **Recursive Directory Support** — Nested docs with folder disclosure groups
4. **Table of Contents** — Auto-generated TOC from markdown headers
5. **Cross-References** — Clickable links between docs

## Related Documentation

- [Architecture Overview](architecture.md) — Overall system design
- [Phases View](phases-view.md) — Related Ushabti integration
- [Plans System](plans-system.md) — Another Ushabti integration point
- [Pharaoh Integration](pharaoh-integration.md) — AI-driven phase execution
- [View Layer and UI](views-ui.md) — Three-column navigation pattern
- [Workspace Service](workspace-service.md) — Project metadata persistence
