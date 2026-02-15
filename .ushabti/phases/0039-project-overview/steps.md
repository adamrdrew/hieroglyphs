# Steps

## S001: Extend Project model with command fields

**Intent:** Add buildCommand, runCommand, publishCommand optional String properties to Project model.

**Work:**
- Open `Sources/Hieroglyphs/Models/Project.swift`
- Add three optional String properties: `buildCommand`, `runCommand`, `publishCommand`
- Update `Codable` conformance if needed (should work automatically)
- Update example frontmatter in models.md documentation

**Done when:**
- Project model compiles with new properties
- Properties are optional (default to nil)
- No breaking changes to existing Project initialization

## S002: Update WorkspaceService to persist command fields

**Intent:** Modify WorkspaceService to read and write command fields in project frontmatter.

**Work:**
- Update `createProject()` to write `buildCommand`, `runCommand`, `publishCommand` to frontmatter (only when non-nil)
- Update `updateProject()` to write/remove command fields (write when non-nil, remove when nil)
- Update `loadProjects()` to read command fields from frontmatter (optional, default to nil)
- Add tests for command field round-trip (create, read, update)
- Test unknown field preservation with command fields present

**Done when:**
- `createProject()` writes command fields to frontmatter when provided
- `updateProject()` writes command fields when non-nil, removes when nil
- `loadProjects()` reads command fields correctly
- Round-trip tests pass
- Unknown fields preserved when command fields added/changed

## S003: Add SidebarSection.overview case and wire in Sidebar

**Intent:** Add new overview section to sidebar enum and update Sidebar view to show overview item.

**Work:**
- Add `case overview(Project)` to `SidebarSection` enum
- Update Sidebar view to include overview row as first child in project DisclosureGroup
- Use "folder.badge.gearshape" SF Symbol for overview icon
- Ensure `.tag(SidebarSection.overview(project))` applied
- Update `selectedProject` computed property if needed (should work automatically)

**Done when:**
- Overview row appears in sidebar under each project
- Clicking overview row sets `selectedSection` to `.overview(project)`
- SF Symbol icon renders correctly
- No visual regressions in sidebar layout

## S004: Update MainWindow middle/detail routing

**Intent:** Add overview routing to MainWindow's middle and detail column switch statements.

**Work:**
- Add `case .overview(let project):` to `middleColumnContent` switch in MainWindow
- Return `ProjectOverview(project: project)` for middle column
- Add `case .overview(let project):` to `detailColumnContent` switch
- Return `ProjectReadme(project: project)` for detail column
- Ensure `.id(viewModel.selectedProject?.id)` modifiers preserve view reset behavior

**Done when:**
- Selecting overview section shows ProjectOverview in middle column
- Selecting overview section shows ProjectReadme in detail column
- Views reset when project changes (verified manually)
- No compilation errors

## S005: Create ProjectOverview view

**Intent:** Build middle-column form view for editing project configuration.

**Work:**
- Create `Sources/Hieroglyphs/Views/ProjectOverview/ProjectOverview.swift`
- Form with sections: Project Details, Source Directory, Build Commands, Git Info
- Project Details: title, description, tags (editable via bindings to viewModel)
- Source Directory: display path, Select Folder button, Clear button
- Build Commands: three TextFields for buildCommand, runCommand, publishCommand
- Git Info: read `.git/HEAD` on appear, display current branch name (if exists)
- Parse git branch via string operations (no regex): check for "ref: refs/heads/" prefix
- Save changes immediately via `viewModel.updateProject()`
- Follow NewProjectSheet form layout patterns (grouped form, section headers, semantic typography)

**Done when:**
- ProjectOverview renders in middle column when overview selected
- All project fields editable and persist on change
- Git branch displays when `.git/HEAD` exists in source directory
- No git branch shown when `.git/` missing or HEAD unparseable
- Form follows L18 design standards (system controls, semantic colors, typography)

## S006: Create ProjectReadme view

**Intent:** Build detail-column view for displaying README.md from source directory.

**Work:**
- Create `Sources/Hieroglyphs/Views/ProjectOverview/ProjectReadme.swift`
- Read README.md from `{sourceDirectory}/README.md` on appear
- Render with swift-markdown-ui `Markdown()` component (same as CardBodyEditor preview mode)
- Show ContentUnavailableView when no source directory or README not found
- ScrollView for long README content
- No editing (read-only)
- Follow CardBodyEditor preview mode layout

**Done when:**
- ProjectReadme renders README.md when file exists
- Empty state shown when no source directory or README missing
- Markdown renders correctly (headings, lists, code blocks, links)
- ScrollView handles long content gracefully

## S007: Create CommandExecutionService protocol and implementation

**Intent:** Build service for executing shell commands via Foundation.Process.

**Work:**
- Create `Sources/Hieroglyphs/Services/CommandExecutionService.swift`
- Define `CommandExecutionProviding` protocol with `executeCommand(command:workingDirectory:) async throws -> CommandResult` method
- Define `CommandResult` struct with `exitCode: Int`, `output: String`, `error: String`
- Implement `CommandExecutionService` conforming to protocol
- Use `Foundation.Process` to run command in specified working directory
- Capture stdout and stderr via Pipe
- Parse output to String (UTF8 decoding)
- Throw error on non-zero exit code or Process errors
- Add timeout handling (default 5 minutes)
- Create environment key for SwiftUI injection

**Done when:**
- Protocol defines clear contract for command execution
- Service executes commands and returns result with output/error
- Non-zero exit code throws error with captured output
- Service injected via environment key
- No regex used (string operations only)

## S008: Add CommandExecutionService tests

**Intent:** Verify command execution service behavior.

**Work:**
- Create `Tests/HieroglyphsTests/Services/CommandExecutionServiceTests.swift`
- Test successful command execution (e.g., `echo "test"`)
- Test command with non-zero exit (e.g., `exit 1`)
- Test output capture (stdout and stderr)
- Test working directory handling
- Test timeout behavior (skip if flaky on CI)
- Use simple shell commands that work on macOS (echo, ls, exit)

**Done when:**
- All tests pass
- Success, failure, and output capture tested
- Working directory verified
- No flaky tests

## S009: Add toolbar buttons to ProjectOverview

**Intent:** Show Build/Run/Publish toolbar buttons when commands configured.

**Work:**
- Add `.toolbar {}` modifier to ProjectOverview
- Three ToolbarItems: Build, Run, Publish
- Each button visible only when corresponding command is non-nil and non-empty
- Each button disabled when no source directory configured
- Use SF Symbols: "hammer" (Build), "play.fill" (Run), "arrow.up.doc" (Publish)
- Button actions set `@State var executingCommand: CommandType?` to trigger modal
- Define `enum CommandType { case build, run, publish }` in ProjectOverview

**Done when:**
- Toolbar buttons appear only when commands configured
- Buttons disabled when no source directory
- Clicking button sets executingCommand state
- SF Symbols render correctly

## S010: Create CommandExecutionModal view

**Intent:** Build modal sheet for command execution with progress/output/result.

**Work:**
- Create `Sources/Hieroglyphs/Views/ProjectOverview/CommandExecutionModal.swift`
- Accept bindings: `@Binding var isPresented: Bool`, command: String, workingDirectory: String, title: String
- Three states: `.running`, `.success(output)`, `.failure(error)`
- Running state: ProgressView with "Executing..." message
- Success state: green checkmark icon, "{title} Complete" message, "Done" button
- Failure state: red exclamationmark icon, "Failed" message, error output (scrollable), "Close" button
- Launch async task on appear: call commandExecutionService.executeCommand()
- Update state based on result
- Modal cannot be dismissed while running (no close button)
- Fixed frame (600x400) with scrollable output area
- Follow L17 modal sizing patterns

**Done when:**
- Modal shows progress while command runs
- Success shows green checkmark and done button
- Failure shows red icon and error output
- Modal constrained to 600x400 with scrollable content
- Cannot dismiss while running
- Follows L18 design standards

## S011: Wire CommandExecutionModal to ProjectOverview

**Intent:** Present CommandExecutionModal when toolbar buttons clicked.

**Work:**
- Add `@State var executingCommand: CommandType?` to ProjectOverview
- Add `.sheet(isPresented:)` modifier bound to `executingCommand != nil`
- Pass appropriate command string based on executingCommand value
- Pass project.sourceDirectory as working directory
- Pass command-specific title ("Build", "Run", "Publish")
- Reset executingCommand to nil when modal dismissed
- Inject commandExecutionService via environment

**Done when:**
- Clicking Build button shows modal with buildCommand execution
- Clicking Run button shows modal with runCommand execution
- Clicking Publish button shows modal with publishCommand execution
- Modal executes command in source directory
- Success/failure feedback displays correctly
- Modal dismisses on done/close button click

## S012: Fix ProjectOverview to use viewModel.updateProject instead of direct service calls

**Intent:** Remove architectural violation where ProjectOverview calls WorkspaceService directly and calls nonexistent viewModel.reloadProjects() method.

**Work:**
- Remove `@Environment(\.workspaceService)` from ProjectOverview
- Change `saveProject()` to call `viewModel.updateProject(updatedProject)` instead of `workspaceService.updateProject(...)` followed by `viewModel.reloadProjects()`
- Remove `workspacePath` guard in `saveProject()` — ViewModel handles this
- Verify ProjectOverview compiles with no errors

**Done when:**
- ProjectOverview no longer imports or uses workspaceService directly
- `saveProject()` delegates to `viewModel.updateProject(_:)`
- No calls to nonexistent `viewModel.reloadProjects()` method
- Code compiles without errors
- Project updates persist correctly when testing in UI

## S013: Update models.md to document command fields

**Intent:** Reconcile models.md documentation with the new Project model command fields introduced in this phase.

**Work:**
- Open `.ushabti/docs/models.md`
- Add documentation for `buildCommand`, `runCommand`, `publishCommand` optional String properties in the Project section
- Update example Project frontmatter YAML to show command fields
- Explain that command fields are optional and used for command execution in ProjectOverview

**Done when:**
- models.md documents all three command fields
- Example frontmatter includes command fields
- Documentation explains the purpose and usage of command fields

## S014: Update views-ui.md to document ProjectOverview and ProjectReadme

**Intent:** Reconcile views-ui.md documentation with the new ProjectOverview and ProjectReadme views introduced in this phase.

**Work:**
- Open `.ushabti/docs/views-ui.md`
- Add section documenting `ProjectOverview` view (editable form, git branch detection, toolbar commands)
- Add section documenting `ProjectReadme` view (markdown rendering, empty states)
- Add section documenting `CommandExecutionModal` view (running/success/failure states)
- Document `SidebarSection.overview(Project)` enum case and routing
- Explain progressive disclosure pattern for command buttons (shown only when configured, disabled without source directory)

**Done when:**
- views-ui.md documents ProjectOverview with form fields and toolbar behavior
- views-ui.md documents ProjectReadme with markdown rendering and empty state patterns
- views-ui.md documents CommandExecutionModal state machine
- Documentation explains overview section routing in MainWindow
