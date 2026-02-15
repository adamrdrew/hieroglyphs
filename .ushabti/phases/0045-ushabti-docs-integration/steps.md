# Steps

## S001: Add docsDirectory to Project model

**Intent:** Extend Project model to store optional docs directory path.

**Work:**
- Add `docsDirectory: String?` property to Project struct
- Update Project initializers to include docsDirectory parameter
- Add computed property `hasDocsDirectory: Bool` returning `docsDirectory != nil`

**Done when:** Project model compiles with docsDirectory field and computed property.

## S002: Update WorkspaceService to handle docsDirectory

**Intent:** Enable reading and writing docsDirectory in project frontmatter.

**Work:**
- Update `loadProjects(from:)` to read `docs_directory` frontmatter field (defaults to nil)
- Update `createProject(...)` to accept `docsDirectory` parameter (defaults to nil)
- Write `docs_directory` to frontmatter only when non-nil (similar to sourceDirectory)
- Update `updateProject(_:at:)` to write/remove `docs_directory` based on nil check
- Preserve unknown frontmatter fields per L02

**Done when:** WorkspaceService reads and writes docs_directory frontmatter field correctly.

## S003: Create Doc model

**Intent:** Define plain data model for documentation files.

**Work:**
- Create `Sources/Hieroglyphs/Models/Doc.swift`
- Define Doc struct with fields:
  - `id: UUID` (generated from filename for Identifiable)
  - `title: String` (filename without .md extension, formatted)
  - `slug: String` (filename without .md extension, lowercase)
  - `filename: String` (full filename with .md extension)
  - `content: String` (markdown content)
- Conform to Identifiable, Equatable
- Add computed property `displayTitle: String` formatting slug as title (replace hyphens with spaces, capitalize words)

**Done when:** Doc model compiles and conforms to required protocols.

## S004: Create DocsProviding protocol and DocsService

**Intent:** Define protocol-based service for reading docs from filesystem.

**Work:**
- Create `Sources/Hieroglyphs/Services/DocsProviding.swift` protocol with methods:
  - `loadDocs(from docsDirectory: String) -> [Doc]`
  - `loadDocContent(path: String) -> String?`
- Create `Sources/Hieroglyphs/Services/DocsService.swift` implementing protocol
- `loadDocs(from:)` implementation:
  - Check directory exists, return empty array if not
  - Enumerate `.md` files in directory (non-recursive)
  - For each file, create Doc with title from filename (strip .md, format)
  - Generate stable UUID from filename via `UUID(uuidString:)` with namespace
  - Load content via `loadDocContent(path:)`
  - Sort docs alphabetically by slug
- `loadDocContent(path:)` implementation:
  - Read file as UTF-8 string
  - Return nil if file doesn't exist or read fails
- Add DocsServiceEnvironmentKey for SwiftUI injection

**Done when:** DocsService compiles, loadDocs returns sorted Doc array, loadDocContent reads files.

## S005: Add .docs(Project) to SidebarSection

**Intent:** Enable navigation to docs section.

**Work:**
- Add `.docs(Project)` case to SidebarSection enum in HieroglyphsVM
- Update `selectedProject` computed property to extract project from .docs case
- Update `selectSection(_:)` to clear cross-section state (cards, plans, phases, docs)

**Done when:** SidebarSection compiles with .docs case and navigation state updates.

## S006: Add Docs item to Sidebar

**Intent:** Show Docs navigation option for projects with docs directory.

**Work:**
- In SidebarProjectEntry disclosure group, add "Docs" item after "Pharaoh"
- Show only when `project.hasDocsDirectory == true`
- Use SF Symbol `doc.text` with hierarchical rendering
- Tag with `.docs(project)`
- Apply same styling as other sidebar items

**Done when:** Sidebar shows Docs item for projects with docsDirectory set.

## S007: Create DocsList view

**Intent:** Middle column view listing all docs.

**Work:**
- Create `Sources/Hieroglyphs/Views/DocsList/DocsList.swift`
- Use List with ForEach over docs array
- Each row shows doc title with `doc.text` SF Symbol
- Empty state when docs array is empty: "No Documentation" with secondary text
- Load docs on appear and when selectedProject changes
- Store docs in @State, load via @Environment(\.docsService)
- Use `.id(selectedProject?.id)` to reset state on project change (L17)

**Done when:** DocsList displays docs, handles empty state, and resets on project change.

## S008: Create DocsDetail view

**Intent:** Detail column view rendering markdown as read-only.

**Work:**
- Create `Sources/Hieroglyphs/Views/DocsDetail/DocsDetail.swift`
- Use ScrollView with Markdown() from swift-markdown-ui
- Load full content on appear and when selectedDoc changes
- Show ProgressView while loading
- Show empty state when no doc selected: "Select a doc to view"
- Use `.id(selectedDoc?.id)` to reset state on doc change (L17)
- Apply standard markdown styling (system fonts, spacing)

**Done when:** DocsDetail renders selected doc markdown, handles empty state, resets on change.

## S009: Wire docs views to MainWindow

**Intent:** Route .docs section to DocsList and DocsDetail.

**Work:**
- In MainWindow, update middle/detail column switch statement
- Add `.docs(let project)` case showing DocsList and DocsDetail
- Pass selectedDoc binding to DocsDetail
- Handle doc selection in HieroglyphsVM (add `selectedDoc: Doc?` property)

**Done when:** MainWindow shows DocsList/DocsDetail when .docs section selected.

## S010: Inject DocsService in App.swift

**Intent:** Create and inject DocsService instance.

**Work:**
- In App.swift, create `let docsService = DocsService()`
- Inject via `.environment(\.docsService, docsService)`

**Done when:** DocsService available via environment in all views.

## S011: Add tests for DocsService

**Intent:** Test docs loading and content reading.

**Work:**
- Create `Tests/HieroglyphsTests/DocsServiceTests.swift`
- Test `loadDocs(from:)` with existing directory, empty directory, missing directory
- Test `loadDocContent(path:)` with existing file, missing file
- Test docs are sorted alphabetically
- Test title formatting (hyphens → spaces, capitalization)
- Use temporary directories for filesystem operations

**Done when:** All DocsService tests pass.

## S012: Update docs to document Docs integration

**Intent:** Add documentation for Docs feature.

**Work:**
- Update `.ushabti/docs/architecture.md` to mention DocsService and Doc model
- Update `.ushabti/docs/index.md` to add entry for Docs integration
- Create `.ushabti/docs/docs-integration.md` documenting:
  - Doc model structure
  - DocsService protocol and implementation
  - UI components (DocsList, DocsDetail)
  - Navigation pattern
  - Read-only rendering approach

**Done when:** Docs updated with Docs integration documentation.

## S013: Build verification

**Intent:** Verify build passes.

**Work:**
- Run `./Scripts/build-app.sh`
- Fix any compilation errors
- Verify no warnings introduced

**Done when:** Build exits 0 with no errors.
