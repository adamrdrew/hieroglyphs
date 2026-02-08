# Steps for Phase 0017: Phases View

## S001: Define Phase Models

**Intent:** Create plain data models for Phase, PhaseStatus, and PhaseStep following existing model patterns.

**Work:**
- Create `Sources/Hieroglyphs/Models/PhaseStatus.swift` with enum cases: planned, active, green, yellow, red (String raw values)
- Create `Sources/Hieroglyphs/Models/PhaseStep.swift` with struct: id (String), summary (String), implemented (Bool), reviewed (Bool)
- Create `Sources/Hieroglyphs/Models/Phase.swift` with struct: number (Int), slug (String), title (String), status (PhaseStatus), intent (String), steps ([PhaseStep]), reviewNotes (String)
- All models conform to Codable, Identifiable (Phase only), Equatable
- Follow existing model patterns (plain structs, no business logic, Foundation only)

**Done when:**
- Three new files exist in Models/ directory
- PhaseStatus enum has 5 cases with lowercase String raw values
- PhaseStep struct has 4 properties (id, summary, implemented, reviewed)
- Phase struct conforms to Identifiable (id = slug or computed from number), has 7 properties
- All models compile without errors
- No SwiftData, no persistence logic

## S002: Define PhaseProviding Protocol

**Intent:** Create protocol defining contract for phase I/O operations.

**Work:**
- Create `Sources/Hieroglyphs/Services/PhaseProviding.swift`
- Define protocol with single method: `func loadPhases(from sourceDirectory: String) throws -> [Phase]`
- Add doc comments describing method behavior and parameters
- Follow WorkspaceProviding protocol pattern

**Done when:**
- Protocol file exists in Services/ directory
- Protocol has single method signature (loadPhases)
- Method throws for error propagation
- Method takes sourceDirectory string parameter
- Method returns array of Phase models
- Doc comments explain purpose and behavior

## S003: Implement PhaseService

**Intent:** Implement concrete service that discovers and parses phase directories.

**Work:**
- Create `Sources/Hieroglyphs/Services/PhaseService.swift`
- Implement `PhaseProviding` protocol
- `loadPhases(from:)` implementation:
  - Check sourceDirectory exists and has `.ushabti/phases/` subdirectory
  - Scan for directories matching pattern `NNNN-slug`
  - For each directory: parse directory name for number and slug
  - Read `progress.yaml` and decode to dictionary
  - Extract phase title, status, steps array from YAML
  - Read `phase.md` and extract body as intent (skip frontmatter if present)
  - Read `review.md` if exists, extract body as reviewNotes (empty string if missing)
  - Construct Phase model for each valid directory
  - Sort phases by number ascending
  - Return array of Phase models
- Use FileManager for directory scanning
- Use Yams for YAML parsing
- Handle missing files gracefully (log warning, skip malformed phases)
- No regex (use string split and components for directory name parsing)

**Done when:**
- PhaseService.swift exists and implements PhaseProviding
- Service discovers directories in `.ushabti/phases/`
- Directory name parsing extracts number (Int) and slug (String)
- YAML parsing reads progress.yaml correctly
- Markdown parsing reads phase.md and review.md
- Missing review.md handled gracefully (reviewNotes = "")
- Malformed phases skipped with warning logged
- Phases sorted by number ascending
- Service compiles and all dependencies resolve

## S004: Create PhaseService Environment Key

**Intent:** Enable SwiftUI dependency injection for PhaseService.

**Work:**
- Create `Sources/Hieroglyphs/Services/PhaseServiceEnvironmentKey.swift`
- Define EnvironmentKey with PhaseProviding? as value type
- Define EnvironmentValues extension with phaseService property
- Follow WorkspaceServiceEnvironmentKey pattern

**Done when:**
- Environment key file exists
- EnvironmentKey defined with correct value type
- EnvironmentValues extension provides `.phaseService` property
- Pattern matches existing environment keys (workspace, fileWatcher, tagReconciler)

## S005: Add Phase State to HieroglyphsVM

**Intent:** Extend ViewModel to hold phase list and selected phase state.

**Work:**
- Open `Sources/Hieroglyphs/HieroglyphsVM.swift`
- Add `@Published` property: `phases: [Phase] = []`
- Add `@Published` property: `selectedPhase: Phase? = nil`
- Add `phaseService: PhaseProviding?` to init parameters and stored properties
- Add `loadPhases()` method:
  - Guard check selectedProject has non-nil sourceDirectory
  - Call phaseService.loadPhases(from: sourceDirectory)
  - Update self.phases with result
  - Catch errors and log to console
- Follow existing loadCards() pattern

**Done when:**
- Two new state properties added (phases, selectedPhase)
- PhaseProviding injected in init (optional parameter)
- loadPhases() method implemented
- Method guards on selectedProject.sourceDirectory
- Method calls phaseService.loadPhases(from:)
- Method updates self.phases on success
- Method logs errors on failure
- Method follows same pattern as loadCards()

## S006: Create PhaseList View

**Intent:** Build middle-column view displaying phase list for selected project.

**Work:**
- Create `Sources/Hieroglyphs/Views/PhaseList/PhaseList.swift`
- Implement SwiftUI view with three states:
  - No sourceDirectory: ContentUnavailableView "Configure a source directory to view phases"
  - No phases: ContentUnavailableView "No Ushabti phases found"
  - Phases list: List with selection binding to viewModel.selectedPhase
- For each phase: show number, title, status badge (SF Symbol or color indicator)
- Status badges: planned (gray), active (blue), green (checkmark), yellow (warning), red (exclamation)
- Auto-load phases when view appears or selectedProject changes (.onChange modifier)
- Follow CardList pattern (empty states, List, onChange)

**Done when:**
- PhaseList.swift exists in Views/PhaseList/ directory
- Three states implemented (no sourceDirectory, no phases, phases list)
- Empty states use ContentUnavailableView with appropriate icons
- List binds to viewModel.selectedPhase
- Each row shows phase number, title, status indicator
- Status badges visually distinguish phase states
- .onChange(of: viewModel.selectedProject) triggers loadPhases()
- View follows CardList patterns and style

## S007: Create PhaseDetail View

**Intent:** Build detail-column view displaying phase intent, steps, and review notes.

**Work:**
- Create `Sources/Hieroglyphs/Views/PhaseDetail/PhaseDetail.swift`
- Implement SwiftUI view with two states:
  - No phase selected: ContentUnavailableView "No Phase Selected"
  - Phase selected: ScrollView with sections for intent, steps, review notes
- Intent section: Markdown rendering of phase.md content
- Steps section: List or VStack of steps with checkmark indicators for implemented/reviewed
- Review notes section: Markdown rendering of review.md content (hidden if empty)
- Use swift-markdown-ui for markdown rendering
- Follow CardDetail pattern (empty state, scrollable content)

**Done when:**
- PhaseDetail.swift exists in Views/PhaseDetail/ directory
- Two states implemented (no selection, phase selected)
- Empty state uses ContentUnavailableView
- Intent section renders markdown from phase.intent
- Steps section shows all steps with completion indicators
- Review notes section renders markdown from phase.reviewNotes (hidden if empty)
- View uses ScrollView for long content
- View follows CardDetail patterns and style

## S008: Integrate with MainWindow

**Intent:** Wire PhaseList and PhaseDetail into MainWindow's middle and detail columns.

**Work:**
- Open `Sources/Hieroglyphs/Views/MainWindow.swift`
- Update middleColumnContent switch statement:
  - Replace PhasesPlaceholder with PhaseList() for `.phases` case
- Detail column should already handle selectedPhase (may need conditional logic)
- Update detailColumnContent to show PhaseDetail when selectedPhase is non-nil
- Ensure selection state flows correctly (sidebar → middle → detail)

**Done when:**
- MainWindow.swift updated
- .phases case in middleColumnContent shows PhaseList()
- Detail column shows PhaseDetail when selectedPhase is non-nil
- Selecting Phases section shows phase list
- Selecting a phase shows phase details
- PhasesPlaceholder.swift no longer used (can be deleted)

## S009: Inject PhaseService in App

**Intent:** Instantiate PhaseService and inject into environment and ViewModel.

**Work:**
- Open `Sources/Hieroglyphs/App.swift`
- Create PhaseService instance in init
- Pass phaseService to HieroglyphsVM init
- Add `.environment(\.phaseService, phaseService)` modifier to window content
- Follow pattern used for workspaceService, fileWatcher, tagReconciler, searchService

**Done when:**
- PhaseService instantiated in App.init
- PhaseService passed to HieroglyphsVM init
- PhaseService injected via environment key
- Pattern matches other service injections
- App compiles successfully

## S010: Write PhaseService Tests

**Intent:** Verify phase discovery, parsing, and error handling with comprehensive tests.

**Work:**
- Create `Tests/HieroglyphsTests/PhaseServiceTests.swift`
- Test cases:
  - loadPhases with valid phases directory returns sorted phases
  - loadPhases parses directory names correctly (number and slug)
  - loadPhases reads progress.yaml and extracts title, status, steps
  - loadPhases reads phase.md and extracts intent
  - loadPhases reads review.md when present
  - loadPhases handles missing review.md (reviewNotes empty)
  - loadPhases skips malformed directories (invalid names)
  - loadPhases handles missing progress.yaml (skips phase, logs warning)
  - loadPhases handles invalid YAML (skips phase, logs warning)
  - loadPhases returns empty array for non-existent sourceDirectory
  - loadPhases sorts phases by number ascending
- Use temporary directories with test fixtures
- Create sample phase directories with phase.md, progress.yaml, review.md
- Verify Phase models have correct field values
- Verify error cases handled gracefully (no crashes)

**Done when:**
- PhaseServiceTests.swift exists
- At least 10 test cases cover happy path and error cases
- Tests use temporary directories with controlled fixtures
- Tests verify parsing correctness (number, slug, title, status, intent, steps, reviewNotes)
- Tests verify sorting (phases returned in number order)
- Tests verify graceful error handling (missing files, invalid YAML)
- All tests pass
- swift test runs successfully

## S011: Write ViewModel Integration Tests

**Intent:** Verify ViewModel phase loading and state management.

**Work:**
- Open `Tests/HieroglyphsTests/HieroglyphsVMTests.swift`
- Add MockPhaseService class implementing PhaseProviding
- Test cases:
  - loadPhases with valid sourceDirectory updates phases state
  - loadPhases with nil sourceDirectory does nothing (phases remain empty)
  - loadPhases with phaseService error logs error and sets phases empty
  - selectedPhase updates correctly when user selects phase
- Use MockPhaseService to control returned phases and errors
- Verify ViewModel state updates correctly
- Follow existing ViewModel test patterns

**Done when:**
- MockPhaseService added to HieroglyphsVMTests.swift
- At least 4 test cases for phase-related ViewModel methods
- Tests verify state updates (phases, selectedPhase)
- Tests verify error handling (nil sourceDirectory, service errors)
- All existing tests still pass
- All new tests pass
- swift test runs successfully

## S012: Manual Verification

**Intent:** Verify UI works end-to-end with real Hieroglyphs project phases.

**Work:**
- Build and run app: `swift run`
- Create or open a project in Hieroglyphs
- Edit project and set sourceDirectory to Hieroglyphs repo path (`/Users/adam/Development/hieroglyphs`)
- Select Phases section in sidebar
- Verify phase list shows all phases from `.ushabti/phases/`
- Verify phases sorted by number (0001, 0002, ..., 0017)
- Verify each phase shows correct title and status badge
- Select a phase (e.g., 0009-tag-reconciler)
- Verify detail view shows intent from phase.md
- Verify detail view shows steps with completion indicators
- Verify detail view shows review notes from review.md
- Test edge cases:
  - Project with no sourceDirectory configured (empty state message)
  - Project with sourceDirectory pointing to directory with no .ushabti/phases/ (empty state message)
  - Phase with no review.md yet (review section hidden or shows "No review yet")

**Done when:**
- App runs without crashes
- Phase list loads and displays phases from Hieroglyphs repo
- Phases sorted correctly by number
- Phase details render correctly (intent, steps, review notes)
- Status badges display correctly
- Empty states work correctly
- Missing review.md handled gracefully
- No console errors or warnings (except expected "no phases found" messages)

## S013: Update Documentation

**Intent:** Document the phases system for future development.

**Work:**
- Create `.ushabti/docs/phases-view.md`
- Document:
  - Phase model structure
  - PhaseService protocol and implementation
  - How phase data is discovered and parsed
  - Empty state handling
  - Integration with ViewModel and views
  - Testing strategy
  - Limitations (read-only, no file watching, no search)
  - Future enhancements (editing, watching, filtering)
- Update `.ushabti/docs/index.md` to add phases-view.md entry
- Update `.ushabti/docs/architecture.md` to mention PhaseService in services layer
- Update `.ushabti/docs/models.md` to document Phase, PhaseStatus, PhaseStep
- Update `.ushabti/docs/views-ui.md` to document PhaseList and PhaseDetail

**Done when:**
- phases-view.md created with comprehensive documentation
- index.md updated with phases-view.md entry
- architecture.md mentions PhaseService
- models.md documents phase models
- views-ui.md documents phase views
- Documentation follows existing doc style and structure
- All docs are accurate and complete

## S014: Fix Section-Switching State Management Bug

**Intent:** Correct state management to ensure selections are cleared when switching between section types (Cards, Plans, Phases).

**Work:**
- Open `Sources/Hieroglyphs/HieroglyphsVM.swift`
- Update `selectSection(_:)` method to clear cross-section selection state
- When switching to `.cards(project)`, clear `selectedPhase` to nil
- When switching to `.plans(project)`, clear both `selectedPhase` and `selectedCard` to nil
- When switching to `.phases(project)`, clear `selectedCard` to nil
- When switching to nil (no section), clear both `selectedCard` and `selectedPhase` to nil
- This ensures the detail column always displays content consistent with the currently selected section

**Done when:**
- `selectSection(_:)` method updated with selection-clearing logic
- Selecting Phases section clears `selectedCard`
- Selecting Cards section clears `selectedPhase`
- Selecting Plans section clears both selections
- Selecting nil (no section) clears both selections
- Manual testing confirms: switching from Phases (with phase selected) to Cards shows card detail, not phase detail
- Manual testing confirms: switching from Cards (with card selected) to Phases shows empty phase detail state, not card detail
- Code compiles without errors
