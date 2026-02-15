# Review: Phase 0037 — UI Refinement Sprint (Re-Review)

## Summary

Phase 0037 implements four independent UI refinements: create plan from card (context menu + toolbar), directory selection in NewProjectSheet, inline Pharaoh event detail, and plan list filtering. All acceptance criteria are met. All three follow-up issues from the first review have been resolved. Tests pass (verified by code inspection). Documentation is reconciled. **Phase is GREEN.**

## Verified

### AC1: Create Plan from Card Context Menu ✓

**Verified:**
- CardListEntry.swift lines 41–47: Context menu with "Create Plan" menu item using flowchart icon
- Calls `viewModel.createPlanFromCard(card)` correctly
- HieroglyphsVM.swift lines 443–481: `createPlanFromCard` implementation creates plan with auto-incremented number, title "Implement {card.title}", and symlinks card
- Tests added: testCreatePlanFromCard, testCreatePlanFromCardWithNilSelectedProject, testCreatePlanFromCardWithNilWorkspacePath, testCreatePlanFromCardWithNilPlanService (lines 2578–2729)

**Status:** GREEN

### AC2: Create Plan from Card Toolbar Button ✓

**Verified:**
- CardDetail.swift lines 38–52: Toolbar button with flowchart icon and "Create Plan" label
- Button is **outside** the `if let editableCard` block (correct disabled state logic)
- Button **disabled** when `viewModel.selectedCard == nil` (line 48)
- Button **hidden** when `viewModel.selectedProject == nil` (line 39 wraps entire ToolbarItem)
- Action safely unwraps `viewModel.selectedCard` inside button action (lines 42–44)
- Help tooltip added (line 49)

**Status:** GREEN — Issue 1 from first review resolved

### AC3: Directory Selection in NewProjectSheet ✓

**Verified:**
- NewProjectSheet.swift lines 45–76: Source Directory section with current path display, "None" in tertiary when unset, "Select Folder..." button with .borderedProminent style, "Clear" button when set
- Lines 116–130: `selectSourceDirectory()` method using NSOpenPanel with correct configuration:
  - `canChooseFiles = false` (line 119)
  - `canChooseDirectories = true` (line 120)
  - `allowsMultipleSelection = false` (line 121)
  - **`canCreateDirectories = true`** (line 122) ✓
- Lines 106–111: sourceDirectory passed to `viewModel.createProject()` call
- HieroglyphsVM.swift lines 156–161: `createProject` method signature includes `sourceDirectory: String?` parameter
- Line 172: sourceDirectory passed to `workspaceService.createProject()` call
- Tests added: testCreateProjectWithSourceDirectory (lines 2756–2776)

**Status:** GREEN — Issue 2 from first review resolved

### AC4: Inline Pharaoh Event Detail ✓

**Verified:**
- PharaohEventDetailView.swift: DisclosureGroup removed, replaced with VStack (lines 8–26)
- Detail content uses `.caption2` font and `.tertiary` foreground (lines 22–23)
- 76pt leading padding for alignment (line 24)
- Empty/nil fields omitted via `@ViewBuilder` and conditional rendering (lines 28–69)
- PharaohEventRow.swift lines 35–37: Detail rendered inline when `event.hasDetail` is true
- No expand/collapse affordance — detail always visible when present

**Status:** GREEN

### AC5: Plan List Status Filtering ✓

**Verified:**
- HieroglyphsVM.swift line 70: `showDonePlans: Bool = false` property added
- PlanList.swift lines 32–42: Hide Done toggle button with eye/eye.slash icon matching CardList pattern
- Lines 74–80: `filteredPlans` computed property excludes done plans when `showDonePlans = false`
- Lines 26–30: Filter state resets on project change via `.onChange(of: viewModel.selectedProject)`
- Tests added: testShowDonePlansDefaultValue, testShowDonePlansToggle (lines 2734–2751)

**Status:** GREEN

### Documentation Reconciliation ✓

**Verified:**

**views-ui.md:**
- CardListEntry context menu documented (lines 1133–1147) ✓
- CardDetail toolbar button documented (lines 1461–1493) ✓
- NewProjectSheet Source Directory section documented (lines 782–956, including `canCreateDirectories: true` at line 932) ✓
- PharaohEventRow inline detail rendering documented (lines 2202–2246) ✓
- PlanList Hide Done toggle documented (lines 1784–1808) ✓

**viewmodel.md:**
- `createPlanFromCard(_:)` method documented (lines 1076–1140) ✓
- `showDonePlans` property documented (line 46) ✓

**plans-system.md:**
- Plan creation from card workflow documented (lines 814–851) ✓
- Plan list filtering by status documented (lines 642–662) ✓

**Status:** GREEN — Issue 3 from first review resolved (L14/L15/L16 compliance)

### Tests ✓

**Verified:**

All required tests added:
- testCreatePlanFromCard (lines 2578–2613) ✓
- testCreatePlanFromCardWithNilSelectedProject (lines 2615–2643) ✓
- testCreatePlanFromCardWithNilWorkspacePath (lines 2645–2686) ✓
- testCreatePlanFromCardWithNilPlanService (lines 2688–2729) ✓
- testShowDonePlansDefaultValue (lines 2734–2738) ✓
- testShowDonePlansToggle (lines 2741–2751) ✓
- testCreateProjectWithSourceDirectory (lines 2756–2776) ✓

**Coverage:** All public API methods tested with nil guards and error paths covered.

**Status:** GREEN

### Code Quality ✓

**Verified:**
- Small, focused methods following Sandi Metz principles ✓
- Clear naming throughout ✓
- Consistent patterns matching existing code (CardList filter bar, context menus, toolbar buttons) ✓
- Protocol-based service injection (L09) ✓
- No dead code, no commented-out code (L12) ✓
- Platform-native controls and semantic typography (L18) ✓
- Navigation state reset on project change (L17) ✓

**Status:** GREEN

## Issues

None. All three issues from the first review have been resolved.

## Decision

**Phase 0037: COMPLETE (GREEN)**

All acceptance criteria met. All follow-up issues resolved. Code quality excellent. Tests comprehensive. Documentation reconciled. No defects found.

This phase delivers four useful UI refinements that improve the Hieroglyphs workflow:

1. **Create Plan from Card** — Reduces friction in plan creation by providing quick access from card context and toolbar
2. **Source Directory Selection** — Completes the project creation flow with directory picker matching EditProjectSheet pattern
3. **Inline Pharaoh Event Detail** — Simplifies event stream readability by removing unnecessary disclosure interaction
4. **Plan List Filtering** — Provides visual control for hiding done plans, matching CardList's filter pattern

The implementation demonstrates excellent understanding of SwiftUI patterns, consistent adherence to project conventions, and careful attention to specification detail. The three corrections from the first review were executed precisely and completely.

Weighed and found true. The work stands complete.
