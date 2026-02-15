# Phase 0039: Project Overview

## Intent

Add a Project Overview view shown when the user clicks a project's folder row in the sidebar. The overview displays project configuration (editable) in the middle column and README.md content (read-only) in the detail column.

This phase introduces build/run/publish command configuration stored in project frontmatter, toolbar buttons for executing commands, and a modal UI for command execution with progress/output/result feedback.

## Scope

**In scope:**
- New `SidebarSection.overview(Project)` enum case
- `ProjectOverview` view (middle column) with editable configuration form
- `ProjectReadme` view (detail column) with markdown rendering
- Extend `Project` model with `buildCommand`, `runCommand`, `publishCommand` optional String fields
- Update `WorkspaceService` to persist new command fields (round-trip with L02 compliance)
- `CommandExecutionService` for running commands via `Foundation.Process`
- Command execution modal with progress indication, output display, and success/error feedback
- Git branch detection via `.git/HEAD` parsing
- Progressive disclosure: hide/disable command buttons when no `source_directory`
- Toolbar buttons for Build/Run/Publish (shown only when commands configured)

**Out of scope:**
- Complex command configuration (environment variables, arguments beyond command string)
- Command history or persistent logs
- Multi-step command sequences or pipelines
- Full git integration beyond branch name display
- Build artifact management or output file handling

## Constraints

- **L02:** Preserve unknown frontmatter fields when reading/writing project files
- **L09:** Protocol-based service for command execution, plain Project model with no logic
- **L10:** Follow TakeNote patterns for form layout and markdown rendering
- **L11:** Test coverage for all public service methods
- **L17:** Modal constrained dimensions, async feedback, views reset on project change
- **L18:** Disabled states, loading states, error surfaces, macOS 26 Liquid Glass, progressive disclosure

## Acceptance Criteria

1. Clicking project folder row in sidebar selects `.overview(Project)` section
2. `ProjectOverview` displays editable project fields (title, description, tags, source directory, commands)
3. `ProjectReadme` renders README.md from source directory (or empty state if not found)
4. `Project` model includes `buildCommand`, `runCommand`, `publishCommand` optional String properties
5. `WorkspaceService.updateProject()` and `createProject()` persist command fields
6. Toolbar shows Build/Run/Publish buttons only when corresponding commands are configured
7. Command execution modal shows progress indicator while running
8. Success shows green checkmark with "Build Complete" message
9. Failure shows red indicator with error message and output
10. Git branch name displayed in ProjectOverview when `.git/HEAD` exists in source directory
11. All tests pass

## Risks / Notes

- Command execution uses `Foundation.Process` which requires `source_directory` to be set and accessible
- Git branch detection assumes standard `.git/HEAD` format (`ref: refs/heads/{branch}`)
- README rendering assumes markdown format (no HTML or other formats supported)
- Command output may be large — consider output size limits or scrolling strategy
- Command execution is blocking on UI thread via modal — ensure timeout handling
