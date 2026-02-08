# Phase 0021: Reinforcement

## Intent

Two targeted fixes to shore up data integrity before we build the automation layer. First, validate the correctness of `removeCardSymlinksFromPlans` which may incorrectly check for symlinks when plans actually use hard links. Second, implement an ingestion path for Ushabti agent-created cards in `.ushabti/cards/` so they flow into the Hieroglyphs library with `triage` status for human review.

These fixes prevent data corruption and close the feedback loop between Ushabti agents and Hieroglyphs.

## Scope

**In scope:**
- Audit and fix `PlanService.removeCardSymlinksFromPlans` to correctly handle hard links
- Rename the method to `removeCardFromPlans` to reflect actual operation (not link type specific)
- Update all protocol signatures, mock implementations, call sites, tests, and documentation
- Add `triage` status to `CardStatus` enum
- Implement ingestion logic in `WorkspaceService` to copy cards from `.ushabti/cards/` into the Hieroglyphs library
- Override imported card status to `triage` regardless of agent-set status
- Delete source cards after successful import to prevent re-import
- Trigger ingestion on project load (polling model)
- Handle missing sourceDirectory, missing `.ushabti/cards/`, malformed card files, and permission errors gracefully

**Out of scope:**
- FSEvents watching on `.ushabti/cards/` (polling on project load is sufficient)
- Write-back from Hieroglyphs to Ushabti (one-directional import only)
- UI for triggering manual ingestion
- Card schema validation beyond basic frontmatter parsing

## Constraints

**Laws:**
- L01 — Filesystem as Source of Truth: Ingestion is a file copy operation, source cards are deleted after import
- L02 — Preserve Unknown Fields: Ingestion preserves all frontmatter fields except status override
- L05 — External Changes First-Class: Agent-created cards are a core workflow, not an edge case
- L09 — Sandi Metz Principles: Protocol-based services, dependency injection
- L11 — Test Coverage: All new public methods must have tests

**Style:**
- Small methods (5 lines target)
- Protocol-based service methods
- Error handling follows "do your best" philosophy (skip malformed cards, log warnings)
- No regex

**Documentation:**
- `plans-system.md` — Update method name and documentation for card removal
- `workspace-service.md` — Document ingestion methods and triage status
- `viewmodel.md` — Document ingestion trigger on project load
- `models.md` — Document `triage` status in CardStatus enum

## Acceptance Criteria

**Hard link validation:**
- `PlanService.removeCardFromPlans` correctly removes hard-linked card directories from plans (directory removal by slug match, not symlink resolution)
- Method renamed from `removeCardSymlinksFromPlans` to `removeCardFromPlans`
- Protocol signature updated in `PlanProviding`
- `MockPlanService` updated to match
- All call sites in `HieroglyphsVM` updated
- All test references updated (4 in `PlanServiceTests`, 3 in `HieroglyphsVMTests`)
- `plans-system.md` documentation updated

**Ingestion:**
- `triage` case added to `CardStatus` enum
- Cards in `{project.sourceDirectory}/.ushabti/cards/{slug}/card.md` are discovered and imported on project load
- Imported cards appear in Hieroglyphs library at `{workspacePath}/{project-slug}/cards/{slug}/`
- Imported cards have `status: triage` regardless of source status
- Duplicate slugs are skipped (no overwrite of existing cards)
- Source cards are deleted from `.ushabti/cards/` after successful import
- Missing `sourceDirectory` is handled gracefully (no error, no import)
- Missing `.ushabti/cards/` directory is handled gracefully (no error, no import)
- Malformed card files are skipped with warning log
- Permission errors are handled gracefully (logged, no crash)
- `triage` status works with existing filter/sort/display logic in CardList
- All new public methods have tests
- Tests and lint pass

**Documentation:**
- `workspace-service.md` updated with ingestion methods
- `viewmodel.md` updated with ingestion trigger
- `models.md` updated with `triage` status

## Risks / Notes

**Method name audit:**
The existing implementation might already be correct (using directory removal by slug). If so, this is purely a rename and documentation update. If the implementation checks for symlinks via `destinationOfSymbolicLink`, it will need fixing to handle hard links correctly.

**Ingestion one-way:**
This is a move operation (copy + delete source), not a sync. Cards flow from Ushabti → Hieroglyphs. Once imported, the Hieroglyphs copy is authoritative. Ushabti does not write back to imported cards.

**Triage status semantics:**
`triage` is a distinct workflow state separate from `backlog`. Cards in triage require explicit human review to decide placement (`todo`, `backlog`, etc.). The user must manually change status from `triage` to move the card into normal workflow.

**Polling model:**
Ingestion happens on project load (when cards are loaded). This is simple and sufficient. FSEvents watching on `.ushabti/cards/` is deferred to a future phase if needed.
