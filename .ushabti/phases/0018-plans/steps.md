# Steps

## S001: Define Plan and PlanStatus models

**Intent:** Create domain models for Plans.

**Work:**
- Define `Plan` struct in `Sources/Hieroglyphs/Models/Plan.swift`:
  - `id: UUID`, `title: String`, `number: Int`, `slug: String`
  - `status: PlanStatus`, `created: Date`, `updated: Date`
  - `linkedCardSlugs: [String]` (derived, not persisted)
  - `phasePrompt: String` (content of PHASE_PROMPT.md)
  - Conformances: `Identifiable`, `Codable`, `Equatable`, `Hashable`
- Define `PlanStatus` enum in `Sources/Hieroglyphs/Models/PlanStatus.swift`:
  - Cases: `planning`, `ready`, `done`
  - Conformances: `String`, `Codable`, `CaseIterable`

**Done when:**
- Plan.swift and PlanStatus.swift exist in Models/
- Models compile and conform to required protocols
- Models follow existing model patterns (Project, Card)

---

## S002: Define PlanProviding protocol

**Intent:** Define service contract for plan I/O operations.

**Work:**
- Create `Sources/Hieroglyphs/Services/PlanProviding.swift`
- Define protocol methods:
  - `loadPlans(projectPath: String) throws -> [Plan]`
  - `createPlan(title: String, number: Int, projectPath: String) throws -> Plan`
  - `updatePlan(_ plan: Plan, projectPath: String) throws`
  - `addCardToPlan(cardSlug: String, planSlug: String, projectPath: String) throws`
  - `removeCardFromPlan(cardSlug: String, planSlug: String, projectPath: String) throws`
  - `updatePlanStatus(plan: Plan, status: PlanStatus, projectPath: String) throws`
  - `writePhasePrompt(planSlug: String, content: String, projectPath: String) throws`

**Done when:**
- PlanProviding.swift exists
- Protocol defines all required methods with correct signatures
- Protocol compiles without errors

---

## S003: Implement PlanService

**Intent:** Implement concrete PlanService with filesystem operations.

**Work:**
- Create `Sources/Hieroglyphs/Services/PlanService.swift`
- Implement `loadPlans()`:
  - Scan `{projectPath}/plans/` for directories
  - Read `plan.yaml` from each directory
  - Parse frontmatter with Yams
  - Enumerate symlinks to derive `linkedCardSlugs`
  - Read `PHASE_PROMPT.md` content
  - Handle dangling symlinks gracefully
  - Return array of Plan models
- Implement `createPlan()`:
  - Generate slug from title and number: `{NNNN}-{kebab-case-title}`
  - Create directory at `{projectPath}/plans/{slug}/`
  - Write `plan.yaml` with id, title, number, slug, status, timestamps
  - Write empty `PHASE_PROMPT.md`
  - Return Plan model
- Implement `updatePlan()`:
  - Read existing `plan.yaml`
  - Merge updated fields
  - Preserve unknown fields
  - Write atomically
- Implement `addCardToPlan()`:
  - Create relative symlink: `{projectPath}/plans/{planSlug}/{cardSlug} -> ../../cards/{cardSlug}/`
  - Use `FileManager.createSymbolicLink()`
- Implement `removeCardFromPlan()`:
  - Delete symlink at `{projectPath}/plans/{planSlug}/{cardSlug}`
- Implement `updatePlanStatus()`:
  - Update plan status in `plan.yaml`
  - If status is `done`, enumerate symlinks, load each card, update card status to `done`, write cards back to disk
- Implement `writePhasePrompt()`:
  - Write content to `{projectPath}/plans/{planSlug}/PHASE_PROMPT.md`

**Done when:**
- PlanService.swift exists and conforms to PlanProviding
- All methods implemented with filesystem operations
- Dangling symlinks handled without throwing errors
- Symlinks are relative, not absolute
- Tests placeholder created

---

## S004: Add PlanService environment key

**Intent:** Enable dependency injection via SwiftUI environment.

**Work:**
- Create `Sources/Hieroglyphs/Services/PlanServiceEnvironmentKey.swift`
- Define `EnvironmentKey` for PlanProviding
- Add environment value extension

**Done when:**
- PlanServiceEnvironmentKey.swift exists
- Environment key defined and compiles
- Pattern matches WorkspaceServiceEnvironmentKey

---

## S005: Integrate PlanService into App and ViewModel

**Intent:** Wire PlanService into app dependency graph.

**Work:**
- Update `App.swift`:
  - Create `PlanService()` instance
  - Inject via `.environment(\.planService, planService)`
- Update `HieroglyphsVM.swift`:
  - Add `@Published var plans: [Plan] = []`
  - Add `@Published var selectedPlan: Plan?`
  - Add `private let planService: PlanProviding`
  - Add `planService` to initializer
  - Add `loadPlans()` method (loads plans for selectedProject)
  - Add `createPlan(title:number:)` method
  - Add `updatePlan(_:)` method
  - Add `addCardToPlan(cardSlug:planSlug:)` method
  - Add `removeCardFromPlan(cardSlug:planSlug:)` method
  - Add `updatePlanStatus(plan:status:)` method
  - Add `writePhasePrompt(planSlug:content:)` method

**Done when:**
- App.swift creates and injects PlanService
- HieroglyphsVM has plans state and methods
- ViewModel delegates all I/O to PlanService
- ViewModel compiles without errors

---

## S006: Create PlanList view

**Intent:** Middle column view for displaying plans.

**Work:**
- Create `Sources/Hieroglyphs/Views/PlanList/PlanList.swift`
- Implement three states:
  - No project selected: ContentUnavailableView
  - No plans: ContentUnavailableView with "Create a plan to group cards"
  - Plans exist: List with selection binding to `viewModel.selectedPlan`
- Add toolbar with "New Plan" button
- Add sheet presentation for NewPlanSheet
- Auto-load plans when selectedProject changes (`.onChange`)

**Done when:**
- PlanList.swift exists in Views/PlanList/
- View shows empty states and plan list appropriately
- Toolbar button shows NewPlanSheet
- View compiles and renders

---

## S007: Create PlanListEntry view

**Intent:** Individual plan row showing number, title, status, card count.

**Work:**
- Create `Sources/Hieroglyphs/Views/PlanList/PlanListEntry.swift`
- Display plan number, title, status badge, linked card count
- Use SF Symbol icon for status (similar to PhaseListEntry pattern)
- Layout: HStack with icon, VStack(title, subtitle)

**Done when:**
- PlanListEntry.swift exists
- Row displays plan metadata clearly
- Status badge color-coded (planning: gray, ready: blue, done: green)
- Card count shown as subtitle

---

## S008: Create NewPlanSheet view

**Intent:** Modal sheet for creating a new plan.

**Work:**
- Create `Sources/Hieroglyphs/Views/PlanList/NewPlanSheet.swift`
- Form with:
  - Title text field (required)
  - Number field (integer input, required)
  - Cancel and Save toolbar buttons
- Save button calls `viewModel.createPlan(title:number:)`
- Dismiss sheet on save

**Done when:**
- NewPlanSheet.swift exists
- Sheet validates required fields (disable Save if title or number empty)
- Save creates plan and dismisses sheet
- Follows NewProjectSheet pattern

---

## S009: Create PlanDetail view

**Intent:** Detail column view for displaying and editing selected plan.

**Work:**
- Create `Sources/Hieroglyphs/Views/PlanDetail/PlanDetail.swift`
- Two states:
  - No plan selected: ContentUnavailableView
  - Plan selected: ScrollView with sections:
    - Plan number, title, status picker
    - Linked cards list with title/status/priority
    - "Add Card" button (shows card picker sheet)
    - PHASE_PROMPT.md content area (TextEditor or CodeEditor)
    - "Generate Phase Prompt" button (disabled, placeholder)
- Status picker updates plan immediately
- Card list shows each linked card with context menu for "Remove Card"
- Handle dangling symlinks: show as "Missing: card-slug" with warning icon

**Done when:**
- PlanDetail.swift exists
- View shows plan metadata and linked cards
- Status picker functional
- Card add/remove functional
- PHASE_PROMPT.md editable
- Dangling symlinks shown as missing

---

## S010: Create AddCardToPlanSheet view

**Intent:** Modal sheet for adding a card to a plan.

**Work:**
- Create `Sources/Hieroglyphs/Views/PlanDetail/AddCardToPlanSheet.swift`
- List of available cards (cards not already in plan)
- Select card and click Add
- Call `viewModel.addCardToPlan(cardSlug:planSlug:)`
- Dismiss sheet

**Done when:**
- AddCardToPlanSheet.swift exists
- Sheet lists available cards
- Add button creates symlink and dismisses sheet
- Only shows cards not already linked

---

## S011: Wire Plans into MainWindow

**Intent:** Connect Plans section to PlanList and PlanDetail.

**Work:**
- Update `MainWindow.swift`:
  - Update `middleColumnContent`: case `.plans(let project)` shows `PlanList()`
  - Update `detailColumnContent`: if `viewModel.selectedPlan != nil` show `PlanDetail()`, else show `CardDetail()`
- Remove `PlansPlaceholder` (replaced by PlanList)

**Done when:**
- MainWindow shows PlanList when Plans section selected
- MainWindow shows PlanDetail when a plan is selected
- PlansPlaceholder no longer used

---

## S012: Update FileWatcher to monitor plans

**Intent:** Detect external changes to plan.yaml and PHASE_PROMPT.md.

**Work:**
- Update `FileWatcherService.swift`:
  - Watch `{projectPath}/plans/` directories
  - Trigger `onWorkspaceChanged` callback when plan files change
- Update `HieroglyphsVM.swift`:
  - Reload plans when file watcher triggers and Plans section is selected

**Done when:**
- FileWatcher monitors plans/ directories
- External edits to plan.yaml detected and UI updated
- External edits to PHASE_PROMPT.md detected and UI updated

---

## S013: Write PlanService tests

**Intent:** Verify all PlanService operations work correctly.

**Work:**
- Create `Tests/HieroglyphsTests/PlanServiceTests.swift`
- Test `loadPlans()`:
  - Returns empty array when no plans exist
  - Loads plans with correct metadata
  - Derives linkedCardSlugs from symlinks
  - Handles dangling symlinks without throwing
- Test `createPlan()`:
  - Creates directory and plan.yaml
  - Writes empty PHASE_PROMPT.md
  - Generates correct slug format
- Test `updatePlan()`:
  - Updates plan.yaml
  - Preserves unknown fields
- Test `addCardToPlan()`:
  - Creates relative symlink
- Test `removeCardFromPlan()`:
  - Deletes symlink
- Test `updatePlanStatus()`:
  - Updates plan status
  - Marks all linked cards done when plan status is done
- Test `writePhasePrompt()`:
  - Writes content to PHASE_PROMPT.md

**Done when:**
- PlanServiceTests.swift exists
- All public methods have tests
- Tests use temporary directories
- All tests pass

---

## S014: Update documentation

**Intent:** Document Plans system architecture and usage.

**Work:**
- Create `.ushabti/docs/plans-system.md`:
  - Document filesystem structure for plans
  - Document Plan and PlanStatus models
  - Document PlanService protocol and implementation
  - Document symlink format (relative paths)
  - Document PHASE_PROMPT.md purpose and format
  - Document dangling symlink handling
  - Document status transitions and card status updates
- Update `.ushabti/docs/index.md`:
  - Add link to plans-system.md
- Update `.ushabti/docs/filesystem-structure.md`:
  - Add plans/ directory structure
  - Add plan.yaml format
  - Add PHASE_PROMPT.md description
- Update `.ushabti/docs/models.md`:
  - Add Plan and PlanStatus model descriptions

**Done when:**
- plans-system.md created with comprehensive documentation
- index.md, filesystem-structure.md, and models.md updated
- Documentation follows existing doc patterns

---

## S015: Remove dead code (PlansPlaceholder)

**Intent:** Fix L12 violation by removing unused PlansPlaceholder file.

**Work:**
- Delete `Sources/Hieroglyphs/Views/PlansPlaceholder.swift`
- Verify no references to PlansPlaceholder exist in codebase

**Done when:**
- PlansPlaceholder.swift deleted
- No references to PlansPlaceholder in codebase
- Build succeeds
