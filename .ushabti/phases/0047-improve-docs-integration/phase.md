# Phase 0047: Improve Docs Integration

## Intent

Improve the Ushabti docs integration by implementing automatic detection of `.ushabti/docs/` directories and modernizing the doc list UI to match macOS first-party app quality standards.

Currently, docs require explicit `docs_directory` frontmatter configuration. This phase removes that requirement by automatically detecting `.ushabti/docs/` within the project's source directory. If the directory exists and contains markdown files, the Docs nav item appears. If not, it's hidden.

The current doc list UI is minimal — just an icon and filename. This phase upgrades it to a modern macOS design with clear information hierarchy: primary H1 heading extracted from the doc, secondary filename metadata, and a tertiary ellipsized excerpt from the first paragraph.

## Scope

**In scope:**
- Automatic detection of `.ushabti/docs/` directory (check existence + contains .md files)
- Remove `docsDirectory` field from Project model
- Remove `docs_directory` frontmatter handling from WorkspaceService
- Update `hasDocsDirectory` to check filesystem instead of model field
- Extract first H1 heading from markdown for list item primary text
- Extract and strip markdown from first paragraph for excerpt
- Modern list item layout with proper typography hierarchy and system colors
- Update DocsService tests for new detection logic
- Update docs integration documentation

**Out of scope:**
- File watching for docs directory (future enhancement)
- Recursive subdirectory support
- Table of contents generation
- Search integration

## Constraints

- **L01**: Filesystem as source of truth — check actual directory existence, not config
- **L05**: External changes are first-class — detection should work for externally added/removed docs
- **L09**: Sandi Metz principles — small focused methods for markdown parsing
- **L11**: Test coverage — all new public methods tested
- **L17**: UI state correctness — views reset properly on project change
- **L18**: Design is how it works — system colors, semantic typography, clear hierarchy
- **L19**: Build must pass
- **Style**: Information hierarchy (primary/secondary/tertiary), `.headline`/`.caption`/`.subheadline`, no hardcoded colors
- **CRITICAL**: Do NOT re-introduce the `generateStableUUID` bug. UUID generation must use `UUID()` directly, NOT stable namespace hashing.

## Acceptance Criteria

1. Projects no longer have `docsDirectory` field or `docs_directory` frontmatter
2. `hasDocsDirectory` computed property checks for `.ushabti/docs/` within `sourceDirectory`
3. DocsService has method to check if docs directory exists and has markdown files
4. Doc model has computed property for extracted H1 heading (falls back to displayTitle if none)
5. Doc model has computed property for stripped excerpt from first paragraph
6. DocsList uses modern three-line layout: H1 heading (headline), filename (caption+secondary), excerpt (subheadline+tertiary)
7. All system semantic colors used (no hardcoded literals)
8. Tests pass for automatic detection, H1 extraction, excerpt stripping
9. Build passes via `./Scripts/build-app.sh`
10. Documentation updated to reflect automatic detection

## Risks / Notes

- Markdown parsing must avoid regex (style rule: regex banned)
- H1 extraction should use simple string methods (find first line starting with `# `)
- Excerpt should stop at first blank line or 2-3 sentences
- UUID generation MUST use `UUID()` directly — stable hashing was removed due to bug
