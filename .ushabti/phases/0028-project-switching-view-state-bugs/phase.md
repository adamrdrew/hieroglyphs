# Phase 0028: Project Switching View State Bugs

## Intent

Fix all navigation state bugs that cause stale content to persist when switching between projects. Ensure views always reflect the currently selected project's data, with no stale state from previous selections.

## Scope

**In scope:**
- Clear all detail selections (selectedCard, selectedPhase, selectedPlan) when the project changes
- Apply `.id(selectedProject?.id)` to middle and detail column views in MainWindow to force view recreation on project change
- Reset local @State in views that persist across project changes
- Verify empty states display correctly when selections are cleared
- Remove stale-selection preservation logic from loadCards(), loadPhases(), and loadPlans()

**Out of scope:**
- Changes to file watching mechanisms (working correctly)
- Changes to data loading logic beyond selection preservation removal
- New state management frameworks or reactive patterns
- UI redesign or layout changes

## Constraints

Refer to L17 (UI State Correctness) and the "SwiftUI UX Patterns — Navigation State Reset" section of style.md. These patterns are now project law.

Do NOT introduce new state management frameworks. Use SwiftUI's built-in `.id()`, `onChange(of:)`, and `onAppear` mechanisms.

Do NOT add workarounds that mask the problem (e.g., forcing timer refreshes). Fix the state management so views correctly reflect context.

Preserve existing functionality — data loading, file watching, Pharaoh monitoring must continue to work correctly after the fix.

## Acceptance Criteria

1. Switching between projects in the sidebar immediately shows the new project's data in all views (cards, plans, phases, pharaoh)
2. The detail pane shows an empty state (not stale content) after switching projects
3. Pharaoh status polling reads from the correct project's `.pharaoh/` directory after switching
4. Event stream shows the correct project's events after switching
5. Local UI state (filter bar, sort popover, sheets) does not persist across project switches
6. Switching back to the original project works correctly (no cached stale state from the first visit)
7. All existing tests pass
8. Manual testing confirms views reset correctly on project switch for all section types

## Risks / Notes

This phase addresses the root cause of two filed cards:
- **switching-between-pharaoh-in-different-projects-doesnt-work** (CRITICAL)
- **reset-views-on-project-switch** (LOW)

The fix is primarily architectural (state management) rather than UI layout. Most changes will be in HieroglyphsVM.swift and MainWindow.swift.

The `.id()` modifier is the most effective fix — it forces SwiftUI to destroy and recreate views when the project changes, which:
- Cancels any running `.task` modifiers (fixes Pharaoh polling issue)
- Resets all `@State` properties to their initial values
- Triggers fresh `onAppear` and `.task` calls for the new project
