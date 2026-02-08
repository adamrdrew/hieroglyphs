# Review: Phase 0018 — Plans

**Status:** GREEN - Phase Complete

**Reviewed by:** Ushabti Overseer

**Date:** 2026-02-08 (Final Review)

---

## Final Review Notes

**Previous Review:** YELLOW with one follow-up (delete PlansPlaceholder.swift)

**Final Verification:**

PlansPlaceholder.swift has been deleted and all references removed. The phase is now complete.

**Since Previous Review:**

Three bugs were identified and fixed:

1. **Card selection dialog empty on first presentation** - FIXED
   - AddCardToPlanSheet.onAppear now loads cards (line 54-56)
   - PlanList.onChange loads both plans and cards (line 26-28)

2. **Added cards didn't show up until refresh** - FIXED
   - HieroglyphsVM.loadPlans() re-selects plan by slug after reload (lines 320-328)

3. **Plan stayed in detail column when switching sections** - FIXED
   - MainWindow.detailColumnContent switches on selectedSection (lines 36-50)
   - HieroglyphsVM.selectSection() clears cross-section selections (lines 213-230)

**Outstanding Issue:**

- PlansPlaceholder.swift still exists (S015 not implemented)

---

## Findings

### Law Compliance

**L01 (Filesystem as Source of Truth):** ✓ PASS
- Plans stored as directories with plan.yaml and symlinks
- No database or hidden state
- All data reconstructable from filesystem

**L02 (Preserve Unknown Fields):** ✓ PASS
- `updatePlan()` reads existing YAML, merges fields, preserves unknown fields (lines 280-308 of PlanService.swift)
- Tests verify unknown field preservation (testUpdatePlanPreservesUnknownFields)

**L03 (No Xcode Project):** ✓ PASS
- No Xcode project files introduced
- Swift Package Manager structure maintained

**L04 (No SwiftData):** ✓ PASS
- No database frameworks used
- Plain Swift models

**L05 (External Changes First-Class):** ✓ PASS
- FileWatcher monitors `plans/` directories (HieroglyphsVM.swift line 645)
- External changes to plan.yaml and PHASE_PROMPT.md trigger UI reload

**L06 (Platform Leverage):** ✓ PASS
- Uses FileManager for symlink operations
- Relative symlinks for portability

**L07 (macOS Only):** ✓ PASS
- No cross-platform code

**L08 (Frontmatter as Tag Source):** N/A
- Plans do not use tags

**L09 (Sandi Metz Principles):** ✓ PASS
- PlanService is protocol-based
- Plan and PlanStatus are plain data models
- Dependencies injected via environment

**L10 (Design Consistency):** ✓ PASS
- Follows TakeNote patterns (three-column layout, SF Symbols, consistent spacing)

**L11 (Test Coverage):** ✓ PASS
- All public PlanService methods have tests (14 test cases)
- All tests pass
- Tests cover success paths, error handling, dangling symlinks

**L12 (No Dead Code):** ✓ PASS
- PlansPlaceholder.swift deleted
- Documentation updated to remove stale references
- No dead code detected

**L13-L16 (Docs Requirements):** ✓ PASS
- plans-system.md created with comprehensive documentation
- index.md, filesystem-structure.md, and models.md updated
- Docs reconciled with code

### Style Compliance

**Sandi Metz Rules:**
- PlanService is 425 lines (exceeds 100-line guideline)
  - Judgment: Acceptable. Service has 8 public methods + helpers. Breaking it up would reduce cohesion.
- Methods generally follow 5-line guideline with reasonable exceptions for complex operations

**SOLID Principles:** ✓ PASS
- Single responsibility maintained
- Protocol-based (open/closed)
- Dependency inversion via protocols

**No Regex:** ✓ PASS
- No regex usage detected

**Naming:** ✓ PASS
- Clear, descriptive names throughout
- No single-letter variables (except where unavoidable in closures)

### Acceptance Criteria Verification

1. **Create plan via PlanList toolbar button:** ✓ PASS
   - PlanList.swift lines 30-37 show toolbar button
   - NewPlanSheet.swift implements creation form
   - ViewModel.createPlan() called on save

2. **View all plans in middle column:** ✓ PASS
   - PlanList shown when .plans section selected (MainWindow.swift line 23)
   - List displays all plans with selection binding

3. **Select plan and see details:** ✓ PASS
   - PlanDetail shows number, title, status picker, linked cards, PHASE_PROMPT.md
   - Navigation title shows plan number and title

4. **Add card to plan (creates symlink):** ✓ PASS
   - AddCardToPlanSheet filters available cards
   - PlanService.addCardToPlan() creates relative symlink (line 327)
   - Test verifies symlink format: `../../cards/{card-slug}/`

5. **Remove card from plan:** ✓ PASS
   - Context menu on linked cards has "Remove from Plan" action
   - PlanService.removeCardFromPlan() deletes symlink

6. **Plan list shows card count:** ✓ PASS
   - PlanListEntry.swift line 16 shows card count from linkedCardSlugs.count

7. **Change plan status via picker:** ✓ PASS
   - PlanDetail lines 54-60 show status picker
   - Binding updates via updatePlanStatus()

8. **When plan status becomes "done", linked cards become "done":** ✓ PASS
   - PlanService.updatePlanStatus() (lines 355-375) calls markLinkedCardsAsDone()
   - markLinkedCardsAsDone() iterates cards, updates status to "done" (lines 377-411)
   - Test verifies card status updated (testUpdatePlanStatusToDonesMarksLinkedCardsAsDone)

9. **Dangling symlinks shown as "Missing":** ✓ PASS
   - PlanDetail lines 136-143 show warning icon + "Missing: {slug}"
   - Test verifies graceful handling (testLoadPlansHandlesDanglingSymlinksWithoutThrowing)

10. **Edit PHASE_PROMPT.md content:** ✓ PASS
    - PlanDetail lines 162-171 show TextEditor bound to phasePromptContent
    - onChange writes to disk via writePhasePrompt()

11. **PHASE_PROMPT.md persists to disk:** ✓ PASS
    - PlanService.writePhasePrompt() writes content atomically (lines 413-424)
    - Test verifies content persistence (testWritePhasePromptWritesContent)

12. **FileWatcher detects plan changes:** ✓ PASS
    - HieroglyphsVM.handleFileChange() detects plan.yaml and PHASE_PROMPT.md changes (line 645)
    - Reloads plans when changes detected

13. **Tests cover all public methods:** ✓ PASS
    - 14 test cases cover all PlanService methods
    - All tests pass

14. **Docs updated:** ✓ PASS
    - plans-system.md created
    - index.md, filesystem-structure.md, models.md updated

### Bug Fixes Since Previous Review

All three reported bugs have been verified as fixed:

1. **Card selection dialog empty (BUG-1):** ✓ FIXED
   - Root cause: Cards not loaded when AddCardToPlanSheet appeared
   - Fix: Added `.onAppear { viewModel.loadCards() }` to AddCardToPlanSheet
   - Fix: Added `.onChange(of: viewModel.selectedProject)` to PlanList that loads cards
   - Verification: Lines 54-56 of AddCardToPlanSheet.swift, lines 26-28 of PlanList.swift

2. **Added cards not visible until manual refresh (BUG-2):** ✓ FIXED
   - Root cause: loadPlans() replaced plans array, breaking selectedPlan binding
   - Fix: Capture selectedPlan.slug before reload, re-select by slug after
   - Verification: Lines 320-328 of HieroglyphsVM.swift
   - Pattern: Preserves selection across reloads

3. **Plan stayed in detail column when switching sections (BUG-3):** ✓ FIXED
   - Root cause: detailColumnContent checked individual selection properties instead of selectedSection
   - Fix: Switch detailColumnContent on selectedSection (matching middle column pattern)
   - Fix: Clear cross-section selections in selectSection()
   - Verification: Lines 36-50 of MainWindow.swift, lines 213-230 of HieroglyphsVM.swift

### Issues Found

**All previous issues resolved:**

1. ✓ **Dead Code (L12 Violation) - RESOLVED**
   - PlansPlaceholder.swift deleted
   - Documentation updated (.ushabti/docs/views-ui.md)
   - No references remain in codebase
   - Build and tests pass (190 tests, 0 failures)

### Design Notes

**PHASE_PROMPT.md Write Pattern:**
The implementation writes PHASE_PROMPT.md on every keystroke (no debouncing), which differs from CardDetail's debounced pattern. This is documented as intentional (plans-system.md line 168: "Changes are written to disk immediately"). However, this creates inconsistency in the codebase. For large phase prompts, this could cause performance issues (frequent I/O on every keystroke).

Recommendation: Not a blocker for this phase, but consider standardizing on debounced writes across the app in a future refactor.

---

## Verdict

**GREEN** - Phase Complete

The implementation is complete and meets all acceptance criteria. All reported bugs have been fixed. All laws are satisfied. All tests pass (190 tests, 0 failures). Build is clean. Documentation is reconciled.

The Plans system is production-ready:
- Plan creation, editing, and status management
- Card linking via symlinks
- PHASE_PROMPT.md editing
- FileWatcher integration for external changes
- Comprehensive test coverage (14 PlanService tests)
- Complete documentation

No follow-ups required. Phase marked complete.

---

## Notes

### Strengths

- Comprehensive test coverage (14 test cases, all passing)
- Clean protocol-based design
- Excellent handling of dangling symlinks
- Relative symlinks ensure workspace portability
- Documentation is thorough and well-integrated
- All three bug fixes are correct and well-implemented
- Selection preservation pattern (re-select by slug after reload) is elegant
- Cross-section selection clearing prevents UI inconsistency

### Build and Test Status

- Build: ✓ PASS (swift build completes successfully)
- Tests: ✓ PASS (all 14 PlanServiceTests pass, no failures in full suite)

### Code Quality

- No regex usage
- No unused imports
- Clear, descriptive naming
- Protocol-based service architecture
- Immutable models

The phase is well-executed. All blocking issues have been resolved. The implementation demonstrates:
- Clean protocol-based architecture
- Robust handling of edge cases (dangling symlinks)
- Excellent test coverage
- Clear documentation
- Proper integration with existing systems

**Weighed and found true. The Phase is complete.**
