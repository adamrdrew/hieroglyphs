# Steps

## S001: Remove docsDirectory from Project model

**Intent:** Eliminate the `docsDirectory` field from the Project model since detection will be automatic.

**Work:**
- Remove `docsDirectory: String?` field from Project struct
- Update `hasDocsDirectory` to become a method that takes `sourceDirectory` and checks filesystem
- Remove `docsDirectory` parameter from any Project initializers in tests

**Done when:** Project model has no `docsDirectory` field, tests compile and pass.

---

## S002: Remove docs_directory frontmatter handling

**Intent:** Remove all `docs_directory` frontmatter read/write logic from WorkspaceService.

**Work:**
- Remove `docs_directory` read in `loadProjects(from:)`
- Remove `docsDirectory` parameter from `createProject(...)`
- Remove `docs_directory` write in `createProject(...)` and `updateProject(_:at:)`
- Update WorkspaceService tests to not expect `docs_directory` field

**Done when:** WorkspaceService has no `docs_directory` frontmatter handling, tests pass.

---

## S003: Add automatic docs detection to DocsService

**Intent:** Implement method to check if a project has a valid docs directory.

**Work:**
- Add `hasDocsDirectory(sourceDirectory: String) -> Bool` method to DocsProviding protocol
- Implement in DocsService: check if `{sourceDirectory}/.ushabti/docs/` exists and contains at least one `.md` file
- Use FileManager to check directory existence and enumerate contents

**Done when:** DocsService can detect docs directory presence, method is testable.

---

## S004: Update Project model with filesystem-based check

**Intent:** Change `hasDocsDirectory` from stored property to method using DocsService.

**Work:**
- Change `hasDocsDirectory` to method: `func hasDocsDirectory(docsService: DocsProviding) -> Bool`
- Implement by calling `docsService.hasDocsDirectory(sourceDirectory:)` if `sourceDirectory` is non-nil
- Return false if `sourceDirectory` is nil

**Done when:** Project model has method-based docs check, compiles.

---

## S005: Update Sidebar to use new detection method

**Intent:** Pass DocsService to sidebar and use method-based check.

**Work:**
- Inject DocsService into Sidebar via environment
- Update `if project.hasDocsDirectory` to `if project.hasDocsDirectory(docsService: docsService)`
- Verify Docs nav item shows/hides correctly

**Done when:** Sidebar uses new detection, Docs item appears only when directory exists with markdown.

---

## S006: Add H1 extraction to Doc model

**Intent:** Extract the first H1 heading from markdown content for primary display.

**Work:**
- Add `var extractedHeading: String` computed property to Doc model
- Parse content line-by-line to find first line starting with `# ` (trim whitespace, check prefix)
- Strip the `# ` prefix and return trimmed result
- Fall back to `displayTitle` if no H1 found
- Use simple string methods, no regex

**Done when:** Doc model has `extractedHeading`, returns H1 when present, falls back gracefully.

---

## S007: Add excerpt extraction to Doc model

**Intent:** Extract and strip markdown from first paragraph for secondary display.

**Work:**
- Add `var excerpt: String` computed property to Doc model
- Find content after first H1 line
- Extract lines until first blank line (paragraph boundary)
- Strip markdown formatting (bold `**text**`, italic `*text*`, links `[text](url)`, code backticks)
- Limit to 2-3 sentences or ~150 characters
- Use simple string methods, no regex

**Done when:** Doc model has `excerpt`, strips markdown, truncates appropriately.

---

## S008: Modernize DocsList UI

**Intent:** Upgrade list item layout to modern macOS design with information hierarchy.

**Work:**
- Replace simple HStack with VStack layout
- Primary: `Text(doc.extractedHeading).font(.headline).foregroundStyle(.primary)`
- Secondary: `HStack` with doc icon + `Text(doc.filename).font(.caption).foregroundStyle(.secondary)`
- Tertiary: `Text(doc.excerpt).font(.subheadline).foregroundStyle(.tertiary).lineLimit(2)`
- Use `.symbolRenderingMode(.hierarchical)` for icon
- Ensure proper spacing (8-12pt between elements)

**Done when:** DocsList displays modern three-line layout with clear hierarchy, uses system colors.

---

## S009: Update DocsService tests

**Intent:** Add test coverage for new detection method.

**Work:**
- Add `testHasDocsDirectoryWithExistingDocsAndMarkdown` — returns true
- Add `testHasDocsDirectoryWithNoMarkdownFiles` — returns false
- Add `testHasDocsDirectoryWithMissingDirectory` — returns false
- Add `testHasDocsDirectoryWithNilSourceDirectory` — returns false
- Use temporary directories for test isolation

**Done when:** New detection method has full test coverage, all tests pass.

---

## S010: Update Doc model tests

**Intent:** Add test coverage for H1 extraction and excerpt generation.

**Work:**
- Add `testExtractedHeadingWithH1Present` — returns H1 text
- Add `testExtractedHeadingWithNoH1` — returns displayTitle
- Add `testExcerptStripsMarkdown` — bold, italic, links removed
- Add `testExcerptTruncatesLongParagraphs` — limited to ~150 chars
- Add `testExcerptHandlesEmptyContent` — returns empty string

**Done when:** H1 extraction and excerpt have full test coverage, all tests pass.

---

## S011: Update docs integration documentation

**Intent:** Document the automatic detection behavior and new UI design.

**Work:**
- Update `.ushabti/docs/docs-integration.md`
- Remove references to `docsDirectory` frontmatter field
- Document automatic detection of `.ushabti/docs/` within `sourceDirectory`
- Document new list item layout and information hierarchy
- Update "Design Decisions" section to explain automatic detection rationale

**Done when:** Documentation reflects automatic detection and modern UI, no stale references.

---

## S012: Verify build and final integration

**Intent:** Ensure everything compiles and works end-to-end.

**Work:**
- Run `./Scripts/build-app.sh` to verify compilation
- Run `swift test` to verify all tests pass
- Manually test: create project with `.ushabti/docs/`, verify Docs item appears
- Manually test: remove docs directory, verify Docs item disappears
- Manually test: doc list shows H1, filename, excerpt with proper hierarchy

**Done when:** Build passes, tests pass, manual verification confirms automatic detection and modern UI work correctly.
