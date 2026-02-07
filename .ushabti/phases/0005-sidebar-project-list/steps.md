# Implementation Steps

## Step 1: Create HieroglyphsVM

**Intent:** Establish the ViewModel layer that coordinates between WorkspaceService and UI views.

**Work:**
- Create `Sources/Hieroglyphs/HieroglyphsVM.swift`
- Define as `@Observable @MainActor final class`
- Add properties: `workspacePath: String?`, `projects: [Project] = []`, `selectedProject: Project?`
- Add `private let workspaceService: WorkspaceProviding` property
- Add `init(workspaceService: WorkspaceProviding)` initializer
- Add `loadWorkspace()` method that loads config, extracts workspace path, loads projects
- Add `createProject(title:description:tags:)` method that delegates to service, then reloads projects
- Add `selectProject(_:)` method that updates selectedProject
- Handle errors by logging to console (no UI error handling in this phase)

**Done when:**
- HieroglyphsVM.swift exists with all specified properties and methods
- File compiles without errors
- ViewModel is @Observable and @MainActor

## Step 2: Write ViewModel Tests

**Intent:** Verify ViewModel behavior in isolation using mock workspace service.

**Work:**
- Create `Tests/HieroglyphsTests/HieroglyphsVMTests.swift`
- Create `MockWorkspaceService` conforming to `WorkspaceProviding` for test isolation
- Test `loadWorkspace()` success: mock returns config and projects, verify projects loaded
- Test `loadWorkspace()` config failure: mock throws configNotFound, verify projects empty
- Test `createProject(title:description:tags:)`: mock returns new project, verify projects reloaded
- Test `selectProject(_:)`: verify selectedProject updated
- Use XCTest assertions for all cases

**Done when:**
- HieroglyphsVMTests.swift exists with tests for all public ViewModel methods
- `swift test` passes for ViewModel tests

## Step 3: Integrate ViewModel into App

**Intent:** Create and inject ViewModel at app entry point for environment propagation.

**Work:**
- Open `Sources/Hieroglyphs/App.swift`
- Create `WorkspaceService()` instance in App struct
- Create `HieroglyphsVM(workspaceService:)` instance in App struct using `@State`
- Add `.environment(viewModel)` modifier to MainWindow in Window scene
- Call `viewModel.loadWorkspace()` in `.onAppear` of MainWindow

**Done when:**
- App.swift creates and injects ViewModel via environment
- App compiles without errors

## Step 4: Create SidebarProjectEntry View

**Intent:** Build the reusable project entry component that displays title and card count summary.

**Work:**
- Create `Sources/Hieroglyphs/Views/Sidebar/SidebarProjectEntry.swift`
- Define view with `project: Project` and `workspaceService: WorkspaceProviding` parameters
- Add `@State private var cardCounts: [CardStatus: Int] = [:]` for count storage
- Add `.onAppear` that loads cards via `workspaceService.loadCards`, computes counts grouped by status
- Display project title as primary text
- Display card count summary as secondary text (format: "N status • N status")
- Filter counts to only show statuses with non-zero cards
- Use `folder.fill` SF Symbol as icon
- Format status labels: replace hyphens with spaces (e.g., "in-progress" → "in progress")

**Done when:**
- SidebarProjectEntry.swift exists and compiles
- View displays project title and computed card count summary
- Card counts loaded and grouped by status in onAppear

## Step 5: Create Sidebar View

**Intent:** Build the sidebar list view that displays projects and handles selection.

**Work:**
- Create `Sources/Hieroglyphs/Views/Sidebar/Sidebar.swift`
- Add `@Environment(HieroglyphsVM.self) private var viewModel` to access ViewModel
- Add `@Environment(\.workspaceService) private var workspaceService` (define environment key if needed)
- Display `List(selection: $viewModel.selectedProject)` bound to ViewModel selection
- Iterate over `viewModel.projects` and display `SidebarProjectEntry` for each
- Add toolbar with ToolbarItem for New Project button (SF Symbol: plus)
- Add `@State private var showingNewProjectSheet = false` for sheet presentation
- Add `.sheet(isPresented: $showingNewProjectSheet)` presenting NewProjectSheet
- Use `.listStyle(.sidebar)` for sidebar appearance

**Done when:**
- Sidebar.swift exists and compiles
- List displays projects with selection binding
- New Project toolbar button presents sheet
- Sidebar styled with `.listStyle(.sidebar)`

## Step 6: Create NewProjectSheet View

**Intent:** Build the project creation form sheet.

**Work:**
- Create `Sources/Hieroglyphs/Views/Sidebar/NewProjectSheet.swift`
- Add `@Environment(HieroglyphsVM.self) private var viewModel`
- Add `@Environment(\.dismiss) private var dismiss`
- Add `@State` properties for title, description, tags (String)
- Display Form with sections for title (TextField), description (TextField), tags (TextField with prompt "Comma-separated")
- Add toolbar buttons: Cancel (dismisses), Save (calls viewModel.createProject, dismisses)
- Parse tags by splitting on comma, trimming whitespace, filtering empty strings
- Disable Save button if title is empty

**Done when:**
- NewProjectSheet.swift exists and compiles
- Form displays all input fields
- Save calls viewModel.createProject with parsed inputs
- Cancel and Save both dismiss sheet

## Step 7: Define WorkspaceService Environment Key

**Intent:** Enable environment injection of WorkspaceProviding for view access.

**Work:**
- Create `Sources/Hieroglyphs/Services/WorkspaceServiceEnvironmentKey.swift`
- Define `struct WorkspaceServiceKey: EnvironmentKey` with default value (WorkspaceService())
- Extend `EnvironmentValues` with `var workspaceService: WorkspaceProviding` computed property
- Use `@Entry` macro if available on macOS 26, otherwise use manual subscript pattern

**Done when:**
- Environment key defined for WorkspaceProviding
- WorkspaceService can be injected and accessed via `@Environment(\.workspaceService)`

## Step 8: Integrate Sidebar into MainWindow

**Intent:** Replace sidebar placeholder with actual Sidebar view.

**Work:**
- Open `Sources/Hieroglyphs/Views/MainWindow.swift`
- Replace `Text("Sidebar")` placeholder with `Sidebar()`
- Ensure NavigationSplitView preserves existing structure
- Verify preferredCompactColumn state is unchanged

**Done when:**
- MainWindow.swift integrates Sidebar view
- NavigationSplitView displays Sidebar in sidebar column
- App compiles without errors

## Step 9: Test End-to-End Project Display

**Intent:** Verify that the app loads and displays projects in the sidebar on launch.

**Work:**
- Create a test workspace directory with sample projects
- Update `~/.hieroglyphs/config.yaml` to point to test workspace
- Run `swift run` to launch app
- Verify Sidebar displays project list with card counts
- Verify clicking a project updates selection state
- Verify New Project button opens sheet
- Verify creating a project adds it to the list

**Done when:**
- App launches without errors
- Sidebar displays projects loaded from workspace
- Selection and creation workflows work as expected

## Step 10: Run Full Test Suite

**Intent:** Verify all tests pass and code quality is maintained.

**Work:**
- Run `swift test` to execute all tests
- Verify ViewModel tests pass
- Verify existing workspace service tests still pass
- Fix any test failures or regressions
- Run `swift build` to check for warnings
- Address any compiler warnings

**Done when:**
- `swift test` reports 100% pass rate
- `swift build` completes with no errors or warnings
- All acceptance criteria verified
