# Phase 9: Tag Reconciler

## Intent

Implement one-way tag projection from frontmatter to macOS extended attributes. The `TagReconcilerService` reads tags from parsed frontmatter and writes them to the `com.apple.metadata:_kMDItemUserTags` extended attribute via the `xattr` command-line tool. This enables tags defined in version-controlled frontmatter to appear as native macOS file tags in Finder and Spotlight.

The reconciler triggers automatically when the file watcher detects changes to project or card files. The projection direction is strictly one-way: frontmatter to extended attributes, never the reverse. This enforces L08 (Frontmatter Is Tag Source of Truth).

## Scope

**In scope:**
- `TagReconciling` protocol defining the service contract
- `TagReconcilerService` concrete implementation using `xattr` command
- Integration with `FileWatcherService` to trigger reconciliation on file changes
- Reconciliation for both Project and Card tags
- Proper handling of empty tag arrays (clearing extended attributes)
- Environment key for dependency injection

**Out of scope:**
- Reading extended attributes back into frontmatter (violates L08)
- Manual reconciliation UI (automatic only in this phase)
- Batch reconciliation of entire workspace (single-file only in this phase)
- Tag validation or constraints
- Conflict detection between frontmatter and extended attributes

## Constraints

**Laws:**
- **L06 (Platform Leverage):** Use macOS extended attributes for tags
- **L08 (Frontmatter Is Tag Source of Truth):** Tags MUST be projected one-way from frontmatter to extended attributes. Never read extended attributes back into frontmatter.
- **L09 (Sandi Metz Principles):** Protocol-based service, dependency injection, single responsibility
- **L11 (Test Coverage):** All public methods must have tests

**Style:**
- Protocol-based service design (TagReconciling protocol + TagReconcilerService implementation)
- Small, focused methods (5 lines or fewer)
- No regex (use string methods for path parsing)
- Environment key for SwiftUI injection
- Error handling follows "do your best" philosophy (log errors, don't crash)

## Acceptance Criteria

1. **Protocol exists:** `TagReconciling` protocol defines `reconcileTags(for:at:)` method
2. **Service implementation:** `TagReconcilerService` implements protocol using `xattr` command
3. **Extended attribute format:** Tags written in plist XML format to `com.apple.metadata:_kMDItemUserTags`
4. **File watcher integration:** Changes to `project.md` or `card.md` trigger tag reconciliation
5. **Verification via mdls:** After creating a card with tags `["work", "urgent"]` and saving, `mdls {path}` shows tags in `kMDItemUserTags` field
6. **Verification via Finder:** Tags appear in Finder's Get Info panel
7. **Empty tags handled:** When tags array is empty, extended attribute is removed
8. **Tests pass:** All new tests and existing tests pass
9. **Lint passes:** No lint violations

## Risks / Notes

- **xattr command dependency:** This implementation uses the `xattr` command-line tool rather than direct extended attribute APIs. This is acceptable for v1, but future phases may replace it with native Swift APIs for better performance.
- **Plist format complexity:** Extended attribute values must be formatted as plist XML. The service will generate minimal valid plist structure.
- **File watcher overhead:** Every file change triggers reconciliation. This is acceptable for typical workspaces but may be optimized in future phases.
- **No conflict detection:** If a user manually changes tags in Finder, those changes will be silently overwritten on next reconciliation. This is correct per L08 but may surprise users initially.
