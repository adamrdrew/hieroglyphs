# Implementation Steps

## S001: Add inProgress status to PlanStatus enum

**Intent:** Enable plans to represent active execution state distinct from planning and completion.

**Work:**

- Add `case inProgress = "in-progress"` to `PlanStatus` enum in `Sources/Hieroglyphs/Models/PlanStatus.swift`
- Update `PlanListEntry` to handle new status with orange `circle.inset.filled` icon
- Update `PlanDetail` status picker to include "In Progress" option
- Update `PlanService` YAML reader to handle new status value (decoder handles automatically via raw value)

**Done when:**

- `PlanStatus` enum compiles with four cases: `planning`, `ready`, `inProgress`, `done`
- Status picker in `PlanDetail` shows "In Progress" option
- Plans can be saved with `inProgress` status and persist correctly to `plan.yaml`
- `swift test` passes

## S002: Make in-progress plans non-editable

**Intent:** Prevent users from modifying plans while Pharaoh is executing them, avoiding conflicts and confusion.

**Work:**

- Add computed property `isEditable` to `PlanDetail` that returns `false` when plan status is `inProgress`
- Disable phase prompt TextEditor when `!isEditable`
- Hide "Add Card" button when `!isEditable`
- Hide context menu "Remove from Plan" when `!isEditable`
- Add visual indicator (e.g., subtle text: "Plan is executing...") when non-editable

**Done when:**

- Plans with `inProgress` status show disabled/hidden editing controls
- Plans with other statuses remain fully editable
- UI clearly indicates when plan is non-editable
- `swift test` passes

## S003: Create PharaohStatus model

**Intent:** Define typed representation of Pharaoh's state machine for type-safe status handling.

**Work:**

- Create `Sources/Hieroglyphs/Models/PharaohStatus.swift`
- Define enum with cases:
  - `case notRunning`
  - `case idle`
  - `case busy(phase: String)`
  - `case done(phase: String, cost: Double, turns: Int)`
  - `case blocked(phase: String, error: String)`
- Make enum `Equatable` for testing
- Add computed properties: `isRunning`, `isBusy`, `isIdle` for UI logic

**Done when:**

- `PharaohStatus` model compiles
- Enum has five cases with appropriate associated values
- Computed properties return correct boolean values for each case
- Model is Equatable
- `swift test` passes with basic model tests

## S004: Create PharaohProviding protocol

**Intent:** Define service contract for Pharaoh process management and status reading.

**Work:**

- Create `Sources/Hieroglyphs/Services/PharaohProviding.swift`
- Define protocol with methods:
  - `func start(in directory: String) throws`
  - `func stop()`
  - `func readStatus(from directory: String) -> PharaohStatus`
  - `func readLogs(from directory: String, count: Int) -> [String]`
- Document each method with parameters, behavior, and error conditions
- Define `PharaohError` enum for typed errors

**Done when:**

- Protocol compiles with four methods
- Method signatures match documented behavior
- Error enum defined with appropriate cases
- Documentation complete
- `swift test` passes

## S005: Implement PharaohService

**Intent:** Provide concrete implementation of Pharaoh process management.

**Work:**

- Create `Sources/Hieroglyphs/Services/PharaohService.swift`
- Implement `start(in:)`:
  - Create `Process` instance
  - Set `executableURL` to `/bin/zsh`
  - Set `arguments` to `["-l", "-c", "npx @adamrdrew/pharaoh serve"]`
  - Set `currentDirectoryURL` to provided directory
  - Set `terminationHandler` to detect exit
  - Call `run()`
- Implement `stop()`:
  - Call `terminate()` on process
  - Set process reference to nil
- Implement `readStatus(from:)`:
  - Construct path to `.pharaoh/pharaoh.json`
  - Read file contents
  - Decode JSON to dictionary
  - Map to `PharaohStatus` enum based on status field
- Implement `readLogs(from:count:)`:
  - Construct path to `.pharaoh/pharaoh.log`
  - Read file, split by newlines
  - Return last `count` lines
- Add property `private var process: Process?` to track running process
- Add notification observer for `NSApplication.willTerminateNotification` to call `stop()`

**Done when:**

- Service compiles and conforms to protocol
- `start(in:)` spawns process successfully
- `stop()` terminates process
- `readStatus(from:)` correctly maps JSON to enum cases
- `readLogs(from:count:)` returns tail of log file
- Process terminates on app quit
- `swift test` passes with service tests (using temp directories)

## S006: Add PharaohService environment key

**Intent:** Enable SwiftUI environment-based dependency injection for PharaohService.

**Work:**

- Add environment key definition to `PharaohProviding.swift`:
  - `struct PharaohServiceEnvironmentKey: EnvironmentKey`
  - `static var defaultValue: PharaohProviding? = nil`
- Add environment extension:
  - `extension EnvironmentValues { var pharaohService: PharaohProviding? }`
- Update `App.swift` to create `PharaohService` instance and inject via `.environment(\.pharaohService, service)`
- Update `HieroglyphsVM` init to accept `pharaohService: PharaohProviding?` parameter
- Update `HieroglyphsVM` to store service as private property

**Done when:**

- Environment key compiles
- Service injected in `App.swift`
- ViewModel accepts and stores service reference
- Views can access service via `@Environment(\.pharaohService)`
- `swift test` passes

## S007: Add third FSEventStream for pharaoh.json watching

**Intent:** Enable real-time UI updates when Pharaoh status changes externally.

**Work:**

- Add `startWatchingPharaoh(path:onChange:)` method to `FileWatching` protocol
- Add `stopWatchingPharaoh()` method to protocol
- Implement methods in `FileWatcherService`:
  - Create third FSEventStream instance for `.pharaoh/` directory
  - Configure with same settings (0.5s latency, main queue)
  - Store stream reference separately from workspace/phases streams
- Add `startWatchingPharaoh()` method to `HieroglyphsVM`:
  - Guard check `selectedProject.sourceDirectory` is not nil
  - Construct pharaoh path: `{sourceDirectory}/.pharaoh/`
  - Call `fileWatcher?.startWatchingPharaoh(path:onChange:)`
  - onChange calls `handlePharaohFileChange(url:)`
- Add `handlePharaohFileChange(url:)` to ViewModel:
  - Check if path contains `pharaoh.json`
  - Call `loadPharaohStatus()` to refresh status
- Call `startWatchingPharaoh()` when project selection changes (in `restartPhasesWatching()` or separate method)

**Done when:**

- Third FSEventStream watches `.pharaoh/` directory
- Changes to `pharaoh.json` trigger UI updates within ~500ms
- File watching starts/stops correctly on project selection changes
- `swift test` passes with mock watcher

## S008: Add .pharaoh case to SidebarSection enum

**Intent:** Enable navigation to Pharaoh status view via sidebar selection.

**Work:**

- Add `case pharaoh(Project)` to `SidebarSection` enum in `HieroglyphsVM.swift`
- Update `selectedProject` computed property to handle `.pharaoh` case
- Update `selectSection(_:)` method if needed (likely works automatically via enum assignment)
- Ensure enum remains `Hashable` for List selection binding

**Done when:**

- `SidebarSection` enum compiles with four cases
- `selectedProject` returns correct project for `.pharaoh(project)` case
- Enum conformance to `Hashable` maintained
- `swift test` passes

## S009: Create SidebarPharaohItem view

**Intent:** Display Pharaoh status indicator in sidebar per project.

**Work:**

- Create `Sources/Hieroglyphs/Views/Sidebar/SidebarPharaohItem.swift`
- Accept `project: Project` parameter
- Use `@Environment(\.pharaohService)` to access service
- Call `pharaohService?.readStatus(from: project.sourceDirectory)` on appear
- Render:
  - `circle.fill` SF Symbol with color: red (notRunning), green (idle), orange (busy/done/blocked)
  - Text: "Pharaoh"
  - Tag with `.pharaoh(project)` for List selection
- Update status periodically (e.g., every 2 seconds when view is visible)
- Follow existing `SidebarPhasesItem` pattern

**Done when:**

- View compiles and renders in sidebar
- Status indicator shows correct color for each Pharaoh state
- Only visible for projects with non-nil `sourceDirectory`
- Tapping item selects `.pharaoh(project)` section
- `swift test` passes (view not unit tested, manual verification)

## S010: Update Sidebar to include Pharaoh item

**Intent:** Integrate Pharaoh item into project disclosure groups in sidebar.

**Work:**

- Open `Sources/Hieroglyphs/Views/Sidebar/Sidebar.swift`
- In project disclosure group (ForEach over projects), add `SidebarPharaohItem` after `SidebarPhasesItem`
- Conditionally show only if `project.sourceDirectory != nil`
- Ensure item tagged for selection binding

**Done when:**

- Pharaoh item appears below Phases in each project group
- Item hidden for projects without `sourceDirectory`
- Selection binding works correctly
- Sidebar compiles and renders
- `swift test` passes

## S011: Create PharaohView

**Intent:** Provide detailed Pharaoh status view as middle+detail content.

**Work:**

- Create `Sources/Hieroglyphs/Views/Pharaoh/PharaohView.swift`
- Accept `project: Project` parameter
- Use `@Environment(\.pharaohService)` to access service
- Use `@Environment(HieroglyphsVM.self)` to access ViewModel
- Implement two states:
  - **Not Running:**
    - "Start Pharaoh" button calls `pharaohService?.start(in: project.sourceDirectory)`
    - Description: "Pharaoh executes Ushabti development phases automatically..."
  - **Running:**
    - Status badge (Text with background color)
    - Phase name when busy/done/blocked
    - Start time / completion time / duration
    - Cost and turns when done/blocked
    - Error message when blocked
    - Log viewer: ScrollView with monospaced Text, auto-scroll to bottom
    - "Stop Pharaoh" button calls `pharaohService?.stop()`
- Refresh status and logs every 2 seconds when running
- Follow existing detail view patterns (ScrollView, VStack, Section-like groupings)

**Done when:**

- View compiles and renders both states
- Start button spawns Pharaoh process
- Stop button terminates process
- Status updates in real-time via file watching + polling
- Logs display and auto-scroll
- View follows design consistency (spacing, fonts, colors)
- `swift test` passes (view not unit tested)

## S012: Update MainWindow to show PharaohView

**Intent:** Route `.pharaoh` section selection to display PharaohView.

**Work:**

- Open `Sources/Hieroglyphs/Views/MainWindow.swift`
- In middle column switch statement (or if-let binding), add case for `.pharaoh(let project)`
- Show `PharaohView(project: project)` as middle+detail content (spans both columns)
- Follow existing pattern from `.phases` case

**Done when:**

- Selecting Pharaoh in sidebar shows `PharaohView`
- View spans middle and detail columns appropriately
- Navigation transitions smoothly
- `swift test` passes

## S013: Add play button to PlanDetail

**Intent:** Enable plan dispatch to Pharaoh from plan detail view.

**Work:**

- Open `Sources/Hieroglyphs/Views/PlanDetail/PlanDetail.swift`
- Add `@Environment(\.pharaohService)` to access service
- Add computed property `canDispatch`:
  - Check `project.sourceDirectory != nil`
  - Check `pharaohService?.readStatus().isIdle == true`
  - Check `plan.status == .ready`
  - Check `!plan.phasePrompt.isEmpty`
- Add toolbar item (or header button):
  - SF Symbol: `play.circle.fill`
  - Color: `.blue`
  - Action: show confirmation alert
  - Only visible when `canDispatch`
- Add `@State var showingDispatchConfirmation = false`
- Add `.alert("Run this plan with Pharaoh?", isPresented: $showingDispatchConfirmation)`:
  - Primary button: "Run" → calls `dispatchPlan()`
  - Secondary button: "Cancel"

**Done when:**

- Play button visible only when all conditions met
- Button hidden (not disabled) when conditions not met
- Tapping button shows confirmation alert
- Alert buttons wired correctly
- `swift test` passes

## S014: Implement plan dispatch logic

**Intent:** Write dispatch file and update plan status when user confirms dispatch.

**Work:**

- Add `dispatchPlan()` method to `HieroglyphsVM`:
  - Guard check `selectedPlan`, `selectedProject.sourceDirectory`, `workspacePath`
  - Construct dispatch file path: `{sourceDirectory}/.pharaoh/dispatch/{plan.slug}.md`
  - Create `.pharaoh/dispatch/` directory if missing
  - Construct markdown content:
    ```markdown
    ---
    phase: {plan.slug}
    model: opus
    ---

    {plan.phasePrompt}
    ```
  - Write file atomically via `Data.write(to:options: .atomic)`
  - Call `updatePlanStatus(plan: plan, status: .inProgress)`
- Call `dispatchPlan()` from alert primary button action in `PlanDetail`

**Done when:**

- Dispatch creates markdown file with correct frontmatter and content
- Plan status changes to `inProgress`
- File write errors logged (don't crash)
- Plans reload to reflect status change
- `swift test` passes with dispatch tests

## S015: Write tests for PharaohService

**Intent:** Ensure service behavior is correct and regressions are caught.

**Work:**

- Create `Tests/HieroglyphsTests/PharaohServiceTests.swift`
- Test `readStatus(from:)`:
  - Create temp directory with `.pharaoh/pharaoh.json`
  - Write JSON for each status shape (idle, busy, done, blocked)
  - Verify correct enum case returned
- Test `readLogs(from:count:)`:
  - Create temp directory with `.pharaoh/pharaoh.log`
  - Write multiple lines
  - Verify last N lines returned
- Test process lifecycle (start/stop):
  - Mock or integration test with real process
  - Verify process starts and can be stopped
  - Verify termination handler called
- Add mock implementation for protocol testing in ViewModelTests

**Done when:**

- All PharaohService public methods have tests
- Tests cover happy path and error conditions
- Tests pass reliably
- `swift test` runs without failures
- Test coverage includes status mapping logic

## S016: Update documentation

**Intent:** Ensure `.ushabti/docs/` reflects new Pharaoh integration architecture.

**Work:**

- Update `.ushabti/docs/architecture.md`:
  - Add PharaohService to Services Layer section
  - Document PharaohStatus model in Models section
  - Note third FSEventStream for `.pharaoh/` watching
- Update `.ushabti/docs/viewmodel.md`:
  - Document new methods: `dispatchPlan()`, `loadPharaohStatus()`, `handlePharaohFileChange()`
  - Update service injection section to include `pharaohService`
- Create `.ushabti/docs/pharaoh-integration.md`:
  - Overview of Pharaoh integration
  - Process lifecycle management
  - Dispatch workflow (plan → file → Pharaoh)
  - Status synchronization via file watching
  - UI patterns (sidebar item, status view, dispatch button)
- Update `.ushabti/docs/plans-system.md`:
  - Document new `inProgress` status
  - Document dispatch workflow
  - Note non-editable state for in-progress plans
- Update `.ushabti/docs/file-watching.md`:
  - Document third FSEventStream for `.pharaoh/pharaoh.json`
  - Note separate lifecycle from workspace/phases streams

**Done when:**

- All affected documentation files updated
- New `pharaoh-integration.md` created with comprehensive coverage
- Documentation accurate and consistent with implementation
- No stale references to old behavior
- Docs follow existing format and style
