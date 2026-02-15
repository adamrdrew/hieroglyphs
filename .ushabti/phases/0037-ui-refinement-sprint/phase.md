# Phase 0037: UI Refinement Sprint

## Intent

Implement four independent UI refinements to improve the Hieroglyphs workflow. All changes are self-contained, build on existing patterns, and enhance user efficiency without introducing new architectural components.

**Why this Phase exists now:** These refinements collectively reduce friction in common workflows — creating plans from cards, configuring projects, reviewing Pharaoh activity, and filtering plans — improving the day-to-day usability of Hieroglyphs.

## Scope

**In scope:**

1. **Create Plan from Card:** Add context menu and toolbar button in CardDetail to create a new plan linked to the current card. Reuses existing plan creation flow.
2. **Directory Selection in NewProjectSheet:** Add NSOpenPanel directory picker to NewProjectSheet for selecting sourceDirectory during project creation (optional field, same picker pattern as EditProjectSheet).
3. **Inline Pharaoh Event Detail:** Remove disclosure group from PharaohEventDetailView and show extracted detail content directly inline when `event.hasDetail` is true.
4. **Plan List Filtering:** Add status-based filter toolbar and filter logic to PlanList matching CardList's existing filter implementation. Done plans hidden by default via toggle.

**Out of scope:**

- Any changes to plan creation logic or data models (reuse existing implementations)
- Changes to Pharaoh event parsing or detail extraction (display only)
- New filter types beyond status for plans (defer priority/card-count filters)
- Persistence of filter state across sessions (ephemeral, matches CardList behavior)
- Multi-card plan creation workflows (single card → plan only)

## Constraints

- **L09 (Sandi Metz):** Small, focused methods. Reuse existing patterns.
- **L10 (Design Consistency with TakeNote):** Match existing filter bar, context menu, and toolbar button patterns.
- **L17 (UI State Correctness):** Filter state resets on project change. Views update immediately on context change.
- **L18 (Design Is How It Works):** Platform-native controls. Standard button styles. Semantic typography. Disabled states when appropriate.
- **Style (SwiftUI UX Patterns):** Navigation State Reset, Empty States, Modal Sizing, Toolbar Actions.
- **Existing Patterns:** CardFilterBar and CardList filtering logic serve as reference implementation for PlanList filtering.

## Acceptance Criteria

### AC1: Create Plan from Card Context Menu

- Right-clicking a card in CardList shows "Create Plan" menu item (flowchart icon)
- Clicking "Create Plan" creates new plan with auto-incremented number, title derived from card title (e.g., "Implement {card.title}"), card symlinked to plan
- Plan created in `planning` status with empty phase prompt
- No modal or sheet shown (immediate creation)
- Context menu only shown when a project is selected
- Tests verify: context menu action creates plan and symlinks card

### AC2: Create Plan from Card Toolbar Button

- CardDetail toolbar shows "Create Plan" button (flowchart icon) when card is selected
- Clicking button creates plan as above (same implementation as context menu)
- Button disabled when no card selected
- Button hidden when no project selected
- Tests verify: toolbar button creates plan and symlinks card

### AC3: Directory Selection in NewProjectSheet

- NewProjectSheet shows "Source Directory" section after Tags section
- Section displays current sourceDirectory path (if set) or "None" in tertiary color
- "Select Folder..." button opens NSOpenPanel configured for directories (canChooseFiles=false, canChooseDirectories=true, allowsMultipleSelection=false, canCreateDirectories=true)
- "Clear" button shown when sourceDirectory is set (removes selection)
- sourceDirectory included in `viewModel.createProject()` call (existing parameter)
- Tests verify: createProject receives sourceDirectory parameter

### AC4: Inline Pharaoh Event Detail

- PharaohEventRow shows detail content directly inline when `event.hasDetail` is true
- No DisclosureGroup, no expand/collapse interaction
- Detail content uses `.caption2` font, `.tertiary` foreground, indented 76pt (aligned with summary text column)
- Detail shows tool name, tool input, turn metrics, full text, or result metrics as appropriate for event type
- Empty/missing detail fields omitted gracefully (no blank rows)
- Tests verify: detail rendering for all event types with detail data

### AC5: Plan List Status Filtering

- PlanList toolbar shows "Hide Done" toggle button (eye/eye.slash icon, same pattern as CardList)
- Default state: done plans hidden (`showDonePlans = false`)
- Clicking toggle shows/hides plans with `done` status
- Filter state resets on project change (`.onChange(of: viewModel.selectedProject)`)
- Filter state is ephemeral (not persisted)
- Tests verify: filteredPlans computation excludes done plans when showDonePlans is false

## Risks / Notes

- **No new ViewModels or service methods required.** All four changes use existing ViewModel/service APIs.
- **Pattern consistency critical.** CardList filter implementation serves as reference for PlanList filtering.
- **Plan creation from card reuses existing logic.** No new plan creation paths introduced.
- **NSOpenPanel pattern already exists** in EditProjectSheet — copy to NewProjectSheet.
- **Event detail rendering already exists** in PharaohEventDetailView — remove DisclosureGroup wrapper and adjust styling.
