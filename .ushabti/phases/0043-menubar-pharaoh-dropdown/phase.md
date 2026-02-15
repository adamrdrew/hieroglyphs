# Phase 0043: Menu Bar Pharaoh Dropdown

## Intent

Add a menu bar dropdown that displays running Pharaoh plans (plans with `inProgress` status) across all projects. When no plans are running, display "No Devel Jobs Running." Clicking a plan entry dismisses the dropdown and navigates to that plan's project Pharaoh view.

## Scope

**In scope:**
- MenuBarExtra with conditional content (running plans list or empty state message)
- Poll all projects for plans with `inProgress` status
- Display project name, plan name, and basic stats (turns elapsed, cost) for each running plan
- Click action to navigate to Pharaoh view for the plan's project
- Automatic dismissal after navigation
- Polling strategy to keep running plans list current

**Out of scope:**
- Plan control actions (stop, pause, restart) from menu bar
- Detailed event stream in menu bar
- Multiple Pharaoh instances per project (assumes one Pharaoh process across all projects)
- Menu bar icon animation or status indicator beyond standard MenuBarExtra

## Constraints

- **L09**: Protocol-based services, small focused methods
- **L17**: UI State Correctness — view must update when plan status changes
- **L18**: Design Is How It Works — native macOS appearance, system colors, SF Symbols
- **Style: Polling and Live Data** — compare content before assigning state, only update when changed
- **Style: Visual Design** — system semantic colors, SF Symbols, hierarchical rendering
- **macOS 26 Liquid Glass** — MenuBarExtra receives automatic glass treatment, do not override

## Acceptance Criteria

1. Menu bar shows "Pharaoh" icon with dropdown (visible when workspace loaded)
2. Dropdown lists all running plans (any project, `inProgress` status) with project name, plan name, turns elapsed, running cost
3. When no plans running, dropdown shows "No Devel Jobs Running" message
4. Clicking a plan entry dismisses dropdown and navigates to that project's Pharaoh view (updates `selectedSection` to `.pharaoh(project)`)
5. Running plans list updates automatically (polling every 2-5 seconds)
6. Content comparison prevents unnecessary redraws (only assign state when running plans change)
7. Uses system semantic colors and SF Symbols
8. MenuBarExtra uses default styling (no custom glass or materials)

## Risks / Notes

- Polling all projects for running plans may be inefficient with many projects (acceptable for MVP, can optimize later)
- Navigation to Pharaoh view assumes project selection is valid (guard against nil projects)
- Menu bar extra is macOS-specific (already covered by L07)
- Single Pharaoh instance assumption means at most one plan can be `inProgress` at a time (current architecture, may change in future)
