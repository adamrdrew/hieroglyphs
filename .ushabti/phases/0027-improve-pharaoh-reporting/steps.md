# Steps

## S001: Create PharaohServerInfo model

**Intent:** Define a structured model representing server metadata from pharaoh.json.

**Work:**
- Create `Sources/Hieroglyphs/Models/PharaohServerInfo.swift`
- Define struct with properties: `status`, `pid`, `started`, `pharaohVersion`, `ushabtiVersion`, `model`, `cwd`, `phasesCompleted`
- Add static parse method `parse(json: [String: Any]) -> PharaohServerInfo?` that extracts fields from dictionary
- Use ISO8601DateFormatter for `started` timestamp parsing
- Handle missing/malformed fields gracefully (return nil on parse failure)

**Done when:** PharaohServerInfo.swift exists with parse method that returns nil for malformed input and populated struct for valid input.

## S002: Extend PharaohProviding protocol with readServerInfo method

**Intent:** Add server metadata reading to the protocol contract.

**Work:**
- Open `Sources/Hieroglyphs/Services/PharaohProviding.swift`
- Add method signature: `func readServerInfo(from directory: String) -> PharaohServerInfo?`
- Add documentation comment explaining return value (nil if file missing or malformed)

**Done when:** PharaohProviding protocol declares readServerInfo method.

## S003: Implement readServerInfo in PharaohService

**Intent:** Parse pharaoh.json and return server metadata.

**Work:**
- Open `Sources/Hieroglyphs/Services/PharaohService.swift`
- Add `readServerInfo(from directory: String) -> PharaohServerInfo?` method
- Read from `{directory}/.pharaoh/pharaoh.json`
- Use JSONSerialization to parse JSON object
- Call `PharaohServerInfo.parse(json:)` to construct model
- Return nil if file missing, read fails, or parse fails

**Done when:** PharaohService.readServerInfo returns structured metadata when pharaoh.json is valid, nil otherwise.

## S004: Add typed detail properties to PharaohEvent

**Intent:** Expose structured detail data as computed properties on PharaohEvent.

**Work:**
- Open `Sources/Hieroglyphs/Models/PharaohEvent.swift`
- Add computed properties:
  - `var toolName: String?` — Extract from detail.tool_name for tool_call events
  - `var toolInput: String?` — Extract from detail.input for tool_call events
  - `var turnNumber: Int?` — Extract from detail.turn for turn events
  - `var inputTokens: Int?` — Extract from detail.input_tokens for turn events
  - `var outputTokens: Int?` — Extract from detail.output_tokens for turn events
  - `var fullText: String?` — Extract from detail.full_text for text events
  - `var resultTurns: Int?` — Extract from detail.turns for result events
  - `var resultCostUsd: Double?` — Extract from detail.cost_usd for result events
- Each property parses detailJson using JSONSerialization and extracts the relevant field
- Return nil if detailJson is nil, parse fails, or field is missing

**Done when:** PharaohEvent has 8 computed properties returning typed detail fields, all returning nil gracefully on missing/malformed data.

## S005: Add hasDetail computed property to PharaohEvent

**Intent:** Provide a simple way to check if an event has detail data.

**Work:**
- Open `Sources/Hieroglyphs/Models/PharaohEvent.swift`
- Add `var hasDetail: Bool { detailJson != nil }`

**Done when:** PharaohEvent.hasDetail returns true if detailJson is non-nil.

## S006: Create PharaohEventDetailView component

**Intent:** Render event detail data in an expandable disclosure group.

**Work:**
- Create `Sources/Hieroglyphs/Views/Pharaoh/PharaohEventDetailView.swift`
- Accept `PharaohEvent` as parameter
- Use DisclosureGroup with "Details" label
- Inside disclosure, use VStack with detail rows based on event type:
  - For tool_call: show tool name, tool input (truncated or scrollable)
  - For turn: show turn number, input tokens, output tokens
  - For text: show full text (if different from summary)
  - For result: show total turns, total cost
- Use compact monospaced font for technical data
- Handle nil detail fields gracefully (don't render row if nil)

**Done when:** PharaohEventDetailView displays structured detail in a collapsible section.

## S007: Integrate PharaohEventDetailView into PharaohEventRow

**Intent:** Add expandable detail section to event rows when detail is available.

**Work:**
- Open `Sources/Hieroglyphs/Views/Pharaoh/PharaohEventRow.swift`
- Update eventRow to include PharaohEventDetailView below summary when `event.hasDetail` is true
- Wrap in VStack with alignment: .leading
- Keep existing summary row unchanged

**Done when:** Event rows show detail disclosure when detail data is present.

## S008: Add server info display to PharaohView

**Intent:** Show server metadata when Pharaoh is running.

**Work:**
- Open `Sources/Hieroglyphs/Views/Pharaoh/PharaohView.swift`
- Add @State property: `serverInfo: PharaohServerInfo? = nil`
- In `updateStatus()`, call `pharaohService.readServerInfo(from:)` and assign to serverInfo
- Add server info section to `runningStateView` above status section:
  - Show version info (pharaohVersion, ushabtiVersion)
  - Show model
  - Show cwd (truncated if long)
  - Show PID
  - Show started timestamp with relative time
  - Show phasesCompleted count
- Use secondary text styling for labels, medium weight for values
- Only render section if serverInfo is non-nil

**Done when:** PharaohView displays server metadata section when running and pharaoh.json exists.

## S009: Write tests for PharaohServerInfo parsing

**Intent:** Verify server metadata parsing handles valid and invalid input.

**Work:**
- Open `Tests/HieroglyphsTests/PharaohServiceTests.swift`
- Add test: `testReadServerInfo_validJSON` — Creates pharaoh.json with all fields, verifies parsed values match
- Add test: `testReadServerInfo_missingFile` — Returns nil when pharaoh.json missing
- Add test: `testReadServerInfo_malformedJSON` — Returns nil when JSON is invalid
- Add test: `testReadServerInfo_missingFields` — Returns nil when required fields are missing

**Done when:** Four new tests pass, covering happy path and error cases for server info parsing.

## S010: Write tests for PharaohEvent detail properties

**Intent:** Verify event detail parsing extracts typed fields correctly.

**Work:**
- Open `Tests/HieroglyphsTests/PharaohServiceTests.swift` (or create PharaohEventTests.swift if preferred)
- Add test: `testEventDetailParsing_toolCall` — Create event with tool_call detail, verify toolName and toolInput extracted
- Add test: `testEventDetailParsing_turn` — Create event with turn detail, verify turnNumber, inputTokens, outputTokens extracted
- Add test: `testEventDetailParsing_text` — Create event with text detail, verify fullText extracted
- Add test: `testEventDetailParsing_result` — Create event with result detail, verify resultTurns and resultCostUsd extracted
- Add test: `testEventDetailParsing_malformed` — Create event with invalid detailJson, verify all detail properties return nil
- Add test: `testHasDetail` — Verify hasDetail returns true when detailJson present, false when nil

**Done when:** Six new tests pass, covering all detail property types and error handling.

## S011: Reconcile pharaoh-integration.md documentation

**Intent:** Update documentation to reflect new server info and event detail capabilities.

**Work:**
- Open `.ushabti/docs/pharaoh-integration.md`
- Add section under "Architecture Components" > "Models" describing PharaohServerInfo
- Update PharaohEvent section to document new detail properties (toolName, toolInput, turnNumber, etc.)
- Add section under "UI Components" describing PharaohEventDetailView
- Update PharaohView section to describe server info display
- Update "Future Enhancements" if any planned features now implemented

**Done when:** Documentation accurately describes new server info model, event detail properties, and updated UI components.

## S012: Run tests and verify build

**Intent:** Ensure all tests pass and project builds cleanly.

**Work:**
- Run `swift test` from project root
- Verify no test failures
- Run `swift build`
- Verify no compilation errors

**Done when:** `swift test` and `swift build` both succeed with no errors.
