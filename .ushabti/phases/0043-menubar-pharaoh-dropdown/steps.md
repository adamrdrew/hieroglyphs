# Steps

## S001: Add PharaohMenuBar view

**Intent:** Create the menu bar extra view displaying running plans or empty state.

**Work:**
- Create `Sources/Hieroglyphs/Views/MenuBar/PharaohMenuBar.swift`
- Define `PharaohMenuBar` view with MenuBarExtra using "chart.line.uptrend.xyaxis" SF Symbol
- Access `HieroglyphsVM` via `@Environment`
- Define local `@State var runningPlans: [(project: Project, plan: Plan)] = []`
- Implement `.onAppear` to start polling via `loadRunningPlans()`
- Create `loadRunningPlans()` method:
  - Iterate `viewModel.projects`
  - For each project with non-nil `sourceDirectory`, call `planService.loadPlans(projectPath:)`
  - Filter plans to only `inProgress` status
  - Build array of `(project, plan)` tuples
  - Compare count to current `runningPlans.count` before assigning (polling pattern)
  - Only assign if count differs (prevents unnecessary redraws)
- Add polling timer: `.onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect())` calling `loadRunningPlans()`
- Define MenuBarExtra content:
  - If `runningPlans.isEmpty`: Text("No Devel Jobs Running") with `.foregroundStyle(.secondary)`
  - Else: ForEach over `runningPlans` with PharaohMenuBarEntry view for each plan
- Use `.labelStyle(.titleOnly)` on MenuBarExtra to show only icon

**Done when:** PharaohMenuBar view compiles and displays correct content (empty state or plan list).

## S002: Create PharaohMenuBarEntry row view

**Intent:** Define individual row view for a running plan with navigation action.

**Work:**
- Create `Sources/Hieroglyphs/Views/MenuBar/PharaohMenuBarEntry.swift`
- Define `PharaohMenuBarEntry` view accepting `project: Project`, `plan: Plan`, `onNavigate: () -> Void`
- Access `HieroglyphsVM` via `@Environment`
- Layout:
  - VStack(alignment: .leading, spacing: 4)
  - First line: Text(plan.title) with `.font(.headline)`
  - Second line: Text(project.title) with `.font(.caption)` and `.foregroundStyle(.secondary)`
  - Third line (if plan has stats): Text with turns elapsed and running cost formatted as "$0.4f"
- Extract stats from plan:
  - Read `plan.phasePrompt` to parse stats (or assume ViewModel provides enriched plan data)
  - If stats unavailable, skip third line
- Button action:
  - Call `viewModel.selectSection(.pharaoh(project))`
  - Call `onNavigate()` to dismiss menu
- Use `.buttonStyle(.plain)` to avoid default button styling

**Done when:** PharaohMenuBarEntry compiles and displays project/plan info correctly.

## S003: Integrate PharaohMenuBar into App

**Intent:** Add menu bar extra to the application scene.

**Work:**
- Open `Sources/Hieroglyphs/App.swift`
- Add `MenuBarExtra` scene alongside existing `Window` scene:
  ```swift
  MenuBarExtra {
      PharaohMenuBar()
          .environment(viewModel)
          .environment(\.planService, planService)
  } label: {
      Label("Pharaoh", systemImage: "chart.line.uptrend.xyaxis")
  }
  ```
- Verify MenuBarExtra only shown when `viewModel.workspacePath != nil` (optional: use conditional scene)

**Done when:** Menu bar icon appears when workspace loaded, dropdown shows content.

## S004: Add running plan stats extraction

**Intent:** Extract turn count and running cost from plan or Pharaoh status.

**Work:**
- Determine where running plan stats come from:
  - Option A: Read `.pharaoh/pharaoh.json` for each project (requires PharaohService call)
  - Option B: Store enriched plan metadata (requires Plan model extension)
  - Option C: Read from Pharaoh status in ViewModel (if already available)
- If Option A:
  - Modify `loadRunningPlans()` to call `pharaohService.readStatus(from: sourceDirectory)` for each project with running plan
  - Extract `turnsElapsed` and `runningCostUsd` from `.busy` case
  - Store stats alongside plan in tuple: `(project: Project, plan: Plan, turns: Int?, cost: Double?)`
  - Update PharaohMenuBarEntry to accept and display optional stats
- If Option B or C: implement as appropriate

**Done when:** Running plans display accurate turn count and running cost in menu bar.

## S005: Implement menu dismissal on navigation

**Intent:** Ensure menu bar dropdown dismisses after user clicks a plan entry.

**Work:**
- Review MenuBarExtra dismissal behavior (automatic on macOS when Button clicked)
- If automatic dismissal works, no code changes needed
- If manual dismissal required:
  - Pass `@Environment(\.dismiss)` from MenuBarExtra content to PharaohMenuBarEntry
  - Call `dismiss()` in button action after calling `viewModel.selectSection()`
- Test: Click plan entry → menu dismisses → Pharaoh view shown for correct project

**Done when:** Clicking a plan entry dismisses menu bar dropdown and navigates to Pharaoh view.

## S006: Handle edge cases

**Intent:** Guard against nil projects, missing sourceDirectory, and stale data.

**Work:**
- Add guard in `loadRunningPlans()`:
  - Skip projects with nil `sourceDirectory`
  - Skip if `planService.loadPlans()` throws (log error, continue to next project)
- Add guard in navigation action:
  - Verify project still exists in `viewModel.projects` before calling `selectSection`
  - If project missing, log warning and do nothing
- Add nil check for `planService` in `loadRunningPlans()`
- Test: Delete project while plan running → menu bar updates to exclude that plan

**Done when:** Menu bar handles missing projects and sourceDirectory gracefully without crashes.

## S007: Write tests for menu bar logic

**Intent:** Verify running plan extraction and navigation behavior.

**Work:**
- Create `Tests/HieroglyphsTests/PharaohMenuBarTests.swift` (if testable logic exists)
- Test running plan extraction:
  - Mock projects with plans in various statuses
  - Verify only `inProgress` plans included in running plans list
  - Verify projects without `sourceDirectory` excluded
- Test polling comparison:
  - Call `loadRunningPlans()` twice with same data
  - Verify state assignment only happens once (count comparison logic)
- If views are not testable (SwiftUI limitation), skip view-level tests and focus on ViewModel methods

**Done when:** Tests pass and verify running plan extraction logic.

## S008: Update documentation

**Intent:** Document menu bar integration in relevant docs.

**Work:**
- Update `.ushabti/docs/pharaoh-integration.md`:
  - Add "Menu Bar Dropdown" section under "UI Components"
  - Describe PharaohMenuBar functionality, polling strategy, navigation behavior
  - Document content comparison pattern for preventing unnecessary redraws
- Update `.ushabti/docs/views-ui.md`:
  - Add PharaohMenuBar and PharaohMenuBarEntry to directory structure
  - Document polling timer and state update strategy
- Commit changes

**Done when:** Documentation updated with menu bar integration details.

## S009: Build verification

**Intent:** Ensure the application compiles successfully.

**Work:**
- Run `./Scripts/build-app.sh`
- Fix any compilation errors
- Verify menu bar icon appears and dropdown shows correct content

**Done when:** Build exits 0 and menu bar dropdown functions correctly.
