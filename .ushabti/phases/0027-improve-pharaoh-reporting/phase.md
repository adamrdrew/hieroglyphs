# Phase 0027: Improve Pharaoh Reporting

## Intent

Improve the completeness and usefulness of Pharaoh monitoring by rendering rich event detail data and displaying server metadata. Currently, the event stream only shows summary text, hiding valuable structured information in the detail field. Additionally, server metadata from pharaoh.json is not displayed anywhere, leaving users without visibility into Pharaoh's configuration and session statistics.

This Phase extends the event model to expose detail fields as typed properties, creates detail views for different event types, adds a server metadata model and display, and updates tests and documentation accordingly.

## Scope

**In scope:**
- Extend `PharaohEvent` to parse detail JSON into typed properties (tool name/input, turn metrics, full text, result metrics)
- Add detail row components for tool_call, turn, text, and result event types
- Create `PharaohServerInfo` model representing pharaoh.json structure
- Extend `PharaohProviding` protocol with `readServerInfo(from:)` method
- Update `PharaohService` to parse pharaoh.json server metadata
- Display server metadata in `PharaohView` (version, model, cwd, PID, started timestamp, phases completed)
- Add expandable detail disclosure in `PharaohEventRow` for events with detail data
- Update tests for detail parsing and server info reading
- Reconcile pharaoh-integration.md documentation

**Out of scope:**
- Changing polling frequency or file watching behavior
- Adding search, filtering, or export features to event stream
- Persisting server info or events beyond filesystem
- Major UI layout changes to PharaohView or activity stream

## Constraints

- **L09** — Protocol-based services, small focused methods, composition over inheritance
- **L11** — Test coverage for all public methods, tests must pass
- **L13-L16** — Consult and reconcile `.ushabti/docs/pharaoh-integration.md`
- **Style** — No regex, readability over cleverness, explicit over clever

## Acceptance Criteria

- [ ] `PharaohEvent` exposes typed detail properties: `toolName`, `toolInput`, `turnNumber`, `inputTokens`, `outputTokens`, `fullText`, `resultTurns`, `resultCostUsd`
- [ ] Event detail parsing handles missing/malformed detail gracefully (returns nil)
- [ ] `PharaohEventRow` shows expandable detail section when detail data is available
- [ ] `PharaohServerInfo` model with properties: `status`, `pid`, `started`, `pharaohVersion`, `ushabtiVersion`, `model`, `cwd`, `phasesCompleted`
- [ ] `PharaohProviding` protocol includes `readServerInfo(from:) -> PharaohServerInfo?`
- [ ] `PharaohService.readServerInfo(from:)` parses pharaoh.json and returns structured metadata
- [ ] `PharaohView` displays server info section when Pharaoh is running and pharaoh.json exists
- [ ] All tests pass (including new tests for detail parsing and server info reading)
- [ ] Documentation reconciled with implementation

## Risks / Notes

**Detail Parsing Fragility:** Event detail structure is controlled by Pharaoh (external). Parser must handle missing fields gracefully to avoid breaking on schema changes.

**Server Info Availability:** pharaoh.json only exists when Pharaoh is running. UI must handle both present and absent cases cleanly.

**Token Count Display:** Turn events include token counts which could be useful for cost awareness but may clutter the UI. We'll include them but keep the display compact.
