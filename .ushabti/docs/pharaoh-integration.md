# Pharaoh Integration

## Overview

Pharaoh integration enables users to dispatch plans for automated execution and monitor Pharaoh's status directly within Hieroglyphs. This completes the development-in-Hieroglyphs loop: users plan work in Hieroglyphs, execute via Pharaoh, and monitor results without leaving the application.

**Pharaoh** is an npm package (`@adamrdrew/pharaoh`) that runs as a long-lived Node.js process watching `.pharaoh/dispatch/` for markdown files containing phase prompts. When a plan becomes "ready" in Hieroglyphs and the user clicks dispatch, Hieroglyphs writes the plan's phase prompt to `.pharaoh/dispatch/{plan-slug}.md`, triggering Pharaoh to execute the full Ushabti cycle (Scribe → Builder → Overseer).

## Architecture Components

### Models

**PharaohStatus** (`Sources/Hieroglyphs/Models/PharaohStatus.swift`)

Represents the current state of a Pharaoh process with five cases:

```swift
enum PharaohStatus: Equatable {
    case notRunning
    case idle
    case busy(phase: String, turnsElapsed: Int, runningCostUsd: Double, phaseStarted: Date?)
    case done(phase: String, costUsd: Double, turns: Int)
    case blocked(phase: String, error: String, costUsd: Double, turns: Int)
}
```

**Computed Properties:**
- `isRunning` — True if Pharaoh is in any state except notRunning
- `isBusy` — True if Pharaoh is actively executing a phase
- `isIdle` — True if Pharaoh is ready to accept work

**Enriched Status Fields:**
- `busy`: Includes `turnsElapsed` (current turn count), `runningCostUsd` (cost so far), and `phaseStarted` (ISO8601 timestamp for elapsed time display)
- `done`: Uses `costUsd` (not `cost`) and `turns` for final execution metrics
- `blocked`: Includes `costUsd` and `turns` for partial execution metrics before failure

**PharaohServerInfo** (`Sources/Hieroglyphs/Models/PharaohServerInfo.swift`)

Represents server metadata extracted from `pharaoh.json`:

```swift
struct PharaohServerInfo: Equatable {
    let status: String
    let pid: Int
    let started: Date
    let pharaohVersion: String
    let ushabtiVersion: String
    let model: String
    let cwd: String
    let phasesCompleted: Int
}
```

**Parsing:**
- Static method `parse(json: [String: Any]) -> PharaohServerInfo?`
- Returns nil if required fields missing or timestamp unparseable
- Uses ISO8601DateFormatter with fractional seconds for `started` field
- JSON keys use camelCase: `pharaohVersion`, `ushabtiVersion`, `phasesCompleted`

### Services

**PharaohProviding / PharaohService** (`Sources/Hieroglyphs/Services/`)

Protocol-based service for Pharaoh process management and status reading.

**Methods:**
- `start(in directory: String, model: String) throws` — Spawns Pharaoh process via `Foundation.Process` with shell profile sourcing
- `stop()` — Terminates running process
- `readStatus(from directory: String) -> PharaohStatus` — Reads and decodes `.pharaoh/pharaoh.json`
- `readLogs(from directory: String, count: Int) -> [String]` — Returns last N lines from `.pharaoh/pharaoh.log`
- `readEvents(from directory: String) -> [PharaohEvent]` — Reads and parses `.pharaoh/events.jsonl`
- `readServerInfo(from directory: String) -> PharaohServerInfo?` — Reads and parses server metadata from `.pharaoh/pharaoh.json`

**Implementation Details:**
- Uses `Process` with `/bin/zsh -l -c "npx @adamrdrew/pharaoh serve"` to source shell profile (ensures homebrew/nvm paths available)
- Sets `currentDirectoryURL` to project's `sourceDirectory`
- Monitors process termination via `terminationHandler`
- Kills process on `NSApplication.willTerminateNotification`
- Marked `@unchecked Sendable` for async compatibility

**Error Handling:**
- Returns `.notRunning` status if JSON file missing or unreadable
- Gracefully handles malformed JSON (returns `.notRunning`)
- Returns empty array if log file missing

### Event Stream Architecture

**PharaohEvent** (`Sources/Hieroglyphs/Models/PharaohEvent.swift`)

Represents a single event from the Pharaoh agent execution stream:

```swift
struct PharaohEvent: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let type: PharaohEventType
    let summary: String
    let detailJson: String?
}

enum PharaohEventType: String, Equatable {
    case toolCall = "tool_call"
    case toolProgress = "tool_progress"
    case toolSummary = "tool_summary"
    case text
    case turn
    case status
    case result
    case error
}
```

**Event Stream File Format:**
- File: `.pharaoh/events.jsonl` (JSON Lines format, one event per line)
- Each line is a JSON object with `timestamp` (ISO8601), `type`, `summary`, and optional `detail`
- Events are appended to the file as Pharaoh executes

**Event Parsing:**
- `PharaohEvent.parse(line: String) -> PharaohEvent?` — Static method parses a single JSON Lines entry
- Returns nil for malformed lines (graceful failure)
- Timestamp parsed with ISO8601DateFormatter including fractional seconds
- Detail object serialized to JSON string for storage (not decoded into typed structs)

**Event Detail Properties:**

PharaohEvent exposes typed computed properties for extracting structured data from `detailJson`:

- `hasDetail: Bool` — True if event has detail data
- `toolName: String?` — Extract tool name for tool_call events (from `detail.tool_name`)
- `toolInput: String?` — Extract tool input for tool_call events (from `detail.input`)
- `turnNumber: Int?` — Extract turn number for turn events (from `detail.turn`)
- `inputTokens: Int?` — Extract input token count for turn events (from `detail.input_tokens`)
- `outputTokens: Int?` — Extract output token count for turn events (from `detail.output_tokens`)
- `fullText: String?` — Extract full text for text events (from `detail.full_text`)
- `resultTurns: Int?` — Extract total turns for result events (from `detail.turns`)
- `resultCostUsd: Double?` — Extract total cost for result events (from `detail.cost_usd`)

All detail properties return nil gracefully if `detailJson` is nil, parse fails, or the field is missing.

**PharaohActivityStreamView** (`Sources/Hieroglyphs/Views/Pharaoh/PharaohActivityStreamView.swift`)

Detail column view that displays the real-time event stream:

- ScrollView with LazyVStack of PharaohEventRow components
- Polls events every 2 seconds via `readEvents(from:)`
- Auto-scrolls to bottom on new events (ScrollViewReader with anchor)
- Empty state shows ContentUnavailableView when no events exist

**PharaohEventRow** (`Sources/Hieroglyphs/Views/Pharaoh/PharaohEventRow.swift`)

Individual event row showing:
- Relative timestamp (Text(style: .relative) in 60pt fixed-width column)
- Type icon (SF Symbol, color-coded by event type)
- Summary text (truncated, font varies by type)
- Expandable detail section (PharaohEventDetailView) when `event.hasDetail` is true

**Turn Events:**
Turn events render as subtle separators (Divider with small "Turn N" label) rather than full rows to reduce visual clutter.

**PharaohEventDetailView** (`Sources/Hieroglyphs/Views/Pharaoh/PharaohEventDetailView.swift`)

Expandable disclosure group showing event-type-specific detail data:

- **tool_call events:** Shows tool name and tool input
- **turn events:** Shows turn number, input tokens, output tokens
- **text events:** Shows full text content
- **result events:** Shows total turns and total cost (formatted as currency)

Detail rows use compact monospaced font with label/value pairs. Missing detail fields are omitted gracefully (no empty rows displayed).

**Event Type Icons and Colors:**
- `toolCall`: wrench.fill, accent color, monospaced font
- `toolProgress`: clock.arrow.circlepath, secondary
- `toolSummary`: checkmark.circle, green
- `text`: text.bubble, secondary
- `turn`: separator (no icon)
- `status`: info.circle, blue
- `result`: checkmark.seal.fill, green, bold
- `error`: exclamationmark.triangle.fill, red, bold

### File Watching

**Third FSEventStream** (`FileWatcherService`)

Pharaoh status monitoring uses a separate FSEventStream watching `.pharaoh/` directory:

- **Protocol Methods:** `startWatchingPharaoh(path:onChange:)` and `stopWatchingPharaoh()`
- **Implementation:** Independent stream lifecycle, separate from workspace and phases streams
- **Event Callback:** Distinguishes between three streams by comparing stream references
- **Latency:** 0.5 seconds (same as other streams)

**Change Detection:**
- Watches entire `.pharaoh/` directory recursively
- Triggers UI updates when `pharaoh.json` or `pharaoh.log` modified
- Combined with polling (every 2 seconds) in PharaohView for guaranteed updates

### UI Components

**SidebarPharaohItem** (`Views/Sidebar/SidebarPharaohItem.swift`)

Displays Pharaoh status indicator in project disclosure groups:

- **Visibility:** Only shown for projects with non-nil `sourceDirectory`
- **Status Colors:** Red (notRunning), green (idle), orange (busy/done/blocked)
- **Polling:** Updates status every 2 seconds via async task
- **Selection:** Tagged with `.pharaoh(project)` for sidebar navigation

**PharaohView** (`Views/Pharaoh/PharaohView.swift`)

Full-screen view for Pharaoh management shown as middle column content:

**Not Running State:**
- "Start Pharaoh" button
- Description text explaining Pharaoh functionality
- Model picker (segmented): Opus/Sonnet/Haiku — selection passed to `--model` flag on start
- Error display if process start failed

**Running State:**
- **Server Information Section** (shown when `serverInfo` is non-nil):
  - Pharaoh Version
  - Ushabti Version
  - Model (selected on server start)
  - Working Directory (truncated if longer than 50 chars, showing last 2 path components)
  - PID
  - Started (relative time since server started)
  - Phases Completed (count of completed phases in this session)
- Status badge with color-coded state (idle/busy/done/blocked)
- Phase name and enriched metrics (for busy/done/blocked states):
  - Busy: Turns elapsed, running cost ($0.4f), live elapsed time (Text(style: .relative))
  - Done: Final cost, turns
  - Blocked: Error message (red banner), final cost, turns
- "Stop Pharaoh" button

**Update Strategy:**
- Polls status and server info every 2 seconds via `monitorStatus()` async task
- Calls `readServerInfo(from:)` on each poll and updates `serverInfo` state
- Detects status transitions for auto-completion and error alerts
- Combined with file watching for responsive updates

**Automatic Plan Completion:**
- Tracks `previousStatus` to detect busy → done transition
- Calls `autoCompletePlan(phase:)` to find matching plan by slug with `inProgress` status
- Updates plan status to `done` via `viewModel.updatePlanStatus(plan:status:)`
- Logs completion to console

**Error Surfacing:**
- Detects busy → blocked transition
- Shows alert with title "Phase Failed" and error message
- Alert remains visible until user clicks OK
- Blocked state continues showing error after alert dismissed

**PlanDetail Dispatch Button** (`Views/PlanDetail/PlanDetail.swift`)

Play button in toolbar with `canDispatch` conditions:

- Project has `sourceDirectory`
- Pharaoh status is `idle`
- Plan status is `ready`
- Phase prompt is non-empty

**Confirmation Alert:**
- Shows warning about setting plan to `inProgress`
- Primary button triggers `viewModel.dispatchPlan()`

### ViewModel Integration

**HieroglyphsVM Extensions**

**New Properties:**
- `private let pharaohService: PharaohProviding?` — Injected service reference
- `var pharaohModel: String = "opus"` — Selected model for plan dispatch (opus/sonnet/haiku)

**New Method:**
- `dispatchPlan()` — Writes dispatch file and updates plan status

**Dispatch Workflow:**
1. Guard check: plan selected, project selected, sourceDirectory set
2. Construct dispatch directory path: `{sourceDirectory}/.pharaoh/dispatch/`
3. Create directory if needed: `FileManager.createDirectory(withIntermediateDirectories:)`
4. Build markdown content using selected model:
   ```markdown
   ---
   phase: {plan.slug}
   model: {pharaohModel}
   ---

   {plan.phasePrompt}
   ```
5. Write file atomically: `{dispatchDirectory}/{plan-slug}.md`
6. Update plan status to `inProgress` via `updatePlanStatus()`

**Error Handling:**
- Logs errors to console (does not throw or show UI alerts)
- Graceful fallback if directory creation fails

### Model Selection

**UI Integration:**
- Segmented picker in PharaohView (visible only when Pharaoh is not running)
- Three options: Opus (default), Sonnet, Haiku
- Binds to `viewModel.pharaohModel`

**Process Start Integration:**
- Selected model passed to `PharaohService.start(in:model:)` which includes `--model <model>` in process arguments
- Model selection must be made before starting Pharaoh (cannot change mid-session)
- Model preference not persisted across app launches (defaults to opus)

**Dispatch Integration:**
- `dispatchPlan()` uses `pharaohModel` value in frontmatter instead of hardcoded "opus"
- Model selection applies to next dispatch only (no effect on running execution)

### Plan Status Changes

**New Status: inProgress**

Added to `PlanStatus` enum with raw value `"in-progress"`:

```swift
enum PlanStatus: String, Codable, CaseIterable {
    case planning = "planning"
    case ready = "ready"
    case inProgress = "in-progress"
    case done = "done"
}
```

**UI Treatment:**
- Icon: `circle.inset.filled` (same as `ready`)
- Color: Orange
- Non-editable: Phase prompt TextEditor disabled, "Add Card" and "Remove from Plan" buttons hidden

**Card Status Mapping:**
- `PlanService.mapPlanStatusToCardStatus(_:)` maps `inProgress` to `CardStatus.inProgress`
- When plan status changes to `inProgress`, linked cards transition to `inProgress` status

## Process Lifecycle

### Starting Pharaoh

**User Action:** Click "Start Pharaoh" in PharaohView

**Process:**
1. `PharaohService.start(in: sourceDirectory, model: selectedModel)` called with user's model selection
2. Creates `Process` instance
3. Sets executable to `/bin/zsh`, arguments to `["-l", "-c", "npx @adamrdrew/pharaoh serve --model \(model)"]`
4. Sets `currentDirectoryURL` to `sourceDirectory`
5. Registers `terminationHandler` to update UI on exit
6. Calls `process.run()` to spawn child process
7. Pharaoh server starts and begins watching `.pharaoh/dispatch/`

**Error Handling:**
- Throws `PharaohError.directoryNotFound` if `sourceDirectory` invalid
- Throws `PharaohError.processStartFailed` if process spawn fails
- PharaohView displays error message in UI

### Stopping Pharaoh

**User Action:** Click "Stop Pharaoh" in PharaohView

**Process:**
1. `PharaohService.stop()` called
2. Calls `process.terminate()` on running process
3. Sets internal process reference to nil
4. UI updates to "Not Running" state

**Automatic Termination:**
- `NSApplication.willTerminateNotification` observer in PharaohService
- Ensures child process killed when app quits

### Status Monitoring

**File-Based Status:**
- Pharaoh writes JSON status to `.pharaoh/pharaoh.json`
- Format varies by state (see PharaohStatus cases above)

**Reading Strategy:**
1. Read JSON file from disk
2. Parse with `JSONSerialization`
3. Extract `status` field (string)
4. Switch on status value to construct PharaohStatus enum
5. Extract associated values (phase name, cost, turns, error) based on status

**Update Frequency:**
- FSEventStream detects file changes within ~500ms
- Polling every 2 seconds provides guaranteed updates even if file watching misses events
- Combined strategy ensures responsive UI

## Dispatch Workflow

**Step 1: User prepares plan**
- Creates plan with title and linked cards
- Writes phase prompt in PlanDetail
- Sets status to "ready"

**Step 2: User triggers dispatch**
- Clicks play button in PlanDetail toolbar (visible only when `canDispatch` conditions met)
- Confirms dispatch in alert dialog

**Step 3: Hieroglyphs writes dispatch file**
- Calls `dispatchPlan()` in ViewModel
- Creates markdown file with frontmatter: `phase`, `model`
- Writes to `.pharaoh/dispatch/{plan-slug}.md`
- Sets plan status to `inProgress`

**Step 4: Pharaoh detects dispatch file**
- File watcher in Pharaoh server detects new markdown file
- Reads phase prompt content
- Invokes Scribe to plan phase

**Step 5: Pharaoh executes phase**
- Scribe writes `phase.md`, `steps.md`, scaffolds `progress.yaml`
- Builder implements steps, updates `progress.yaml`
- Overseer reviews implementation, writes `review.md`

**Step 6: Status updates**
- Pharaoh writes status to `pharaoh.json` (idle → busy → done/blocked)
- Pharaoh appends events to `events.jsonl` as execution proceeds
- FSEventStream and polling detect changes
- PharaohView and PharaohActivityStreamView update in real-time

**Step 7: Automatic completion or error surfacing**
- On busy → done transition: PharaohView auto-completes matching plan (sets status to `done`)
- On busy → blocked transition: PharaohView shows alert with error message

**Step 8: User reviews results**
- Views phase completion in `.ushabti/phases/{phase-id}/`
- Plan status already set to `done` automatically
- Reviews event stream for execution details

## Integration Points

### SidebarSection Enum

Added `.pharaoh(Project)` case to enable navigation:

```swift
enum SidebarSection: Hashable {
    case cards(Project)
    case plans(Project)
    case phases(Project)
    case pharaoh(Project)
}
```

**Handling:**
- `selectedProject` computed property extracts project
- `selectSection(_:)` clears cross-section state (cards, plans, phases)
- `MainWindow` shows `PharaohView` when `.pharaoh` selected

### Environment Injection

**App.swift:**
- Creates `PharaohService` instance
- Injects via `.environment(\.pharaohService, pharaohService)`
- Passes to `HieroglyphsVM` in initializer

**Service Access:**
- Views access via `@Environment(\.pharaohService)`
- ViewModel stores as `private let pharaohService: PharaohProviding?`

### Testing

**PharaohServiceTests** (`Tests/HieroglyphsTests/PharaohServiceTests.swift`)

Tests cover all public methods:

- `readStatus(from:)` with all five status shapes (idle, busy, done, blocked, missing file)
- `readLogs(from:count:)` with empty file, last N lines, count exceeds total
- `readEvents(from:)` with missing file, empty file, malformed lines, detail JSON, all event types
- `readServerInfo(from:)` with valid JSON, missing file, malformed JSON, missing fields
- Event detail property parsing (tool_call, turn, text, result, malformed JSON, hasDetail)

**Test Strategy:**
- Uses temporary directories for filesystem operations
- Creates mock `.pharaoh/pharaoh.json`, `.pharaoh/pharaoh.log`, and `.pharaoh/events.jsonl` files
- Verifies correct enum case returned with associated values
- Tests detail property extraction with all event types and error cases
- All tests pass

**MockFileWatcher:**
- Added `startWatchingPharaoh` and `stopWatchingPharaoh` to mock for ViewModel tests
- Tracks calls for verification

## Edge Cases and Limitations

### Process Management

**Single Process:** Only one Pharaoh process runs at a time (tied to PharaohService singleton, not per-project)

**Project Switching:** Process continues running when user switches projects (process tied to filesystem, not UI selection)

**Termination Detection:** `terminationHandler` enables UI state sync when process exits unexpectedly

### Status Transitions

**Manual Transitions:** User must manually move plan from `inProgress` back to `ready` or `done` (auto-transition deferred)

**No Validation:** Dispatch always sets status to `inProgress` regardless of Pharaoh response

**Empty Prompt Prevention:** Dispatch button hidden when `phasePrompt` is empty

### Error Handling

**Process Start Failures:** Displayed in PharaohView with error message, no crash

**JSON Decode Errors:** Return `.notRunning` status with no error UI

**Missing Files:** Log viewer shows empty, status shows `.notRunning`

### Performance

**Polling Overhead:** Status polling every 2 seconds adds minimal CPU usage

**Log Tailing:** Reading last 50 lines prevents memory issues with large logs

**File Watching:** Third FSEventStream adds minimal overhead (`.pharaoh/` updated infrequently)

## Future Enhancements

### Dispatch Queue

**Multiple Dispatches:**
- Queue pending dispatches when Pharaoh is busy
- Show dispatch history in PharaohView

### Cost Tracking

**Budget Management:**
- Track total cost across dispatches
- Show warnings when approaching budget limits
- Persist cost history across sessions

### Retry Logic

**Interrupted Phases:**
- Offer retry button for blocked phases
- Allow editing phase prompt before retry

### Multi-Process Support

**Per-Project Pharaoh:**
- Run separate Pharaoh process per project
- Requires process registry and lifecycle management
