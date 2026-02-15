# Steps

## S001: Add Create Plan context menu to CardListEntry

**Intent:** Provide quick access to plan creation from card list.

**Work:**
- Add context menu to CardListEntry with "Create Plan" item (flowchart icon)
- Call `viewModel.createPlanFromCard(card)` on menu item click
- Only show menu when card is not nil

**Done when:** Right-clicking card in CardList shows "Create Plan" option. Clicking it has no effect yet (method not implemented).

---

## S002: Add Create Plan toolbar button to CardDetail

**Intent:** Provide plan creation from card detail view.

**Work:**
- Add toolbar button to CardDetail with flowchart icon and "Create Plan" label
- Call `viewModel.createPlanFromCard(card)` on button click
- Disable button when no card selected
- Hide button when no project selected

**Done when:** CardDetail toolbar shows "Create Plan" button when card selected. Button disabled when no card selected. Clicking it has no effect yet (method not implemented).

---

## S003: Implement createPlanFromCard in HieroglyphsVM

**Intent:** Create plan and link card in single operation.

**Work:**
- Add `createPlanFromCard(_ card: Card)` method to HieroglyphsVM
- Guard check: selectedProject and workspacePath not nil, planService not nil
- Call `planService.findNextPlanNumber()` to get next plan number
- Generate plan title: "Implement \(card.title)"
- Call `planService.createPlan(title:number:projectPath:)`
- Call `planService.addCardToPlan(cardSlug:planSlug:projectPath:)` to link card
- Call `loadPlans()` to refresh plan list
- Log errors to console on failure

**Done when:** createPlanFromCard creates plan with auto-incremented number, title derived from card, card symlinked. Plans reload after creation. Context menu and toolbar button now functional.

---

## S004: Add Source Directory section to NewProjectSheet

**Intent:** Allow users to configure sourceDirectory during project creation.

**Work:**
- Add "Source Directory" section to NewProjectSheet Form after Tags section
- Add `@State private var sourceDirectory: String?` property
- Display current path or "None" (tertiary color) in `.caption` font
- Add "Select Folder..." button with `.borderedProminent` style
- Add "Clear" button (shown only when sourceDirectory != nil)
- Implement `selectSourceDirectory()` method using NSOpenPanel (copy pattern from EditProjectSheet)
- Configure panel: canChooseFiles=false, canChooseDirectories=true, allowsMultipleSelection=false, canCreateDirectories=true
- Pass sourceDirectory to `viewModel.createProject()` in saveProject method

**Done when:** NewProjectSheet shows Source Directory section. Select Folder button opens directory picker. Selected path displayed. Clear button removes selection. sourceDirectory passed to createProject call.

---

## S005: Update viewModel.createProject to accept sourceDirectory

**Intent:** Persist sourceDirectory during project creation.

**Work:**
- Add `sourceDirectory: String?` parameter to `createProject` method signature
- Pass sourceDirectory to `workspaceService.createProject()` call
- Update all call sites (NewProjectSheet is only caller)

**Done when:** createProject accepts sourceDirectory parameter and passes it to service. NewProjectSheet compiles and passes sourceDirectory value.

---

## S006: Remove DisclosureGroup from PharaohEventDetailView

**Intent:** Show event detail inline without expand/collapse interaction.

**Work:**
- Replace DisclosureGroup with plain VStack in PharaohEventDetailView
- Remove `isExpanded` state variable (no longer needed)
- Remove chevron label (no longer needed)
- Adjust indentation to 76pt (aligned with summary text column in PharaohEventRow)
- Use `.caption2` font and `.tertiary` foreground style for all detail text
- Preserve existing detail content logic (tool name, input, turn metrics, etc.)
- Omit empty/nil detail fields gracefully (no blank rows)

**Done when:** PharaohEventRow shows detail content inline when event.hasDetail is true. No disclosure interaction. Detail aligned and styled consistently.

---

## S007: Update PharaohEventRow to render inline detail

**Intent:** Integrate inline detail rendering into event row layout.

**Work:**
- Check `event.hasDetail` in PharaohEventRow body
- If true, render PharaohEventDetailView directly below summary (no conditional disclosure)
- Ensure detail content is indented to align with summary text (76pt from leading edge)
- Preserve relative timestamp and icon positioning
- Adjust vertical spacing if needed for readability

**Done when:** Events with detail data show detail content directly inline. No expand/collapse affordance. Layout clean and aligned.

---

## S008: Add showDonePlans state to HieroglyphsVM

**Intent:** Track plan filter state in ViewModel.

**Work:**
- Add `@Published var showDonePlans: Bool = false` to HieroglyphsVM
- Default to false (hide done plans by default)
- State is ephemeral (not persisted)

**Done when:** HieroglyphsVM exposes showDonePlans property. Default value is false.

---

## S009: Add Hide Done toggle button to PlanList toolbar

**Intent:** Provide UI control for showing/hiding done plans.

**Work:**
- Add toolbar button to PlanList with eye/eye.slash icon (matches CardList pattern)
- Button toggles `viewModel.showDonePlans` on click
- Label changes based on state: "Hide Done" when showing, "Show Done" when hiding
- Icon changes: `eye` when showing all, `eye.slash` when hiding done
- Add `.help()` tooltip for accessibility

**Done when:** PlanList toolbar shows Hide Done toggle button. Clicking toggles state. Icon and label update correctly.

---

## S010: Implement filteredPlans computed property in PlanList

**Intent:** Apply status filter to plan list.

**Work:**
- Add `filteredPlans` computed property to PlanList
- Filter `viewModel.plans` to exclude plans with `.done` status when `viewModel.showDonePlans` is false
- Use filtered array in List ForEach
- Reset filter state on project change via `.onChange(of: viewModel.selectedProject)`

**Done when:** PlanList displays only non-done plans by default. Toggle button shows/hides done plans. Filter resets on project change. List updates immediately on filter change.

---

## S011: Test create plan from card workflow

**Intent:** Verify end-to-end plan creation from card works correctly.

**Work:**
- Add test: `testCreatePlanFromCard()`
- Set up: selectedProject, workspacePath, card in cards array
- Call `viewModel.createPlanFromCard(card)`
- Verify: planService.createPlan called with correct title ("Implement \(card.title)")
- Verify: planService.addCardToPlan called with card.slug and plan.slug
- Verify: loadPlans called to refresh

**Done when:** Test passes. createPlanFromCard creates plan with expected title, links card, and refreshes plans.

---

## S012: Test plan list filtering hides done plans by default

**Intent:** Verify plan filtering logic works as expected.

**Work:**
- Add test: `testPlanListFilterHidesDoneByDefault()`
- Set up: plans array with mix of planning/ready/done statuses
- Set `viewModel.showDonePlans = false`
- Compute filteredPlans
- Verify: done plans excluded from result
- Set `viewModel.showDonePlans = true`
- Verify: done plans included in result

**Done when:** Test passes. filteredPlans excludes done plans when showDonePlans is false, includes them when true.

---

## S013: Test sourceDirectory passed to createProject

**Intent:** Verify sourceDirectory parameter flows through to service.

**Work:**
- Add test: `testCreateProjectWithSourceDirectory()`
- Call `viewModel.createProject(title:description:tags:sourceDirectory:)` with non-nil sourceDirectory
- Verify: workspaceService.createProject called with correct sourceDirectory value

**Done when:** Test passes. createProject passes sourceDirectory to workspaceService.

---

## S014: Manual UI testing and verification

**Intent:** Verify all four refinements work correctly in the running app.

**Work:**
- Run app and test each feature:
  1. Right-click card → Create Plan. Verify plan created with card linked.
  2. Select card → CardDetail toolbar → Create Plan. Verify plan created.
  3. Create new project → select source directory. Verify path displayed and passed to service.
  4. View Pharaoh event stream with detail. Verify detail shown inline without disclosure.
  5. View plan list → toggle Hide Done. Verify done plans shown/hidden.
- Verify UI state resets correctly on project change (filter state, selection state)
- Verify disabled/hidden states for buttons (no project selected, no card selected)

**Done when:** All four features work as expected. UI state correct. No console errors. Disabled states correct.

---

## S015: Fix CardDetail toolbar button disabled state logic

**Intent:** Ensure the Create Plan toolbar button in CardDetail correctly reflects whether a card is selected and project is selected, per AC2.

**Work:**
- Move toolbar button outside the `if let editableCard` block
- Disable button when `viewModel.selectedCard == nil`
- Hide button when `viewModel.selectedProject == nil`
- Button should call `viewModel.createPlanFromCard(viewModel.selectedCard!)` inside the action (safe because button is disabled when nil)

**Done when:** Button is disabled when no card selected. Button is hidden when no project selected. Button only clickable when both project and card are selected.

---

## S016: Set canCreateDirectories to true in NewProjectSheet NSOpenPanel

**Intent:** Allow users to create new directories when selecting source directory during project creation, per AC3.

**Work:**
- Change `panel.canCreateDirectories = false` to `panel.canCreateDirectories = true` in NewProjectSheet.selectSourceDirectory()

**Done when:** NSOpenPanel in NewProjectSheet allows directory creation. Matches AC3 specification.

---

## S017: Update docs for new UI features

**Intent:** Reconcile documentation with the four UI refinements added in this phase, per L14/L15/L16.

**Work:**
- Update `.ushabti/docs/views-ui.md`:
  - Document Create Plan context menu in CardListEntry
  - Document Create Plan toolbar button in CardDetail
  - Document Source Directory section in NewProjectSheet
  - Document inline detail rendering in PharaohEventRow/PharaohEventDetailView
  - Document Hide Done toggle in PlanList
- Update `.ushabti/docs/viewmodel.md`:
  - Document `createPlanFromCard(_ card: Card)` method
  - Document `showDonePlans` property
- Update `.ushabti/docs/plans-system.md`:
  - Document plan creation from card workflow
  - Document plan list filtering by status

**Done when:** Docs accurately describe all four UI refinements. No missing documentation for new features.
