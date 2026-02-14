# Review: Phase 0035 — UI Layout Fixes

## Summary

Phase 0035 implements three UI fixes: constraining the NewCardSheet body TextEditor to prevent unbounded modal growth, fixing the CardList empty state layout to prevent filter bar expansion, and adding plan deletion functionality with confirmation dialogs.

**Implementation quality is high.** The code follows laws and style correctly. All nine original steps were implemented. Documentation was reconciled. However, **tests are incomplete** — the new `deletePlan` public API lacks test coverage, violating L11. Additionally, the MockPlanService test infrastructure is missing the deletePlan stub, causing test compilation to fail.

Phase status set to **building**. Three follow-up steps added to complete test coverage and fix test infrastructure.

## Verified

**UI Layout Fixes (S001, S002):**
- ✓ NewCardSheet body TextEditor wrapped in ScrollView with `maxHeight: 300`
- ✓ TextEditor constrained with `minHeight: 100, maxHeight: 300`
- ✓ Modal frame remains fixed at `minWidth: 500, minHeight: 500`
- ✓ CardList Group has `.frame(maxHeight: .infinity)` to prevent filter bar expansion
- ✓ Empty state fills available space correctly

**Plan Deletion Protocol and Service (S003, S004):**
- ✓ PlanProviding.deletePlan protocol method added with correct signature and documentation
- ✓ PlanService.deletePlan implemented correctly:
  - Checks directory exists, throws `PlanError.planNotFound` if missing
  - Uses `FileManager.trashItem(at:resultingItemURL:)` per L06 (Platform Leverage)
  - Logs success to console
  - Throws `PlanError.fileWriteFailed` on error
- ✓ Implementation follows L06 (macOS Trash for reversible deletion)

**ViewModel Coordination (S005):**
- ✓ HieroglyphsVM.deletePlan method implemented correctly:
  - Guards for selectedProject and planService
  - Clears selectedPlan if deleted plan was selected
  - Calls loadPlans() to refresh list
  - Logs errors to console (does not throw)
- ✓ Method follows ViewModel coordination pattern from deleteProject/deleteCard

**UI Actions (S006, S007):**
- ✓ PlanListEntry context menu with "Delete Plan" option (destructive role, trash icon)
- ✓ Confirmation alert with plan title in message: "Are you sure you want to delete '{plan.title}'? This will move the plan to Trash."
- ✓ PlanDetail toolbar delete button (visible only when plan selected, destructive role, trash icon)
- ✓ Both actions use same confirmation alert pattern
- ✓ Alert buttons: Cancel (role: .cancel) and Delete (role: .destructive)
- ✓ Follows L18 (Design Is How It Works) — destructive actions require confirmation

**Documentation Reconciliation (S009):**
- ✓ plans-system.md updated with deletePlan documentation under PlanProviding Protocol section
- ✓ Documented method signature, parameters, throws, and behavior
- ✓ Notes deletion is reversible via Trash and does not delete linked cards
- ✓ views-ui.md updated:
  - PlanListEntry section documents context menu delete action
  - PlanDetail section documents toolbar delete button
  - NewCardSheet section notes TextEditor constraints
  - CardList section notes empty state layout fix

**Code Quality:**
- ✓ All code follows L09 (Sandi Metz principles) — small, focused methods with clear single responsibility
- ✓ Follows L06 (Platform Leverage) — uses FileManager.trashItem for macOS Trash
- ✓ Follows L17 (UI State Correctness) — modals have constrained dimensions, content scrolls
- ✓ Follows L18 (Design Is How It Works) — destructive actions use .destructive role and require confirmation
- ✓ No dead code, no regex, no law violations detected
- ✓ Naming is clear and intention-revealing

## Issues

**L11 Violation: Missing Test Coverage**

The `deletePlan` method was added as a new public API method in PlanProviding protocol and implemented in PlanService and HieroglyphsVM. **L11 states: "Every public API method MUST have tests."**

Current state:
- ✗ PlanService.deletePlan has **zero tests** (checked PlanServiceTests.swift)
- ✗ HieroglyphsVM.deletePlan has **zero tests** (checked HieroglyphsVMTests.swift)
- ✗ MockPlanService missing deletePlan stub → test compilation **fails**

Tests must cover:
1. **PlanService.deletePlan:**
   - Happy path: deletes plan directory via Trash
   - Error path: throws when plan not found
   - Linked card preservation: cards remain after plan deletion
2. **HieroglyphsVM.deletePlan:**
   - Calls service with correct parameters
   - Clears selectedPlan when deleted plan was selected
   - Reloads plans after deletion
   - Logs errors without crashing

**Test Compilation Failure:**

Running `swift test` produces compilation error:
```
error: type 'MockPlanService' does not conform to protocol 'PlanProviding'
note: protocol requires function 'deletePlan(planSlug:projectPath:)' with type '(String, String) throws -> ()'
```

MockPlanService (HieroglyphsVMTests.swift line 1717) is missing the deletePlan stub. This must be added to enable test compilation.

## Required Follow-ups

Three follow-up steps added to steps.md and progress.yaml:

**S010: Add deletePlan stub to MockPlanService**
- Add `shouldThrowOnDeletePlan` error flag
- Implement deletePlan method stub matching protocol signature
- Remove plan from mockPlans array when called
- Enable tests to compile

**S011: Add tests for PlanService.deletePlan**
- `testDeletePlanMovesDirectoryToTrash` — verify directory removed
- `testDeletePlanThrowsWhenPlanNotFound` — verify error handling
- `testDeletePlanPreservesLinkedCards` — verify cards remain

**S012: Add tests for HieroglyphsVM.deletePlan**
- `testDeletePlanCallsServiceAndReloadsPlans` — verify service call and reload
- `testDeletePlanClearsSelectedPlanWhenDeleted` — verify selection clearing
- `testDeletePlanLogsErrorOnFailure` — verify error logging

These steps satisfy L11's requirement for public API test coverage.

## Decision — Re-review After Test Coverage Fix

**Status:** COMPLETE (GREEN)

**Verdict:** Phase is **complete**. All three UI fixes are correctly implemented, documented, and tested. Builder successfully addressed all issues from the first review.

**Implementation quality is high:**
- All code follows laws and style
- All 12 steps implemented and verified
- All 277 tests pass with 0 failures
- Test coverage complete for all new public API methods
- Documentation reconciled with code changes

**Follow-up work from first review completed successfully:**

S010 (MockPlanService stub):
- ✓ `shouldThrowOnDeletePlan` flag added
- ✓ `deletePlan` method stub implemented
- ✓ Removes plan from `mockPlans` array by slug
- ✓ Tests compile successfully

S011 (PlanService.deletePlan tests):
- ✓ `testDeletePlanMovesDirectoryToTrash` — verifies directory removed
- ✓ `testDeletePlanThrowsWhenPlanNotFound` — verifies error handling
- ✓ `testDeletePlanPreservesLinkedCards` — verifies cards remain

S012 (HieroglyphsVM.deletePlan tests):
- ✓ `testDeletePlanCallsServiceAndReloadsPlans` — verifies service call and reload
- ✓ `testDeletePlanClearsSelectedPlanWhenDeleted` — verifies selection clearing
- ✓ `testDeletePlanLogsErrorOnFailure` — verifies error logging

**Acceptance Criteria Status — All Satisfied:**

NewCardSheet TextEditor:
- ✓ TextEditor wrapped in ScrollView with maxHeight: 300
- ✓ TextEditor has minHeight: 100, maxHeight: 300
- ✓ Typing beyond visible area triggers internal scroll
- ✓ Modal frame remains fixed at minWidth: 500, minHeight: 500
- ✓ No unbounded modal growth

CardList Filter Bar:
- ✓ Filter bar stays at intrinsic height when list is empty (Group has `.frame(maxHeight: .infinity)`)
- ✓ Empty state fills available space below filter bar
- ✓ Filter bar height consistent whether empty or populated
- ✓ No layout shift on state transition

Plan Deletion:
- ✓ PlanListEntry context menu with "Delete Plan" option (destructive role, trash icon)
- ✓ PlanDetail toolbar delete button (visible when plan selected, destructive role, trash icon)
- ✓ Both actions show confirmation alert with plan title in message
- ✓ Alert message: "Are you sure you want to delete '{plan.title}'? This will move the plan to Trash."
- ✓ Confirmation calls `viewModel.deletePlan(plan)` which moves directory to Trash
- ✓ Linked cards remain in workspace (only plan directory removed)
- ✓ Plans list refreshes and selection clears after deletion
- ✓ No crash if plan directory does not exist (PlanError.planNotFound thrown)
- ✓ **Test coverage complete** (6 tests for deletePlan: 3 service, 3 ViewModel)

**Phase weighed and found true.** GREEN.
