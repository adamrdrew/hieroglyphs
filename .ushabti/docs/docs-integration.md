# Docs Integration

## Overview

The Docs integration enables users to browse and view read-only documentation files from `.ushabti/docs/` directly within Hieroglyphs. This completes the development workflow loop by providing in-app access to project documentation maintained by Ushabti agents.

Documentation is automatically detected when a project has a `sourceDirectory` containing a `.ushabti/docs/` folder with at least one markdown file. No explicit configuration is required.

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

- `id`: UUID generated at load time
- `title`: Raw slug (filename without .md extension)
- `slug`: Lowercase filename without extension (used for sorting)
- `filename`: Full filename with .md extension
- `content`: Markdown file content as string
- `displayTitle`: Formatted title (hyphens replaced with spaces, capitalized words)
- `extractedHeading`: First H1 heading from markdown, or `displayTitle` if no H1 found
- `excerpt`: First paragraph after H1 with markdown stripped, truncated to ~150 characters

### Services

**DocsProviding Protocol** (`Sources/Hieroglyphs/Services/DocsProviding.swift`)

Defines the contract for loading documentation files:

```swift
protocol DocsProviding {
    func hasDocsDirectory(sourceDirectory: String) -> Bool
    func loadDocs(from docsDirectory: String) -> [Doc]
    func loadDocContent(path: String) -> String?
}
```

- `hasDocsDirectory(sourceDirectory:)` — Checks if `.ushabti/docs/` exists within the source directory and contains at least one markdown file

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

Middle column view displaying documentation files with modern three-line layout:

- **Primary line**: `extractedHeading` in `.headline` font with `.primary` color
- **Secondary line**: Icon + `filename` in `.caption` font with `.secondary` color
- **Tertiary line**: `excerpt` in `.subheadline` font with `.tertiary` color (line limit 2)
- Empty state: "No Documentation"
- Loads docs on appear and when project changes
- Uses `.id(project.id)` to reset state on project change (L17 compliance)
- Uses system semantic colors and typography hierarchy (L18 compliance)

**DocsDetail** (`Sources/Hieroglyphs/Views/DocsDetail/DocsDetail.swift`)

Detail column view rendering markdown:

- Uses `Markdown()` from swift-markdown-ui for read-only rendering
- ScrollView wrapper for variable-length content
- Empty state: "No Documentation Selected"
- Uses `.id(selectedDoc.id)` to reset state on doc change (L17 compliance)
- Navigation title shows `displayTitle`

**Sidebar Integration**

Docs item shown in project disclosure group when docs directory is detected:

```swift
if project.hasDocsDirectory(docsService: docsService) {
    Label("Docs", systemImage: "doc.text")
        .tag(SidebarSection.docs(project))
}
```

Detection is filesystem-based via `DocsService.hasDocsDirectory(sourceDirectory:)`. Positioned after Pharaoh item in sidebar hierarchy.

### Project Model Extension

**hasDocsDirectory Method**

Projects now detect docs directories dynamically:

```swift
struct Project: Identifiable, Codable, Equatable, Hashable {
    // ...
    let sourceDirectory: String?
    // ...

    func hasDocsDirectory(docsService: DocsProviding) -> Bool {
        guard let sourceDirectory = sourceDirectory else {
            return false
        }
        return docsService.hasDocsDirectory(sourceDirectory: sourceDirectory)
    }
}
```

**No Frontmatter Field**

Unlike the previous implementation, there is no `docsDirectory` or `docs_directory` field. Detection is automatic based on the presence of `.ushabti/docs/` within the project's `sourceDirectory`.

## Navigation Flow

1. User selects project with `sourceDirectory` containing `.ushabti/docs/`
2. Sidebar checks `project.hasDocsDirectory(docsService:)` — if true, "Docs" item appears
3. User clicks "Docs"
4. `selectedSection` becomes `.docs(project)`
5. MainWindow shows `DocsList(project:)` in middle column
6. `DocsList` constructs docs path as `{sourceDirectory}/.ushabti/docs/` and loads via `docsService`
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

### Automatic Detection

The docs directory is automatically detected at `{sourceDirectory}/.ushabti/docs/`:

- No explicit configuration required in project frontmatter
- Detection happens at render time via `DocsService.hasDocsDirectory(sourceDirectory:)`
- Docs item appears in sidebar only when directory exists and contains at least one `.md` file
- External changes (docs added/removed by Ushabti) are reflected immediately on next navigation

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

Full test coverage for service methods:

- `testLoadDocsFromExistingDirectory` — Multiple docs loaded correctly
- `testLoadDocsFromEmptyDirectory` — Empty array returned
- `testLoadDocsFromMissingDirectory` — Empty array returned
- `testLoadDocsIsSortedAlphabetically` — Docs sorted by slug
- `testLoadDocContentWithExistingFile` — Content loaded correctly
- `testLoadDocContentWithMissingFile` — Nil returned
- `testDisplayTitleFormatsSlugCorrectly` — Hyphens replaced, capitalized
- `testLoadDocsIgnoresHiddenFiles` — `.hidden.md` filtered out
- `testLoadDocsIgnoresNonMarkdownFiles` — `.txt`, `.yaml` filtered out
- `testHasDocsDirectoryWithExistingDocsAndMarkdown` — Returns true when valid
- `testHasDocsDirectoryWithNoMarkdownFiles` — Returns false when only non-markdown
- `testHasDocsDirectoryWithMissingDirectory` — Returns false when directory missing
- `testHasDocsDirectoryWithNilSourceDirectory` — Returns false for empty string

Full test coverage for Doc model computed properties:

- `testExtractedHeadingWithH1Present` — Returns H1 text when present
- `testExtractedHeadingWithNoH1` — Falls back to displayTitle
- `testExcerptStripsMarkdown` — Bold, italic, links, code backticks removed
- `testExcerptTruncatesLongParagraphs` — Limited to ~150 chars with ellipsis
- `testExcerptHandlesEmptyContent` — Returns empty string when no paragraph

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
