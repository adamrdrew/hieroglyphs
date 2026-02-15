# Phase 0045: Ushabti Docs Integration

## Intent

Integrate Ushabti project documentation from `.ushabti/docs/` into Hieroglyphs. Enable users to browse and view read-only documentation files directly in the application, completing the development workflow loop alongside Cards, Plans, Phases, and Pharaoh.

This phase detects the docs directory, stores its path in project metadata, and provides a Docs navigation section with a list of markdown files rendered as read-only content.

## Scope

**In scope:**
- Detect `.ushabti/docs/` directory when project has `sourceDirectory` set
- Add optional `docsDirectory` field to Project model
- Update WorkspaceService to read/write `docsDirectory` in project frontmatter
- Create `Doc` model representing a single documentation file
- Create `DocsProviding` protocol and `DocsService` for reading docs from filesystem
- Add `.docs(Project)` case to `SidebarSection` enum
- Create DocsList view (middle column) showing all docs in alphabetical order
- Create DocsDetail view (detail column) rendering markdown as read-only
- Add "Docs" navigation item to Sidebar project disclosure groups
- Handle empty state when no docs directory exists or directory is empty

**Out of scope:**
- Creating or editing docs (docs are managed by Ushabti agents, not Hieroglyphs)
- Indexing or searching docs content
- Docs directory configuration UI (derived automatically from `sourceDirectory`)
- Recursive directory traversal (only top-level `.md` files in `.ushabti/docs/`)
- Docs file watching (refresh on project selection is sufficient)

## Constraints

- **L01**: Filesystem as source of truth - docs loaded from disk on demand, no caching
- **L02**: Preserve unknown frontmatter fields when updating project metadata
- **L05**: External changes first-class - docs may be edited externally by Ushabti
- **L09**: Protocol-based DocsService, plain Doc model
- **L10**: Three-column NavigationSplitView pattern (sidebar → list → detail)
- **L17**: UI state correctness - reset detail view when doc selection changes
- **L18**: Native macOS design with system colors and SF Symbols
- **Style**: Read-only markdown rendering using swift-markdown-ui, no CodeEditorView

## Acceptance Criteria

1. Project model has optional `docsDirectory: String?` field
2. WorkspaceService reads/writes `docs_directory` frontmatter field (only when non-nil)
3. Doc model represents title, slug, filename, and markdown content
4. DocsProviding protocol defines `loadDocs(from:)` and `loadDocContent(path:)` methods
5. DocsService implements protocol, reading `.md` files from docs directory
6. SidebarSection has `.docs(Project)` case
7. Sidebar shows "Docs" item for projects with non-nil `docsDirectory`
8. DocsList displays all docs in alphabetical order with empty state
9. DocsDetail renders selected doc markdown as read-only
10. MainWindow routes `.docs` section to DocsList/DocsDetail views
11. Selecting different doc updates detail view immediately (L17)
12. Build passes via `./Scripts/build-app.sh`

## Risks / Notes

- Docs directory path is derived as `{sourceDirectory}/.ushabti/docs/` automatically (not configurable separately)
- If `.ushabti/docs/` directory doesn't exist but sourceDirectory is set, Docs item is hidden
- Docs are assumed to be markdown files with `.md` extension
- No frontmatter parsing for docs - they are plain markdown content
- Future enhancement: Add docs search integration with SpotlightService
