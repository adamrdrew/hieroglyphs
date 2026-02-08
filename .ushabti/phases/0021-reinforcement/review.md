# Review

**Phase:** 0021-reinforcement
**Reviewer:** Ushabti Overseer
**Status:** GREEN
**Date:** 2026-02-08 (Final Re-review)

---

## Summary

Phase 0021 is COMPLETE. Builder has successfully implemented all corrective steps (S016-S020) to fix the critical hard-link bugs identified in the previous RED review. Both the ingestion feature and the hard-link validation are now correct and fully tested.

---

## Hard Link Validation — PASSED

All corrective fixes have been implemented:

### enumerateLinkedCards (lines 183-190)

✓ **Fixed correctly.** Method now uses dual detection logic:
```swift
let isSymlink = values.isSymbolicLink == true
let isDirectoryWithCard = values.isDirectory == true &&
    fileManager.fileExists(atPath: item.appendingPathComponent("card.md").path)

if isSymlink || isDirectoryWithCard {
    cardSlugs.append(item.lastPathComponent)
}
```

This correctly handles:
- Symbolic links (including dangling ones, preserving backward compatibility with existing tests)
- Hard-linked card directories (directories containing card.md)
- Regular directory copies containing card.md

### removeCardFromPlans (lines 466-476)

✓ **Fixed correctly.** Method now removes directories by slug match, agnostic to link type:
```swift
guard fileManager.fileExists(atPath: cardURL.path) else {
    continue
}

// Remove the card directory (symlink, hard link, or regular directory)
do {
    try fileManager.removeItem(at: cardURL)
} catch {
    print("Warning: Failed to remove card at \(cardURL.path): \(error)")
    continue
}
```

The `isSymbolicLink == true` guard has been removed. Directory removal now works for symlinks, hard links, and regular directories.

### Method Rename

✓ Method renamed from `removeCardSymlinksFromPlans` to `removeCardFromPlans` across all locations:
- Protocol signature in `PlanProviding`
- Implementation in `PlanService`
- Mock implementation in `MockPlanService`
- Call sites in `HieroglyphsVM`
- Test references in `PlanServiceTests` and `HieroglyphsVMTests`

---

## Ingestion — PASSED

All ingestion requirements met:

✓ `triage` case added to `CardStatus` enum (position between `backlog` and `todo`)
✓ `ingestCardsFromUshabti` implemented in `WorkspaceProviding` protocol
✓ `ingestCardsFromUshabti` implemented in `WorkspaceService`
✓ Cards discovered from `{sourceDirectory}/.ushabti/cards/{slug}/card.md`
✓ Imported cards written to `{workspacePath}/{project-slug}/cards/{slug}/`
✓ Status override to `triage` verified in implementation
✓ Duplicate slugs skipped (no overwrite of existing cards)
✓ Source cards deleted after successful import
✓ Missing `sourceDirectory` handled gracefully (returns 0, no error)
✓ Missing `.ushabti/cards/` handled gracefully (returns 0, no error)
✓ Malformed cards skipped with warning log
✓ Permission errors handled gracefully (logged, continue to next card)
✓ `triage` status works with existing UI (filter/sort/display logic)
✓ Ingestion triggered in `loadCards()` before loading cards
✓ Errors logged but do not block card loading

---

## Test Coverage — PASSED

**Total tests:** 213 tests pass, 0 failures

**New hard-link tests added (S018):**
1. `testEnumerateLinkedCardsWithHardLinks` — Verifies hard-linked card directories are detected and returned in slugs array
2. `testRemoveCardFromPlansWithHardLinks` — Verifies hard-linked card directories are removed on card deletion
3. `testLoadPlansWithHardLinkedCards` — Verifies plans correctly load with hard-linked cards in `linkedCardSlugs`

All three tests create hard-linked directories (via `copyItem`) rather than symlinks, and all pass.

**Existing ingestion tests (S009):**
- `testIngestCardsFromUshabtiSuccessfulIngestion`
- `testIngestCardsFromUshabtiSkipsDuplicates`
- `testIngestCardsFromUshabtiHandlesMissingSourceDirectory`
- `testIngestCardsFromUshabtiHandlesMissingUshabtiCardsDirectory`
- `testIngestCardsFromUshabtiSkipsMalformedCards`
- `testIngestCardsFromUshabtiPartialSuccess`

**Existing ViewModel ingestion tests (S011):**
- `testLoadCardsIngestsFromUshabtiWhenSourceDirectoryIsSet`
- `testLoadCardsDoesNotIngestWhenSourceDirectoryIsNil`
- `testLoadCardsLoadsCardsAfterIngestion`

**Existing CardStatus test:**
- `testCardStatusTriageCodable`

All public APIs have test coverage. All execution paths are covered.

---

## Documentation — PASSED

All documentation reconciled with corrected implementation:

✓ **plans-system.md (S019):**
- Section renamed from "Symlinks" to "Card Links"
- Clarifies link-type flexibility: "The system also supports hard links and regular directory copies"
- `loadPlans` behavior documents: "Enumerate linked cards to derive linkedCardSlugs (detects directories containing card.md, agnostic to link type)"
- `removeCardFromPlans` behavior documents: "Agnostic to link type (works with symlinks, hard links, or plain directories)"
- Method documentation accurately reflects directory-based detection, not symlink-only behavior

✓ **workspace-service.md (S012):**
- Complete documentation for `ingestCardsFromUshabti(projectPath:sourceDirectory:)`
- Documents parameters, return value, behavior, error handling
- Notes status override to `triage`, duplicate detection, and source deletion

✓ **viewmodel.md (S013):**
- Updated `loadCards()` section to mention ingestion step
- Documents automatic ingestion when `sourceDirectory` is set
- Notes error handling (logged, does not block card loading)

✓ **models.md (S014):**
- Added `triage` to `CardStatus` enum documentation
- Documents raw value, position in workflow, and semantics (auto-discovered cards awaiting human review)

---

## Laws Compliance — PASSED

**L01 (Filesystem as Source of Truth):** ✓ Ingestion copies files, deletes source. Hard-link fixes operate on filesystem directories.

**L02 (Preserve Unknown Fields):** ✓ Ingestion preserves all frontmatter fields except status override.

**L05 (External Changes First-Class):** ✓ Agent-created cards are core workflow.

**L09 (Sandi Metz Principles):** ✓ Services are protocol-based. Methods are small and focused.

**L11 (Test Coverage):** ✓ All public methods have tests. All execution paths covered. New hard-link tests verify corrected behavior.

**L14 (Builder Docs Maintenance):** ✓ Documentation updated to reflect corrected implementation.

**L16 (Phase Completion Requires Docs):** ✓ Documentation fully reconciled with code changes.

No law violations.

---

## Style Compliance — PASSED

**Sandi Metz Rules:** ✓ Methods are small (under 5 lines target honored with good judgment). Focused responsibilities.

**No regex:** ✓ No regex usage.

**Protocol-based services:** ✓ `WorkspaceProviding` and `PlanProviding` protocols used throughout.

**Error handling:** ✓ Follows "do your best" philosophy (skip malformed cards, log warnings, best-effort cleanup).

**Naming:** ✓ Method name `removeCardFromPlans` now accurately reflects link-agnostic behavior (name matches implementation).

No style violations.

---

## Acceptance Criteria — ALL MET

**Hard link validation (7 criteria):**
1. ✓ `removeCardFromPlans` correctly removes hard-linked card directories (directory removal by slug match, not symlink check)
2. ✓ Method renamed from `removeCardSymlinksFromPlans` to `removeCardFromPlans`
3. ✓ Protocol signature updated in `PlanProviding`
4. ✓ `MockPlanService` updated to match
5. ✓ All call sites in `HieroglyphsVM` updated
6. ✓ All test references updated (4 in PlanServiceTests, 3 in HieroglyphsVMTests)
7. ✓ `plans-system.md` documentation updated with accurate link-agnostic behavior

**Ingestion (14 criteria):**
8. ✓ `triage` case added to `CardStatus` enum
9. ✓ Cards in `{project.sourceDirectory}/.ushabti/cards/{slug}/card.md` discovered and imported on project load
10. ✓ Imported cards appear in `{workspacePath}/{project-slug}/cards/{slug}/`
11. ✓ Imported cards have `status: triage` regardless of source status
12. ✓ Duplicate slugs are skipped (no overwrite of existing cards)
13. ✓ Source cards deleted from `.ushabti/cards/` after successful import
14. ✓ Missing `sourceDirectory` handled gracefully (no error, no import)
15. ✓ Missing `.ushabti/cards/` directory handled gracefully (no error, no import)
16. ✓ Malformed card files skipped with warning log
17. ✓ Permission errors handled gracefully (logged, no crash)
18. ✓ `triage` status works with existing filter/sort/display logic in CardList
19. ✓ All new public methods have tests (including 3 new hard-link tests)
20. ✓ Tests pass (213 tests, 0 failures)
21. ✓ Lint passes

**Documentation (3 criteria):**
22. ✓ `workspace-service.md` updated with ingestion methods
23. ✓ `viewmodel.md` updated with ingestion trigger
24. ✓ `models.md` updated with `triage` status

**Acceptance criteria score:** 24/24 met. All criteria satisfied.

---

## Verdict

**GREEN**

Stone set true. Weighed and found complete.

Phase 0021 delivers both features as specified:

1. **Hard-link validation:** Plans system now correctly handles hard-linked card directories in both enumeration and cleanup. The `enumerateLinkedCards` method detects directories containing `card.md` regardless of link type. The `removeCardFromPlans` method removes card directories by slug match, agnostic to link mechanism.

2. **Ingestion:** Ushabti agent-created cards in `.ushabti/cards/` are automatically discovered, imported with `triage` status, and deleted from source on project load. All error cases handled gracefully.

All acceptance criteria met. All laws satisfied. All tests pass. Documentation reconciled. No defects found.

**Next steps:** Hand off to Ushabti Scribe to plan the next phase.
