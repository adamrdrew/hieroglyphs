# Implementation Steps

## S001: Update PharaohStatus enum with enriched fields

**Intent**: Extend the status model to include cost, turns, and timing data from the Pharaoh server.

**Work**:
- Open `Sources/Hieroglyphs/Models/PharaohStatus.swift`
- Update the `busy` case to: `case busy(phase: String, turnsElapsed: Int, runningCostUsd: Double, phaseStarted: Date?)`
- Update the `done` case to: `case done(phase: String, costUsd: Double, turns: Int)`
- Update the `blocked` case to: `case blocked(phase: String, error: String, costUsd: Double, turns: Int)`
- Update computed properties `isRunning`, `isBusy`, `isIdle` to handle new associated values (pattern matching updates)

**Done when**:
- PharaohStatus.swift compiles without errors
- All case patterns match the new associated value shapes
- Computed properties correctly handle all cases

## S002: Update PharaohService.readStatus() to parse enriched JSON

**Intent**: Parse the new fields from `pharaoh.json` and construct updated enum cases.

**Work**:
- Open `Sources/Hieroglyphs/Services/PharaohService.swift`
- In `readStatus(from:)`, update the `busy` case parsing:
  - Read `turnsElapsed` as Int, default to 0 if missing
  - Read `runningCostUsd` as Double, default to 0.0 if missing
  - Read `phaseStarted` as String, parse via `ISO8601DateFormatter` (with `.withFractionalSeconds` option), default to nil if missing or parse fails
- In `readStatus(from:)`, update the `done` case parsing:
  - Read `costUsd` as Double (JSON key is `costUsd`, not `cost`)
  - Read `turns` as Int
- In `readStatus(from:)`, update the `blocked` case parsing:
  - Read `error` as String
  - Read `costUsd` as Double, default to 0.0 if missing
  - Read `turns` as Int, default to 0 if missing

**Done when**:
- PharaohService.swift compiles without errors
- `readStatus()` correctly constructs all five enum cases with proper associated values
- Missing fields handled gracefully with sensible defaults

## S003: Refactor PharaohView to display enriched status

**Intent**: Update the UI to display cost, turns, and elapsed time for busy/done/blocked states.

**Work**:
- Open `Sources/Hieroglyphs/Views/Pharaoh/PharaohView.swift`
- Remove the `logViewerSection` entirely (and any references to logs)
- Update the `busy` state display to show:
  - Phase name
  - Turns elapsed: `Text("Turns: \(turnsElapsed)")`
  - Running cost: `Text(String(format: "$%.4f", runningCostUsd))`
  - Elapsed time: if `phaseStarted` is non-nil, add `Text(phaseStarted, style: .relative)` to show live relative time
- Update the `done` state display to match new enum shape (use `costUsd` and `turns`)
- Update the `blocked` state display to show error (red banner), `costUsd`, and `turns`

**Done when**:
- PharaohView.swift compiles without errors
- Log viewer section is removed
- Busy state displays turns, cost, and elapsed time
- Done state displays final cost and turns
- Blocked state displays error, cost, and turns

## S004: Create PharaohEvent model with JSON parsing

**Intent**: Define the event model for parsing structured agent events from `.pharaoh/events.jsonl`.

**Work**:
- Create file `Sources/Hieroglyphs/Models/PharaohEvent.swift`
- Define `PharaohEvent` struct:
  - Fields: `id: UUID`, `timestamp: Date`, `type: PharaohEventType`, `summary: String`, `detailJson: String?`
  - Conformances: `Identifiable`, `Equatable`
- Define `PharaohEventType` enum (String raw values):
  - Cases: `toolCall = "tool_call"`, `toolProgress = "tool_progress"`, `toolSummary = "tool_summary"`, `text`, `turn`, `status`, `result`, `error`
- Add static method `parse(line: String) -> PharaohEvent?`:
  - Parse line as JSON using `JSONSerialization.jsonObject`
  - Extract `timestamp` (String), `type` (String), `summary` (String)
  - Parse timestamp with `ISO8601DateFormatter` (with `.withFractionalSeconds`)
  - Construct `PharaohEventType` from raw value (return nil if unknown)
  - If `detail` object exists, serialize to JSON String for `detailJson`
  - Return `PharaohEvent` or nil if parsing fails

**Done when**:
- PharaohEvent.swift file exists and compiles
- Model includes all required fields and conformances
- `parse(line:)` method correctly decodes JSON Lines format
- Malformed lines return nil (graceful failure)

## S005: Add readEvents method to PharaohService

**Intent**: Provide a service method for reading and parsing the event stream.

**Work**:
- Open `Sources/Hieroglyphs/Services/PharaohProviding.swift`
- Add method signature to protocol: `func readEvents(from directory: String) -> [PharaohEvent]`
- Open `Sources/Hieroglyphs/Services/PharaohService.swift`
- Implement `readEvents(from:)`:
  - Construct path: `directory + "/.pharaoh/events.jsonl"`
  - Check file exists with `FileManager.default.fileExists(atPath:)`
  - If missing, return empty array
  - Read file content as String
  - Split on newline: `content.split(separator: "\n")`
  - CompactMap with `PharaohEvent.parse(line: String($0))`
  - Return array of events

**Done when**:
- PharaohProviding protocol includes `readEvents(from:)` method
- PharaohService implements `readEvents(from:)` correctly
- Method returns empty array if file missing
- Method gracefully skips malformed lines and returns valid events

## S006: Create PharaohEventRow view

**Intent**: Define a row view for displaying individual events in the stream.

**Work**:
- Create file `Sources/Hieroglyphs/Views/Pharaoh/PharaohEventRow.swift`
- Define `PharaohEventRow` struct with `let event: PharaohEvent`
- Layout with HStack:
  - Relative timestamp: `Text(event.timestamp, style: .relative).font(.caption2.monospacedDigit()).foregroundStyle(.tertiary).frame(width: 60, alignment: .trailing)`
  - Type icon: `Image(systemName: iconName).foregroundStyle(iconColor).frame(width: 16)`
  - Summary: `Text(event.summary).font(summaryFont).lineLimit(1).truncationMode(.tail)`
- Add computed properties for `iconName`, `iconColor`, `summaryFont` based on event type:
  - `toolCall`: `wrench.fill`, accent, `.callout.monospaced()`
  - `toolProgress`: `clock.arrow.circlepath`, secondary, `.callout`
  - `toolSummary`: `checkmark.circle`, green, `.callout`
  - `text`: `text.bubble`, secondary, `.callout`
  - `turn`: render as subtle separator (Divider + small "Turn N" label), not full row
  - `status`: `info.circle`, blue, `.callout`
  - `result`: `checkmark.seal.fill`, green, `.callout.bold()`
  - `error`: `exclamationmark.triangle.fill`, red, `.callout.bold()`
- Padding: `.padding(.vertical, 2)`

**Done when**:
- PharaohEventRow.swift file exists and compiles
- View displays timestamp, icon, and summary
- Icons and colors match event types
- Turn events render as separators, not rows
- Layout is compact and readable

## S007: Create PharaohActivityStreamView

**Intent**: Build the detail column view for displaying the real-time event stream.

**Work**:
- Create file `Sources/Hieroglyphs/Views/Pharaoh/PharaohActivityStreamView.swift`
- Define `PharaohActivityStreamView` struct with `let project: Project`
- Add environment: `@Environment(\.pharaohService) private var pharaohService`
- Add state: `@State private var events: [PharaohEvent] = []`, `@State private var autoScroll = true`
- Body:
  - If `events.isEmpty`: `ContentUnavailableView("No Events", systemImage: "list.bullet", description: Text("Events will appear here when Pharaoh executes a phase."))`
  - Else: `eventList` (ScrollView with ScrollViewReader and LazyVStack)
- `eventList` implementation:
  - `ScrollViewReader { proxy in ScrollView { LazyVStack { ForEach(events) { PharaohEventRow(event: $0) } Color.clear.frame(height: 1).id("bottom") } } }`
  - On each poll, if `autoScroll` is true: `proxy.scrollTo("bottom", anchor: .bottom)` with animation
- `pollEvents()` async task:
  - Loop: read events via `pharaohService.readEvents(from: sourceDirectory)`, update `events`, sleep 2 seconds
  - Add `.task { await pollEvents() }` modifier
- Navigation title: `.navigationTitle("Activity")`

**Done when**:
- PharaohActivityStreamView.swift file exists and compiles
- Empty state shows when no events
- Event list displays all events via PharaohEventRow
- Auto-scrolls to bottom on each update
- Polls events every 2 seconds

## S008: Wire PharaohActivityStreamView to MainWindow detail column

**Intent**: Route the `.pharaoh` sidebar selection to display the activity stream in the detail column.

**Work**:
- Open `Sources/Hieroglyphs/Views/MainWindow.swift`
- Locate the `detailColumnContent` computed property
- Update the switch statement for `.pharaoh(let project)` case to show `PharaohActivityStreamView(project: project)` instead of `Text("")`

**Done when**:
- MainWindow.swift compiles without errors
- Selecting Pharaoh in sidebar shows PharaohActivityStreamView in detail column
- Content column continues to show PharaohView

## S009: Implement auto-complete plan on success

**Intent**: Automatically transition plans from `inProgress` to `done` when Pharaoh completes a phase.

**Work**:
- Open `Sources/Hieroglyphs/Views/Pharaoh/PharaohView.swift`
- Add state: `@State private var previousStatus: PharaohStatus = .notRunning`
- In `updateStatus()` (or equivalent method that handles status updates):
  - Read new status
  - Check for transition: `if case .busy = previousStatus, case .done(let phase, _, _) = newStatus { autoCompletePlan(phase: phase) }`
  - Update `previousStatus = status` and `status = newStatus`
- Add method `autoCompletePlan(phase: String)`:
  - Guard check: find plan where `plan.slug == phase` and `plan.status == .inProgress`
  - If found, call `viewModel.updatePlanStatus(plan: matchingPlan, status: .done)`
  - Log: `print("[Hieroglyphs] Auto-completed plan: \(phase)")`

**Done when**:
- PharaohView tracks previous status
- Transition from busy to done triggers `autoCompletePlan`
- Matching plan is updated to `done` status
- Console logs auto-completion event

## S010: Surface Pharaoh errors with alert

**Intent**: Show an alert when Pharaoh transitions to blocked status with an error message.

**Work**:
- Open `Sources/Hieroglyphs/Views/Pharaoh/PharaohView.swift`
- Add state: `@State private var showErrorAlert = false`, `@State private var errorMessage = ""`
- In `updateStatus()`, detect `busy → blocked` transition:
  - `if case .busy = previousStatus, case .blocked(_, let error, _, _) = newStatus { errorMessage = error; showErrorAlert = true }`
- Add `.alert("Phase Failed", isPresented: $showErrorAlert) { Button("OK") { } } message: { Text(errorMessage) }` modifier to view body
- Ensure blocked state display includes error text (from enum associated value), cost, and turns

**Done when**:
- PharaohView shows alert on blocked status transition
- Alert displays error message from blocked case
- Alert has title "Phase Failed" and OK button
- Blocked state display continues showing error after alert dismissed

## S011: Add model selection to PharaohView

**Intent**: Allow users to choose the model (opus/sonnet/haiku) when dispatching plans.

**Work**:
- Open `Sources/Hieroglyphs/Views/Pharaoh/PharaohView.swift`
- Add model picker visible when `status.isIdle`:
  - `Picker("Model", selection: Bindable(viewModel).pharaohModel) { Text("Opus").tag("opus"); Text("Sonnet").tag("sonnet"); Text("Haiku").tag("haiku") }.pickerStyle(.segmented)`
- Open `Sources/Hieroglyphs/HieroglyphsVM.swift`
- Verify `pharaohModel` property exists (it should already exist per docs)
- Update `dispatchPlan()` method to use `pharaohModel` in frontmatter instead of hardcoded "opus":
  - Frontmatter: `model: \(pharaohModel)`

**Done when**:
- PharaohView shows model picker when Pharaoh is idle
- Picker binds to `viewModel.pharaohModel`
- `dispatchPlan()` uses selected model in dispatch file frontmatter
- Picker hidden when Pharaoh is busy/done/blocked

## S012: Update PharaohServiceTests for enriched status and events

**Intent**: Verify that updated `readStatus()` and new `readEvents()` methods work correctly.

**Work**:
- Open `Tests/HieroglyphsTests/PharaohServiceTests.swift`
- Update existing status tests to expect new enum shapes:
  - `busy` test: verify `turnsElapsed`, `runningCostUsd`, `phaseStarted` fields
  - `done` test: verify `costUsd` and `turns` fields
  - `blocked` test: verify `error`, `costUsd`, `turns` fields
- Add new test `testReadEvents`:
  - Create temp directory with `.pharaoh/events.jsonl` file
  - Write sample events (toolCall, turn, result) in JSON Lines format
  - Call `service.readEvents(from: tempDir)`
  - Verify returned array has correct count
  - Verify event types, summaries, timestamps parsed correctly
  - Verify malformed lines are skipped gracefully
- Add test `testReadEventsEmptyFile`:
  - Create empty events.jsonl file
  - Verify `readEvents()` returns empty array
- Add test `testReadEventsMissingFile`:
  - Call `readEvents()` on directory without events.jsonl
  - Verify returns empty array (no crash)

**Done when**:
- All existing PharaohServiceTests pass with updated enum shapes
- New tests for `readEvents()` pass
- Tests verify parsing correctness and graceful error handling
- `swift test` completes successfully

## S013: Update documentation

**Intent**: Reconcile docs with the enhanced Pharaoh integration.

**Work**:
- Open `.ushabti/docs/pharaoh-integration.md`
- Update PharaohStatus section to reflect new enum shapes (busy, done, blocked with enriched fields)
- Add section "Event Stream Architecture" describing:
  - `.pharaoh/events.jsonl` format (JSON Lines)
  - Event types (toolCall, toolProgress, toolSummary, text, turn, status, result, error)
  - PharaohEvent model structure
  - PharaohActivityStreamView polling and display
- Update "Process Lifecycle" section to mention auto-completion on done transition
- Add section "Error Surfacing" describing alert behavior on blocked transition
- Add section "Model Selection" describing picker UI and dispatch frontmatter usage
- Open `.ushabti/docs/views-ui.md`
- Add entries for `PharaohActivityStreamView` and `PharaohEventRow`:
  - Location, purpose, structure
  - Polling strategy, auto-scroll behavior
  - Event type rendering with icons and colors

**Done when**:
- pharaoh-integration.md reflects all new features
- views-ui.md includes new views
- Documentation is accurate and complete

## S014: Build verification

**Intent**: Ensure the project builds successfully.

**Work**:
- Run `swift build` from `/Users/adam/Development/hieroglyphs`
- Verify build completes without errors

**Done when**:
- `swift build` exits with status 0
- No compilation errors or warnings
