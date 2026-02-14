# Phase 0035: UI Layout Fixes

## Intent

Fix three UI layout and interaction issues: constrain the new card modal's body TextEditor to prevent unbounded growth, prevent the filter bar from expanding when the card list is empty, and add plan deletion functionality with confirmation.

These fixes address L17 (UI State Correctness) and L18 (Design Is How It Works) violations. Modals must have constrained dimensions with scrollable content. Empty states must fill available space to prevent layout components from expanding inappropriately. Destructive actions require confirmation and appropriate visual treatment.

## Scope

**In scope:**
- NewCardSheet.swift: Add ScrollView and maxHeight constraint to Body TextEditor
- CardList.swift: Ensure empty state fills available space to prevent filter bar expansion
- PlanList.swift: Add context menu with delete option to PlanListEntry
- PlanDetail.swift: Add delete button to toolbar with confirmation
- PlanProviding protocol: Add deletePlan method
- PlanService: Implement deletePlan to move plan to Trash
- HieroglyphsVM: Add deletePlan method that cleans up state and delegates to service

**Out of scope:**
- Filter bar functionality changes (what it filters, how it works)
- Card list sorting or filtering logic
- Any other modals or sheets beyond NewCardSheet
- Plan archive functionality (deletion only)
- Multi-plan deletion or batch operations

## Constraints

**Laws:**
- L06 (Platform Leverage): Use macOS Trash for deletion via NSWorkspace or FileManager
- L09 (Sandi Metz): Keep methods small, focused, with clear single responsibility
- L17 (UI State Correctness): Modal content scrolls, container has constrained dimensions
- L18 (Design Is How It Works): Destructive actions use `.destructive` role and require confirmation

**Style:**
- Modal and Sheet Sizing: `.frame(maxWidth:maxHeight:)` on outer container, ScrollView inside for variable content
- Empty States: Empty state views fill available space with centered message, preventing adjacent UI from expanding
- Destructive Actions: Use `.destructive` role, require confirmation alert before irreversible operations

## Acceptance Criteria

**NewCardSheet TextEditor:**
- [ ] TextEditor wrapped in ScrollView with maxHeight constraint (300pt recommended)
- [ ] TextEditor has minHeight: 100, maxHeight: 300
- [ ] Typing beyond visible area triggers scroll within the editor
- [ ] Modal frame remains fixed at minWidth: 500, minHeight: 500
- [ ] No unbounded modal growth when typing long body content

**CardList Filter Bar:**
- [ ] When card list is empty, filter bar stays at intrinsic height (does not expand)
- [ ] Empty state view fills available space below filter bar (uses `.frame(maxHeight: .infinity)` or Spacer pattern)
- [ ] Filter bar height consistent whether list is empty or populated
- [ ] No visual layout shift when transitioning between empty and populated states

**Plan Deletion:**
- [ ] PlanListEntry has context menu with "Delete Plan" option (destructive role, trash icon)
- [ ] PlanDetail has toolbar delete button (visible only when plan selected, destructive role, trash icon)
- [ ] Both actions show confirmation alert with plan title in message
- [ ] Alert message: "Are you sure you want to delete 'Plan Title'? This will move the plan to Trash."
- [ ] Confirmation calls `viewModel.deletePlan(plan)` which moves plan directory to Trash
- [ ] Linked cards remain in workspace (only plan directory and symlinks are removed)
- [ ] After deletion, plans list refreshes and selection clears
- [ ] No crash or error if plan directory does not exist

## Risks / Notes

**Risk:** CardList empty state fix may require adjusting VStack layout or adding `.frame(maxHeight: .infinity)` to the Group. This could affect other list views if pattern is reused.

**Mitigation:** Apply fix narrowly to CardList. Document pattern in review for future reference.

**Note:** Plan deletion follows the same pattern as Project deletion (Sidebar.swift) and Card deletion (CardList.swift context menu). All three use confirmation alerts with `.destructive` role and move to Trash.

**Note:** Deleting a plan does not delete linked cards. Cards remain in the workspace. Only the plan directory (containing plan.yaml, PHASE_PROMPT.md, and symlinks) is moved to Trash. This is reversible via macOS Trash.
