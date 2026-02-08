# Phases View (Ushabti Integration)

## Overview

The Phases view integrates Hieroglyphs with the Ushabti phase-based development workflow. When a project has a `sourceDirectory` configured, users can select the "Phases" section in the sidebar to view all phases from the project's `.ushabti/phases/` directory. This enables developers to view phase-based development progress directly within Hieroglyphs without leaving the app.

This is a **read-only** integration. Phases are managed by Ushabti agents (Scribe, Builder, Overseer) outside of Hieroglyphs, and the app only displays their current state.

## Architecture

### Models

**Phase** (`Sources/Hieroglyphs/Models/Phase.swift`)
- `number: Int` — Phase number extracted from directory name
- `slug: String` — Directory name (e.g., "0012-fix-typing-lag")
- `title: String` — Phase title from progress.yaml
- `status: PhaseStatus` — Current phase status
- `intent: String` — Intent section from phase.md
- `steps: [PhaseStep]` — Array of implementation steps
- `reviewNotes: String` — Full content of review.md (empty if not yet reviewed)

**PhaseStatus** (`Sources/Hieroglyphs/Models/PhaseStatus.swift`)
- Enum with cases: `planned`, `active`, `green`, `yellow`, `red`
- Raw values match status strings in progress.yaml

**PhaseStep** (`Sources/Hieroglyphs/Models/PhaseStep.swift`)
- `id: String` — Step identifier (e.g., "S001")
- `summary: String` — Step title
- `implemented: Bool` — Builder completion flag
- `reviewed: Bool` — Overseer review flag

All models conform to `Codable`, `Equatable`, `Identifiable`, and `Hashable`.

### Service Layer

**PhaseProviding Protocol** (`Sources/Hieroglyphs/Services/PhaseProviding.swift`)
- Defines contract: `func loadPhases(from sourceDirectory: String) throws -> [Phase]`
- Implementations read phase data from disk on demand
- Read-only protocol (no write methods)

**PhaseService** (`Sources/Hieroglyphs/Services/PhaseService.swift`)
- Concrete implementation of `PhaseProviding`
- Discovers phase directories matching pattern `NNNN-slug` in `.ushabti/phases/`
- Parses `progress.yaml` using Yams library for title, status, steps
- Extracts intent from phase.md `## Intent` section
- Reads review.md content when present (gracefully handles missing file)
- Returns phases sorted by number ascending
- Handles errors gracefully (logs warnings, skips malformed phases)

**Environment Key** (`Sources/Hieroglyphs/Services/PhaseServiceEnvironmentKey.swift`)
- SwiftUI environment key for dependency injection
- Optional `PhaseProviding?` type

### ViewModel Integration

**HieroglyphsVM** (`Sources/Hieroglyphs/HieroglyphsVM.swift`)
- `phases: [Phase]` — Current phase list
- `selectedPhase: Phase?` — Currently selected phase
- `loadPhases()` — Loads phases from selected project's sourceDirectory
  - Guards on selectedProject and sourceDirectory
  - Calls phaseService.loadPhases(from:)
  - Updates self.phases on success
  - Logs errors on failure

### View Layer

**PhaseList** (`Sources/Hieroglyphs/Views/PhaseList/PhaseList.swift`)
- Middle-column view when Phases section selected
- Three states:
  - No sourceDirectory: Shows "Configure a source directory" message
  - No phases: Shows "No Ushabti phases found" message
  - Phases exist: List with selection binding to viewModel.selectedPhase
- Automatically loads phases when selectedProject changes

**PhaseListEntry** (`Sources/Hieroglyphs/Views/PhaseList/PhaseListEntry.swift`)
- Individual phase row
- Shows phase number, title, status icon with color
- Status icons:
  - Planned: gray circle
  - Active: blue filled circle
  - Green: green checkmark
  - Yellow: yellow warning triangle
  - Red: red X mark

**PhaseDetail** (`Sources/Hieroglyphs/Views/PhaseDetail/PhaseDetail.swift`)
- Detail-column view for selected phase
- Shows empty state if no phase selected
- Sections:
  - Header: title, status badge, phase number
  - Intent: Rendered markdown from phase.md
  - Steps: Checklist with completion indicators (implemented/reviewed)
  - Review: Rendered markdown from review.md (hidden if empty)
- Uses MarkdownUI for rendering intent and review notes

**MainWindow Integration** (`Sources/Hieroglyphs/Views/MainWindow.swift`)
- `.phases` case shows PhaseList in middle column
- Detail column shows PhaseDetail when selectedPhase is non-nil
- Falls back to CardDetail when selectedPhase is nil

## File Discovery and Parsing

### Directory Pattern

PhaseService scans `{sourceDirectory}/.ushabti/phases/` for directories matching the pattern `NNNN-slug`, where:
- `NNNN` is a zero-padded phase number (e.g., "0001", "0042")
- `slug` is a descriptive identifier with hyphens

Examples:
- `0001-initial-setup`
- `0012-fix-typing-lag`
- `0017-phases-view`

### Parsing Process

1. **Directory discovery:** FileManager.contentsOfDirectory scans phases/ folder
2. **Number extraction:** Split directory name on "-", parse first component as Int
3. **progress.yaml parsing:**
   - Read file with String(contentsOfFile:encoding:)
   - Parse YAML with Yams.load()
   - Extract phase.title, phase.status from YAML dictionary
   - Parse steps array into PhaseStep models
4. **Intent extraction:**
   - Read phase.md
   - Locate "## Intent" section
   - Extract text until next "##" heading
5. **Review notes extraction:**
   - Read review.md if exists
   - Use full content as reviewNotes
   - Empty string if file missing
6. **Phase construction:** Build Phase model with all parsed data
7. **Sorting:** Sort phases by number ascending

### Error Handling

- Missing .ushabti/phases/ directory: Returns empty array
- Invalid directory name (no hyphen or non-numeric prefix): Logs warning, skips
- Missing progress.yaml: Logs warning, skips phase
- Invalid YAML syntax: Logs warning, skips phase
- Missing phase.md: Returns empty intent string
- Missing review.md: Returns empty reviewNotes string

No crashes or exceptions propagated to caller. Service does its best to parse what it can.

## Testing

### PhaseService Tests (`Tests/HieroglyphsTests/PhaseServiceTests.swift`)

13 test cases covering:
- Empty results for non-existent directory
- Empty results when no phases exist
- Single phase discovery and parsing
- Multiple phase discovery
- Sorting by number ascending
- Directory name parsing
- Intent extraction from phase.md
- Review notes extraction from review.md
- Missing review.md handling
- Steps parsing from progress.yaml
- All PhaseStatus values
- Skipping malformed directories
- Skipping phases with missing progress.yaml

Uses temporary directories and controlled fixtures for deterministic testing.

### ViewModel Tests (`Tests/HieroglyphsTests/HieroglyphsVMTests.swift`)

4 test cases covering:
- loadPhases with valid sourceDirectory updates state
- loadPhases with nil sourceDirectory does nothing
- loadPhases with no selected project does nothing
- loadPhases with service error logs and sets phases empty

Uses MockPhaseService for controlled test scenarios.

All tests pass. Total test count: 178.

## Limitations and Future Enhancements

### Current Limitations

1. **Read-only:** Cannot create, edit, or delete phases from UI (intentional to preserve Ushabti workflow integrity)
2. **No file watching:** Phase files live outside workspace, so FileWatcherService doesn't monitor them. Users must re-select Phases section to refresh.
3. **No search/filter:** All phases shown without filtering by status or text search
4. **No Plans view integration:** Plans view (future Phase 0018) is separate

### Future Enhancements

- File watching for phase directories (requires second FSEvents monitor)
- Filter/search phases by status, title, or step content
- Jump to step implementation in source files (requires sourceDirectory file navigation)
- Phase creation wizard (separate phase, requires careful Ushabti integration)
- Integration with Plans view for full Ushabti context

## Laws and Style Compliance

**Laws:**
- **L01 (Filesystem as Source of Truth):** Reads phase data from disk on demand, no caching
- **L09 (Sandi Metz Principles):** Protocol-based service, plain data models, small methods
- **L10 (TakeNote Design Consistency):** Three-column layout, SF Symbols, consistent spacing
- **L11 (Test Coverage):** All public methods tested

**Style:**
- PhaseService separate from WorkspaceService (single responsibility)
- Read-only service (no write methods)
- No regex (string methods for directory name parsing)
- Small, focused views following existing patterns
- Graceful error handling (log and skip, never crash)

## Integration Points

### With ViewModel
- HieroglyphsVM holds phase state and selected phase
- loadPhases() method called when selectedProject changes
- PhaseService injected via init parameter

### With Navigation
- Sidebar shows "Phases" section for each project
- Selecting .phases(project) loads PhaseList
- Selecting phase in list shows PhaseDetail

### With Environment
- PhaseService injected at App level via .environment(\.phaseService, ...)
- Available to all views via @Environment(\.phaseService)

## Usage

1. Open/create a project in Hieroglyphs
2. Edit project metadata to set `sourceDirectory` to a path containing `.ushabti/phases/`
3. Select "Phases" section in sidebar for that project
4. Phase list appears in middle column
5. Select a phase to view details (intent, steps, review notes)

## Related Documentation

- [ViewModel Layer](viewmodel.md) — State management and service coordination
- [View Layer and UI](views-ui.md) — NavigationSplitView patterns
- [Workspace Service](workspace-service.md) — Similar protocol-based service pattern
- [Testing Strategy](testing.md) — Test organization and coverage
