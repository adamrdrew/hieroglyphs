# Phase 0017: Phases View (Ushabti Integration)

## Intent

Add a read-only Phases view that displays Ushabti phase data from a project's source code directory. When a user selects the "Phases" section for a project in the sidebar, the middle column shows a list of phases read from `{project.sourceDirectory}/.ushabti/phases/`, and selecting a phase displays its intent, steps, and review notes in the detail column.

This phase fills in the placeholder Phases view created in Phase 0016, enabling users to view phase-based development progress directly within Hieroglyphs without leaving the app.

## Scope

**In scope:**
- New model `Phase` (read-only value type with number, slug, title, status, intent, steps, reviewNotes)
- New enum `PhaseStatus` (planned, active, green, yellow, red)
- New struct `PhaseStep` (id, summary, implemented, reviewed)
- New protocol `PhaseProviding` and implementation `PhaseService` for reading phase data
- `PhaseService.loadPhases(from:)` discovers phase directories and parses phase.md, progress.yaml, review.md
- New view `PhaseList` (middle column when Phases selected) shows phase number, title, status
- New view `PhaseDetail` (right column when phase selected) shows intent, steps checklist, review notes
- Wire into MainWindow: `.phases(project)` section shows PhaseList, selecting phase shows PhaseDetail
- Add `selectedPhase: Phase?` to HieroglyphsVM
- Environment key for PhaseService injection
- Tests for PhaseService (parsing, error handling, missing files)
- Empty states for no sourceDirectory and no phases found

**Out of scope:**
- Writing phase files (read-only only)
- File watching for phase changes (phases live outside workspace)
- Editing phase data
- Creating new phases from UI
- Phase search or filtering
- Plans view (separate future phase)

## Constraints

**Laws:**
- **L01 (Filesystem as Source of Truth):** Read phase data from disk on demand, no caching
- **L09 (Sandi Metz Principles):** Protocol-based service, plain data models, small methods
- **L10 (TakeNote Design Consistency):** Three-column layout, SF Symbols, consistent spacing
- **L11 (Test Coverage):** All public methods in PhaseService must have tests

**Style:**
- PhaseService is separate from WorkspaceService (single responsibility principle)
- Read-only service (no write methods)
- Use Yams library for YAML parsing (already in project)
- Handle missing files gracefully (phase.md required, review.md optional)
- Small, focused views following existing patterns (CardList, CardDetail)
- No regex (use string methods for parsing directory names)

## Acceptance Criteria

1. **Phase model exists:** `Phase` struct with number, slug, title, status, intent, steps, reviewNotes fields
2. **PhaseStatus enum exists:** Cases for planned, active, green, yellow, red (matching progress.yaml values)
3. **PhaseStep struct exists:** Fields for id, summary, implemented, reviewed
4. **PhaseService protocol exists:** `PhaseProviding` protocol defines `loadPhases(from:) throws -> [Phase]`
5. **PhaseService implementation:** Discovers `.ushabti/phases/NNNN-slug/` directories, parses files, returns sorted phases
6. **Directory parsing:** Extracts number and slug from directory name (e.g., "0012-fix-typing-lag" → number: 12, slug: "0012-fix-typing-lag")
7. **YAML parsing:** Reads progress.yaml for title, status, steps array
8. **Markdown parsing:** Reads phase.md for intent text, review.md for review notes (gracefully handles missing review.md)
9. **PhaseList view:** Shows phases in List with number, title, status indicator (empty states for no sourceDirectory, no phases)
10. **PhaseDetail view:** Shows phase number/title, status badge, intent, steps checklist, review notes
11. **MainWindow integration:** Selecting `.phases(project)` section shows PhaseList, selecting phase shows PhaseDetail
12. **ViewModel integration:** `selectedPhase` property, `loadPhases()` method
13. **Empty state handling:** No sourceDirectory shows "Configure a source directory to view phases"
14. **Empty state handling:** No phases shows "No Ushabti phases found"
15. **Tests pass:** All PhaseService tests and existing tests pass
16. **Lint passes:** No lint violations
17. **Documentation updated:** New docs file for phases system or update to existing docs

## Risks / Notes

- **Read-only limitation:** Users cannot edit phases from Hieroglyphs. This is intentional to maintain Ushabti workflow integrity (Scribe/Builder/Overseer agents own phase files).
- **No file watching:** Phase files live outside the workspace, so FileWatcherService doesn't monitor them. Users must re-select the Phases section to refresh. This is acceptable for v1.
- **YAML parsing complexity:** progress.yaml has nested structure (phase metadata + steps array). Parser must handle missing optional fields gracefully.
- **Missing files:** Not all phases have review.md yet (only phases reviewed by Overseer). Service must handle this gracefully (empty reviewNotes string).
- **Status mapping:** progress.yaml uses lowercase status strings (planned, active, green, yellow, red). PhaseStatus enum must match these exactly.
