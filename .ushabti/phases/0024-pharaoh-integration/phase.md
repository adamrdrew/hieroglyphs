# Phase 24: Pharaoh Integration

card: plan-in-progress-status
card: pharaoh-process-service
card: pharaoh-sidebar-integration
card: pharaoh-status-view
card: plan-dispatch-to-pharaoh

## Intent

Integrate Pharaoh into Hieroglyphs as a first-class feature, enabling users to dispatch plans for execution and monitor Pharaoh's status directly within the app. This completes the development-in-Hieroglyphs loop: users plan work in Hieroglyphs, execute via Pharaoh, and monitor results in Hieroglyphs without leaving the application.

Pharaoh is an npm package (`@adamrdrew/pharaoh`) that runs as a long-lived Node.js process watching `.pharaoh/dispatch/` for markdown files containing phase prompts. When a plan becomes "ready" in Hieroglyphs and the user clicks a dispatch button, Hieroglyphs writes the plan's phase prompt to `.pharaoh/dispatch/{plan-slug}.md`, triggering Pharaoh to execute the full Ushabti cycle (Scribe → Builder → Overseer).

Users will see Pharaoh's status in the sidebar (not running, idle, busy, done, blocked), manage the server (start/stop), view logs, and dispatch plans with a single click. This transforms Hieroglyphs from a planning tool into an integrated development orchestrator.

## Scope

**In scope:**

1. Add `inProgress` status to `PlanStatus` enum (raw value `"in-progress"`)
2. Update `PlanDetail` status picker to include the new status
3. Style `inProgress` with `circle.inset.filled` icon and `.orange` color
4. Make plans at `inProgress` status non-editable (phase prompt, card links)
5. Create `PharaohProviding` protocol and `PharaohService` implementation
6. Spawn Pharaoh process via `Foundation.Process` with `/bin/zsh -l -c "npx @adamrdrew/pharaoh serve"`
7. Set process `currentDirectoryURL` to project's `sourceDirectory`
8. Monitor process termination via `terminationHandler`
9. Read and decode `.pharaoh/pharaoh.json` for status (idle, busy, done, blocked)
10. Add third `FSEventStream` for `.pharaoh/pharaoh.json` watching
11. Read recent lines (~50) from `.pharaoh/pharaoh.log`
12. Kill child process on `NSApplication.willTerminateNotification`
13. Inject service via `PharaohServiceEnvironmentKey`
14. Create `PharaohStatus` model enum with cases: `notRunning`, `idle`, `busy(phase: String)`, `done(phase: String, cost: Double, turns: Int)`, `blocked(phase: String, error: String)`
15. Add `.pharaoh(Project)` case to `SidebarSection` enum
16. Handle new case in `selectedProject` computed property and `selectSection()` method
17. Handle in `MainWindow` middle column switch to show `PharaohView`
18. Create `SidebarPharaohItem` view with status indicator: red (not running), green (idle), orange (busy)
19. Only show for projects with non-nil `sourceDirectory`
20. Place below Phases in project disclosure group
21. Create `PharaohView` as middle+detail content when `.pharaoh` section selected
22. Show "Start Pharaoh" button and description when not running
23. Show status badge, phase info, cost/turns, error message, log viewer, and "Stop Pharaoh" button when running
24. Add play button (`play.circle.fill`) to `PlanDetail` toolbar
25. Show button only when: project has `sourceDirectory`, Pharaoh is idle, plan is `ready`, and plan has non-empty `phasePrompt`
26. On click, show confirmation alert, write dispatch file to `.pharaoh/dispatch/{plan-slug}.md`, and set plan status to `inProgress`

**Out of scope:**

- Multiple concurrent Pharaoh processes (one at a time)
- Pharaoh configuration UI (relies on defaults)
- Plan status auto-transition from `inProgress` back to `ready` or `done` (manual for now)
- Phase result import/visualization beyond log viewing
- Cost tracking or budget management
- Pharaoh version checking or auto-updates
- Retry/resume logic for interrupted phases
- Process switching when user changes projects (existing process continues running)

## Constraints

**Laws:**

- L01 (Filesystem as Source of Truth): Pharaoh status read from `.pharaoh/pharaoh.json`, dispatch via filesystem writes
- L05 (External Changes First-Class): FSEvents watch on `.pharaoh/pharaoh.json` for reactive UI updates
- L06 (Platform Leverage): Use `Foundation.Process` for process management, FSEvents for file watching
- L09 (Sandi Metz Principles): Protocol-based service (`PharaohProviding`), models as plain data, composition over inheritance
- L10 (Design Consistency): Follow existing patterns (three-column layout, SF Symbols, consistent spacing)
- L11 (Test Coverage): All public API methods tested

**Style:**

- Protocol-based service design (PharaohProviding protocol, PharaohService implementation)
- Plain data models (PharaohStatus enum with associated values, no framework dependencies)
- Service injection via SwiftUI environment keys
- Small, focused views (SidebarPharaohItem, PharaohView separated)
- No regex (use string methods for path parsing)
- Clarity over brevity (descriptive names, explicit logic)

**Architecture:**

- Follows existing service pattern: protocol → implementation → environment key → injection in App.swift
- Follows existing sidebar pattern: SidebarSection enum case → SidebarItem view → MainWindow switch
- Follows existing file watching pattern: FSEventStream → onChange closure → reload method
- PlanStatus change requires updating PlanService reader/writer (YAML field preservation per L02)

## Acceptance Criteria

1. `PlanStatus` enum includes `inProgress` case with raw value `"in-progress"`
2. `PlanDetail` status picker includes "In Progress" option styled with orange `circle.inset.filled` icon
3. Plans with `inProgress` status are non-editable (phase prompt TextEditor disabled, "Add Card" button hidden)
4. `PharaohProviding` protocol defines methods: `start(in:)`, `stop()`, `readStatus(from:)`, `readLogs(from:count:)`
5. `PharaohService` spawns Node.js process with shell profile sourced (`-l` flag)
6. Service reads `.pharaoh/pharaoh.json` and decodes into `PharaohStatus` enum
7. Service reads last ~50 lines from `.pharaoh/pharaoh.log`
8. Service kills process on app termination notification
9. Third FSEventStream watches `.pharaoh/pharaoh.json` and triggers UI updates
10. `PharaohStatus` enum has five cases covering all Pharaoh states
11. `SidebarSection` includes `.pharaoh(Project)` case
12. `HieroglyphsVM.selectedProject` computed property handles `.pharaoh` case
13. `MainWindow` shows `PharaohView` when `.pharaoh` section selected
14. `SidebarPharaohItem` renders status indicator with correct colors (red/green/orange)
15. Sidebar Pharaoh item only visible for projects with `sourceDirectory`
16. `PharaohView` shows start button and description when Pharaoh not running
17. `PharaohView` shows status, phase info, logs, and stop button when running
18. `PlanDetail` shows play button only when all conditions met
19. Play button click shows confirmation alert before dispatch
20. Dispatch writes markdown file with frontmatter to `.pharaoh/dispatch/{plan-slug}.md`
21. Dispatch sets plan status to `inProgress` via `updatePlanStatus()`
22. Tests cover all public methods in `PharaohService`
23. Tests pass (`swift test`)
24. Lint passes (no unused symbols, no dead code)

## Risks / Notes

**Process lifecycle:**
- Process continues running when user switches projects (tied to filesystem, not UI selection)
- Process termination detection via `terminationHandler` enables UI state sync
- Shell profile sourcing (`-l` flag) ensures homebrew/nvm paths available for npx

**File watching performance:**
- Third FSEventStream adds minimal overhead (`.pharaoh/pharaoh.json` updated infrequently)
- Log reading limited to ~50 lines prevents memory issues with large logs

**Error handling:**
- Process spawn failure shows error in PharaohView (e.g., "Failed to start: command not found")
- JSON decode errors show "unknown" status with error message
- Missing log file shows empty log viewer (no error UI)

**Plan status transitions:**
- User must manually move plan from `inProgress` back to `ready` or `done` (auto-transition deferred)
- Consider adding phase completion detection in future (watch `.ushabti/phases/` for review.md GREEN status)

**Dispatch validation:**
- Empty `phasePrompt` prevents dispatch (button hidden)
- Dispatch always sets status to `inProgress` (no validation of Pharaoh response)
- Consider adding dispatch queue/history in future

**Phase vs Plan terminology:**
- Plans (Hieroglyphs concept) generate phase prompts for Ushabti Phases (external concept)
- Keep naming clear: "Plan" in UI, "phase prompt" for file content, "phase" in Pharaoh status
