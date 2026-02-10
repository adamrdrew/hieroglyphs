# Phase 0025: Improved Pharaoh Integration

## Intent

Transform the Pharaoh integration from a basic status viewer into a rich observability dashboard with a two-pane layout, real-time event stream, automatic plan lifecycle management, error surfacing, and model selection. This enhances the development workflow by providing detailed visibility into agent execution and automating plan status transitions.

The current Pharaoh integration (introduced in a prior phase) provides basic functionality: start/stop controls, status polling, and log viewing. This phase extends it with five focused enhancements that address gaps in observability, usability, and automation.

## Scope

### In Scope

1. **Two-pane layout**: Refactor PharaohView to be a status-focused panel in the content column, with a new PharaohActivityStreamView in the detail column showing real-time agent events
2. **Enriched status model**: Update PharaohStatus enum to include `turnsElapsed`, `runningCostUsd`, and `phaseStarted` for busy state, and `costUsd`/`turns` for done/blocked states
3. **Real-time event stream**: Parse `.pharaoh/events.jsonl` and display structured agent events (tool calls, progress, turns, results, errors) with timestamp, icon, and formatting
4. **Automatic plan completion**: Detect done status transition and auto-complete the matching plan via `updatePlanStatus(plan:status:.done)`
5. **Error surfacing**: Detect blocked status transition and show alert with error message
6. **Model selection**: Add model picker (opus/sonnet/haiku) to PharaohView and update `dispatchPlan()` to use selected model instead of hardcoded "opus"

### Out of Scope

- Changes to Pharaoh server (npm package `@adamrdrew/pharaoh`)
- Changes to Ushabti agents or framework
- Multi-project Pharaoh support (remains single-process)
- Plan dispatch queue or history
- Cost tracking and budget management
- Custom Pharaoh arguments or configuration UI
- Modifications to files outside `/Users/adam/Development/hieroglyphs/Sources/Hieroglyphs/`

## Constraints

**Laws:**
- L01 (Filesystem as Source of Truth): All state derived from `.pharaoh/pharaoh.json` and `.pharaoh/events.jsonl`
- L02 (Preserve Unknown Fields): Not applicable (JSON files, not frontmatter)
- L03 (No Xcode Project): Build verification with `swift build`
- L09 (Sandi Metz Principles): Small focused views, protocol-based services, dependency injection
- L10 (Design Consistency with TakeNote): SF Symbols for all icons, NavigationSplitView pattern, consistent spacing
- L11 (Test Coverage): All public PharaohService methods tested (existing tests updated, new `readEvents` method tested)

**Style:**
- Small classes and methods (100 lines / 5 lines guidelines)
- SOLID principles: single responsibility, dependency inversion
- No regex (use String methods and JSON parsing)
- Clarity over brevity in naming
- Protocol-based services with environment injection

**Existing Patterns:**
- PharaohService already conforms to PharaohProviding protocol
- ViewModel already has `pharaohModel` property (String, defaults to "opus")
- MainWindow already routes `.pharaoh(project)` to PharaohView in content column, detail column currently shows `Text("")`
- Status polling already implemented (every 2 seconds via `monitorStatus()`)
- File format reference in docs: `.pharaoh/pharaoh.json` has `turnsElapsed`, `runningCostUsd`, `costUsd` fields when busy/done/blocked

## Acceptance Criteria

1. **PharaohStatus enum updated**: Busy case includes `turnsElapsed: Int`, `runningCostUsd: Double`, `phaseStarted: Date?`. Done and blocked cases include `costUsd: Double` and `turns: Int`. Computed properties (`isRunning`, `isBusy`, `isIdle`) updated to match new shapes.

2. **PharaohService.readStatus() enhanced**: Parses new JSON fields (`turnsElapsed`, `runningCostUsd`, `phaseStarted` as ISO8601 string, `costUsd`, `turns`) and constructs updated enum cases with all associated values.

3. **PharaohView refactored**: Log viewer section removed. Busy state displays turns elapsed, running cost formatted as currency, and live elapsed time (using `Text(phaseStarted, style: .relative)` if available). Done and blocked states display final cost and turns. Model picker (segmented) visible when idle, binds to `viewModel.pharaohModel`.

4. **PharaohEvent model created**: Struct with `id: UUID`, `timestamp: Date`, `type: PharaohEventType` (enum with cases: `toolCall`, `toolProgress`, `toolSummary`, `text`, `turn`, `status`, `result`, `error`), `summary: String`, `detailJson: String?`. Static `parse(line:)` method decodes JSON Lines format using `JSONSerialization`.

5. **PharaohService.readEvents() implemented**: Method signature `func readEvents(from directory: String) -> [PharaohEvent]`. Reads `.pharaoh/events.jsonl`, splits on newline, compactMaps `PharaohEvent.parse(line:)`. Added to `PharaohProviding` protocol.

6. **PharaohEventRow created**: View displays event with relative timestamp (`Text(event.timestamp, style: .relative)`), type icon (SF Symbol), icon color, and summary text. Icons and colors match event types (wrench for tool calls, checkmark for success, exclamationmark.triangle for errors, etc.). Turn events render as subtle separator with "Turn N" label.

7. **PharaohActivityStreamView created**: View with `ScrollViewReader` wrapping `LazyVStack` inside `ScrollView`. Polls events every 2 seconds via async task. Auto-scrolls to bottom anchor on each update if `autoScroll` is true. Empty state shows `ContentUnavailableView` with "No Events" message. Navigation title "Activity".

8. **MainWindow detail column wired**: Case `.pharaoh(let project)` shows `PharaohActivityStreamView(project: project)` instead of `Text("")`.

9. **Auto-complete plan on success**: PharaohView tracks `previousStatus` in `@State`. On status update, if transition is `busy → done`, calls `autoCompletePlan(phase:)` which finds matching plan by slug (where `plan.slug == phase` and `plan.status == .inProgress`), then calls `viewModel.updatePlanStatus(plan:status:.done)`. Logs completion to console.

10. **Error surfacing**: PharaohView has `@State` for `showErrorAlert: Bool` and `errorMessage: String`. On `busy → blocked` transition, sets `errorMessage` from blocked error string and shows alert. Alert has title "Phase Failed", message displays error, single OK button.

11. **Model selection**: `viewModel.pharaohModel` used in `dispatchPlan()` frontmatter instead of hardcoded "opus". Model picker in PharaohView offers "Opus", "Sonnet", "Haiku" tags, visible only when `status.isIdle`. Uses segmented picker style.

12. **Tests updated**: PharaohServiceTests includes test for `readEvents(from:)` with mock `.pharaoh/events.jsonl` file. Verifies event parsing, timestamp decoding, type mapping, and detail JSON extraction. All existing tests pass. `swift test` completes successfully.

13. **Build verification**: `swift build` from `/Users/adam/Development/hieroglyphs` completes without errors.

14. **Docs reconciled**: `.ushabti/docs/pharaoh-integration.md` updated to reflect new PharaohStatus shape, event stream architecture, auto-completion flow, error surfacing, and model selection. `.ushabti/docs/views-ui.md` updated with PharaohActivityStreamView and PharaohEventRow descriptions.

## Risks / Notes

**Efficient event polling**: To avoid re-parsing the entire events file on every poll, the implementation should track file size via `FileManager.default.attributesOfItem(atPath:)` and only re-parse if size changed. This optimization is mentioned in the phase prompt and should be implemented.

**JSON parsing resilience**: `PharaohEvent.parse(line:)` should return `nil` for malformed lines rather than crashing. Event stream should gracefully skip unparseable events and continue rendering valid events.

**Detail JSON as String**: The `detailJson` field stores raw JSON as a String rather than decoding into typed structs. This is intentional — the detail object structure varies by event type, and storing raw JSON simplifies the model. Future enhancement could add a `DisclosureGroup` in `PharaohEventRow` to display formatted detail JSON.

**Turn event rendering**: Turn events should render as subtle separators (thin `Divider()` with small muted "Turn N" label), not full rows, to reduce visual clutter in the event stream.

**Auto-completion timing**: Auto-completion triggers immediately on `done` status detection. If the user manually set the plan to `done` before Pharaoh finished, no harm — `updatePlanStatus` is idempotent. If the plan was deleted, the `guard` check in `autoCompletePlan` prevents errors.

**Error alert non-blocking**: The alert for blocked status is informational only. The user clicks OK to dismiss. The blocked state display in PharaohView continues showing the error message, so the information is not lost after dismissing the alert.

**Model picker visibility**: The model picker only appears when Pharaoh is idle. This prevents changing the model mid-execution, which would have no effect (the model is set at dispatch time in the frontmatter).

**Selection preservation**: No changes to plan or phase selection preservation logic. Those patterns remain unchanged.

**File paths**: All file modifications are within `/Users/adam/Development/hieroglyphs/Sources/Hieroglyphs/`. No changes to package structure, build scripts, or resources.
