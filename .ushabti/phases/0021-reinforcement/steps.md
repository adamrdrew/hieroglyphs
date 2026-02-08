# Steps

## S001: Add triage status to CardStatus enum

**Intent:** Enable cards imported from Ushabti to be marked for human review before entering normal workflow.

**Work:**
- Add `triage` case to `CardStatus` enum in `Sources/Hieroglyphs/Models/CardStatus.swift`
- Raw value is `"triage"` (lowercase string)
- Position: between `backlog` and `todo` (logical workflow progression)

**Done when:**
- `CardStatus` enum includes `case triage` with raw value `"triage"`
- Enum still conforms to `String`, `Codable`, `CaseIterable`
- Code compiles without errors

---

## S002: Test triage status enum case

**Intent:** Verify triage status serializes and deserializes correctly.

**Work:**
- Add test cases to `CardStatusTests` (or create file if it doesn't exist)
- Test raw value encoding: `CardStatus.triage.rawValue == "triage"`
- Test decoding from string: `"triage"` decodes to `.triage`
- Test `CaseIterable` includes triage

**Done when:**
- Tests pass
- All CardStatus cases including triage are covered

---

## S003: Audit removeCardSymlinksFromPlans implementation

**Intent:** Determine if the method correctly handles hard links or incorrectly checks for symlinks.

**Work:**
- Read `PlanService.removeCardSymlinksFromPlans` implementation
- Verify whether it uses slug-based directory removal OR symlink resolution checks
- Document findings in implementation notes

**Done when:**
- Implementation reviewed
- Determination made: method is correct (slug-based) OR incorrect (symlink-specific)
- If incorrect, path forward is clear (use directory removal by slug match)

---

## S004: Fix or verify removeCardFromPlans logic

**Intent:** Ensure the method removes hard-linked card directories from plans correctly.

**Work:**
- If S003 found symlink-specific checks, replace with directory removal by slug match
- Method should enumerate plan directories, check for subdirectory named `{cardSlug}`, and remove it (regardless of whether it's a symlink, hard link, or plain directory)
- If S003 confirmed correct implementation, no change needed

**Done when:**
- Method removes card directories from plans by slug match (not symlink resolution)
- Implementation is agnostic to link type

---

## S005: Rename removeCardSymlinksFromPlans to removeCardFromPlans

**Intent:** Accurately describe the operation without assuming link type.

**Work:**
- Rename method in `PlanService` implementation
- Update protocol signature in `PlanProviding`
- Update `MockPlanService` to match
- Update all call sites in `HieroglyphsVM` (in `deleteSelectedItem()`)
- Update test references in `PlanServiceTests` and `HieroglyphsVMTests`

**Done when:**
- Method renamed consistently across all files
- All tests pass
- Code compiles without errors

---

## S006: Update plans-system.md documentation

**Intent:** Reflect the method rename and clarify that it handles all link types.

**Work:**
- Update `plans-system.md` to rename method references from `removeCardSymlinksFromPlans` to `removeCardFromPlans`
- Clarify that method removes card directories by slug match, agnostic to link type
- Update method signature documentation

**Done when:**
- Documentation reflects new method name
- Description clarifies slug-based removal approach

---

## S007: Implement ingestCardsFromUshabti in WorkspaceService

**Intent:** Provide service method to discover and import agent-created cards.

**Work:**
- Add `ingestCardsFromUshabti(projectPath:sourceDirectory:)` method to `WorkspaceProviding` protocol
- Implement in `WorkspaceService`:
  1. Return early if `sourceDirectory` is nil (no error)
  2. Construct path to `{sourceDirectory}/.ushabti/cards/`
  3. Return early if directory doesn't exist (no error)
  4. Enumerate subdirectories containing `card.md`
  5. For each card directory:
     - Parse `card.md` frontmatter
     - Check if slug already exists in `{projectPath}/cards/` (skip if duplicate)
     - Copy entire card directory to `{projectPath}/cards/{slug}/`
     - Override `status` field to `triage` in copied file
     - Delete source directory from `.ushabti/cards/{slug}/`
  6. Skip malformed cards with warning log
  7. Handle permission errors gracefully (log, continue to next card)
- Return count of successfully ingested cards (for observability)

**Done when:**
- Method signature added to protocol
- Implementation handles all error cases gracefully
- Returns integer count of ingested cards
- Malformed cards are skipped with warning
- Duplicate slugs are skipped (no overwrite)

---

## S008: Add mock ingestCardsFromUshabti to MockWorkspaceService

**Intent:** Enable testing of ingestion logic.

**Work:**
- Add `ingestCardsFromUshabti(projectPath:sourceDirectory:)` to `MockWorkspaceService`
- Track call count and parameters for verification
- Return configured count (default 0)

**Done when:**
- Mock method exists and matches protocol
- Can be configured in tests to return specific count

---

## S009: Test ingestCardsFromUshabti in WorkspaceServiceTests

**Intent:** Verify ingestion handles all cases correctly.

**Work:**
- Test successful ingestion: cards copied, status overridden to triage, source deleted
- Test duplicate detection: existing card slug is skipped
- Test missing sourceDirectory: returns 0, no error
- Test missing .ushabti/cards/: returns 0, no error
- Test malformed card (missing frontmatter): skipped with warning, does not throw
- Test partial success: one card succeeds, one malformed → returns 1

**Done when:**
- All test cases pass
- Tests verify count returned matches cards ingested
- Tests verify status override to triage
- Tests verify source deletion

---

## S010: Trigger ingestion on project load in HieroglyphsVM

**Intent:** Automatically discover and import agent-created cards when a project is selected.

**Work:**
- Update `loadCards()` method in `HieroglyphsVM`:
  - Before loading cards, check if `selectedProject.sourceDirectory` is non-nil
  - If so, call `workspaceService.ingestCardsFromUshabti(projectPath:sourceDirectory:)`
  - Log ingested count if > 0
  - Then proceed with normal `loadCards()` logic
- Ingestion errors are caught and logged (do not prevent card loading)

**Done when:**
- `loadCards()` triggers ingestion when `sourceDirectory` is set
- Cards load normally after ingestion
- Ingestion errors are logged but do not throw

---

## S011: Test ingestion trigger in HieroglyphsVMTests

**Intent:** Verify ViewModel calls ingestion before loading cards.

**Work:**
- Add test: mock project with sourceDirectory, verify `ingestCardsFromUshabti` is called
- Add test: mock project without sourceDirectory, verify ingestion is not called
- Add test: ingestion returns count > 0, verify cards are loaded after ingestion

**Done when:**
- Tests pass
- Mock service tracks ingestion calls
- Tests verify call order (ingest, then load)

---

## S012: Update workspace-service.md documentation

**Intent:** Document the ingestion method and triage workflow.

**Work:**
- Add section describing `ingestCardsFromUshabti(projectPath:sourceDirectory:)`
- Document parameters, return value, behavior, error handling
- Note status override to triage
- Note duplicate detection and source deletion

**Done when:**
- `workspace-service.md` includes complete documentation for ingestion method

---

## S013: Update viewmodel.md documentation

**Intent:** Document ingestion trigger on project load.

**Work:**
- Update `loadCards()` section to mention ingestion step
- Document that ingestion happens automatically when sourceDirectory is set
- Note error handling (logged, does not block card loading)

**Done when:**
- `viewmodel.md` reflects ingestion trigger in loadCards flow

---

## S014: Update models.md documentation

**Intent:** Document triage status in CardStatus enum.

**Work:**
- Add `triage` to CardStatus enum documentation
- Document raw value, position in workflow, and semantics (auto-discovered cards awaiting human review)

**Done when:**
- `models.md` includes triage status in CardStatus section

---

## S015: Run tests and lint

**Intent:** Verify all changes pass quality gates.

**Work:**
- Run `swift test` to verify all tests pass
- Run lint to verify no violations
- Fix any failures or violations

**Done when:**
- `swift test` exits with success
- Lint reports no violations

---

## S016: Fix enumerateLinkedCards to handle hard links

**Intent:** Correct the link-type filter bug that causes hard-linked cards to be skipped.

**Work:**
- Remove the `isSymbolicLink == true` check on line 183 of PlanService.swift
- Replace with directory detection logic: check if item is a directory AND contains a `card.md` file
- Skip items named "plan.yaml" and "PHASE_PROMPT.md" as before
- Logic should be:
  1. Enumerate items in plan directory
  2. Skip plan.yaml and PHASE_PROMPT.md
  3. Check if item is a directory (using isDirectory key)
  4. Check if directory contains card.md file
  5. If yes, append lastPathComponent to cardSlugs
- This approach works for symlinks, hard links, and regular directories containing card.md

**Done when:**
- Method no longer checks `isSymbolicLink`
- Method checks for directories containing card.md
- Hard-linked card directories are included in returned slugs
- Code compiles

---

## S017: Fix removeCardFromPlans to handle hard links

**Intent:** Correct the link-type guard that prevents hard-linked card cleanup.

**Work:**
- Remove the `isSymbolicLink == true` guard on line 468 of PlanService.swift
- Replace with simpler logic: if directory matching cardSlug exists, remove it
- Keep the fileExists check (line 461) to skip non-existent items
- Remove the resourceValues check entirely (lines 466-474) — it's a link-type filter masquerading as a safety check
- Removal logic should be:
  1. Check if item at symlinkURL.path exists (keep existing guard)
  2. Attempt to remove it
  3. Log warning on failure, continue to next plan
- This approach works for symlinks, hard links, and regular directories

**Done when:**
- Method no longer checks `isSymbolicLink`
- Method removes directories matching card slug regardless of link type
- Hard-linked card directories are cleaned up on card deletion
- Code compiles

---

## S018: Add hard-link test coverage

**Intent:** Verify that plans system works correctly with hard-linked cards.

**Work:**
- Add test to PlanServiceTests: `testEnumerateLinkedCardsWithHardLinks`
  - Create plan directory with hard-linked card subdirectory (directory copy, not symlink)
  - Verify `enumerateLinkedCards` returns the card slug
- Add test to PlanServiceTests: `testRemoveCardFromPlansWithHardLinks`
  - Create plan directory with hard-linked card subdirectory
  - Call `removeCardFromPlans`
  - Verify directory is removed
- Add test to PlanServiceTests: `testLoadPlansWithHardLinkedCards`
  - Create plan with hard-linked card directory containing card.md
  - Call `loadPlans`
  - Verify plan.linkedCardSlugs includes the hard-linked card

**Done when:**
- Three new tests added
- All tests pass
- Tests verify hard-link scenarios work correctly

---

## S019: Update plans-system.md with correct logic

**Intent:** Reconcile documentation with corrected implementation.

**Work:**
- Update `enumerateLinkedCards` documentation to describe directory+card.md detection
- Update `removeCardFromPlans` documentation to describe directory removal by slug match
- Remove references to "symlink-only" behavior
- Clarify that methods work with any directory structure (symlinks, hard links, regular directories)
- Update method descriptions to reflect link-type agnostic approach

**Done when:**
- Documentation describes directory-based detection (not symlink detection)
- Documentation accurately reflects corrected implementation
- No misleading claims about link types

---

## S020: Run tests and lint after corrections

**Intent:** Verify corrective work passes quality gates.

**Work:**
- Run `swift test` to verify all tests pass (including new hard-link tests)
- Run lint to verify no violations
- Fix any failures or violations

**Done when:**
- `swift test` exits with success (all tests including S018 tests pass)
- Lint reports no violations
