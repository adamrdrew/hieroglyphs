# Steps

## S001: Add WelcomeView

**Intent:** Display first-launch welcome screen with directory picker button

**Work:**
- Create `Sources/Hieroglyphs/Views/Welcome/WelcomeView.swift`
- Show app title, brief description, and "Choose Workspace Folder" button
- Button action presents NSOpenPanel for directory selection
- On selection, call `viewModel.initializeWorkspace(at: selectedURL)`

**Done when:**
- WelcomeView exists
- NSOpenPanel presents when button clicked
- ViewModel method called with selected directory path

---

## S002: Add ViewModel workspace initialization

**Intent:** Handle workspace setup from welcome screen

**Work:**
- Add `initializeWorkspace(at:)` method to HieroglyphsVM
- Method calls `workspaceService.createWorkspace(at:configDirectory:)`
- Method calls `workspaceService.initializeWorkspaceFiles(at:)`
- Method calls `loadWorkspace()` to load newly created workspace
- Set `workspacePath` to trigger UI transition from WelcomeView to MainWindow

**Done when:**
- ViewModel has `initializeWorkspace(at:)` method
- Method creates workspace, writes config, generates CLAUDE.md and AGENT.md
- Method loads workspace and updates state

---

## S003: Add conditional welcome/main window in App.swift

**Intent:** Show WelcomeView when no config exists, otherwise show MainWindow

**Work:**
- Modify App.swift Window body to conditionally render based on `viewModel.workspacePath`
- If `workspacePath == nil`, show WelcomeView
- If `workspacePath != nil`, show MainWindow
- On `.onAppear`, attempt to load workspace (if load fails due to missing config, workspacePath remains nil)

**Done when:**
- App shows WelcomeView when config missing
- App shows MainWindow when config exists
- Transition from WelcomeView to MainWindow works after workspace initialization

---

## S004: Add menu bar commands

**Intent:** Provide keyboard shortcuts and menu items for common actions

**Work:**
- Add `.commands()` modifier in App.swift
- Define File menu with "New Project" (Cmd+Shift+N) and "New Card" (Cmd+N)
- Define Edit menu with "Delete" (Cmd+Delete) and "Find" (Cmd+F)
- Commands trigger ViewModel methods via @FocusedValue or direct calls
- Use `.disabled()` to disable Delete when no item selected

**Done when:**
- Menu commands appear in File and Edit menus
- Keyboard shortcuts trigger correct actions
- Delete command disabled when no selection

---

## S005: Add ViewModel sheet presentation state

**Intent:** Coordinate menu commands with sheet presentation

**Work:**
- Add published properties to ViewModel: `showingNewProjectSheet: Bool`, `showingNewCardSheet: Bool`
- Add methods: `showNewProjectSheet()`, `showNewCardSheet()`, `deleteSelectedItem()`
- Methods set sheet state to true or perform deletion

**Done when:**
- ViewModel has sheet presentation state properties
- Methods exist and modify state correctly
- Menu commands can trigger these methods

---

## S006: Update Sidebar and CardList to observe sheet state

**Intent:** Present sheets from ViewModel state, not local @State

**Work:**
- Update Sidebar to bind `.sheet(isPresented:)` to `viewModel.showingNewProjectSheet`
- Update CardList to bind `.sheet(isPresented:)` to `viewModel.showingNewCardSheet`
- Remove local `@State private var showingNewProjectSheet` and `showingNewCardSheet` variables
- Keep button actions but have them call `viewModel.showNewProjectSheet()` and `viewModel.showNewCardSheet()`

**Done when:**
- Sidebar presents NewProjectSheet from ViewModel state
- CardList presents NewCardSheet from ViewModel state
- Sheets present from both toolbar buttons and menu commands

---

## S007: Add empty state to Sidebar

**Intent:** Show helpful message when no projects exist

**Work:**
- Wrap Sidebar List in conditional Group or if/else
- If `viewModel.projects.isEmpty`, show `ContentUnavailableView("No Projects", systemImage: "folder", description: Text("Create a project to get started."))`
- Otherwise show List

**Done when:**
- Sidebar shows ContentUnavailableView when no projects exist
- Empty state includes folder icon and helpful description

---

## S008: Add delete command logic

**Intent:** Delete selected project or card via menu command

**Work:**
- Add `deleteSelectedItem()` method to ViewModel
- If `selectedCard != nil`, call `workspaceService.deleteCard(slug: selectedCard.slug, projectPath:)`
- Else if `selectedProject != nil`, call `workspaceService.deleteProject(at:)`
- Reload projects or cards after deletion
- Clear selection state after deletion

**Done when:**
- ViewModel method deletes selected card if card selected
- ViewModel method deletes selected project if project selected (and no card selected)
- UI reloads and reflects deletion
- Selection cleared after deletion

---

## S009: Add Find menu command

**Intent:** Focus search field when Cmd+F pressed

**Work:**
- Add `@FocusState` to CardList for search field focus
- Add `focusSearch: Bool` published property to ViewModel
- Add `requestSearchFocus()` method to ViewModel that sets `focusSearch = true`
- Edit > Find menu command calls `viewModel.requestSearchFocus()`
- CardList observes `viewModel.focusSearch` and sets local focus state

**Done when:**
- Cmd+F triggers menu command
- Menu command sets ViewModel focus state
- CardList focuses search field when state changes

---

## S010: Add app icon

**Intent:** Visual identity in Dock and window

**Work:**
- Design or select 1024x1024 PNG icon (hieroglyphic glyph, stylized "H", or markdown symbol)
- Use `iconutil` or export tool to create AppIcon.icns with all required macOS sizes
- Place AppIcon.icns in `Resources/` directory
- Update Package.swift `.executableTarget` to include `resources: [.process("Resources")]`
- Reference icon in Info.plist or via Package.swift metadata

**Done when:**
- AppIcon.icns exists in Resources/
- Package.swift references Resources/ directory
- Icon appears in Dock when app runs

---

## S011: Review and verify malformed file handling

**Intent:** Ensure app never crashes on bad data

**Work:**
- Review WorkspaceService `loadProjects()` and `loadCards()` error handling
- Verify that parse errors are caught and logged (not thrown)
- Create test project with invalid YAML frontmatter
- Launch app and verify project is skipped with console log, app doesn't crash
- Verify unknown fields are preserved on successful parse (existing tests cover this)

**Done when:**
- Manual test confirms app handles malformed YAML gracefully
- App logs error to console
- App skips malformed item and continues loading

---

## S012: Write tests for new ViewModel methods

**Intent:** Test coverage for workspace initialization and delete logic

**Work:**
- Add tests for `initializeWorkspace(at:)` using MockWorkspaceService
- Verify method calls `createWorkspace()`, `initializeWorkspaceFiles()`, and `loadWorkspace()`
- Add tests for `deleteSelectedItem()` with selected card and selected project
- Verify correct service methods called with correct slugs
- Add tests for `showNewProjectSheet()` and `showNewCardSheet()` state changes

**Done when:**
- Tests exist for all new ViewModel public methods
- Tests use MockWorkspaceService
- All tests pass

---

## S013: Update documentation

**Intent:** Document first-launch flow and menu commands

**Work:**
- Update `.ushabti/docs/views-ui.md` to document WelcomeView structure
- Document conditional rendering in App.swift (WelcomeView vs MainWindow)
- Update `.ushabti/docs/viewmodel.md` to document new methods: `initializeWorkspace()`, `deleteSelectedItem()`, `showNewProjectSheet()`, `showNewCardSheet()`, `requestSearchFocus()`
- Document sheet presentation state properties
- Add note about menu commands and keyboard shortcuts

**Done when:**
- views-ui.md includes WelcomeView documentation
- viewmodel.md includes all new methods and properties
- Documentation reconciled with code changes

---

## S014: Fix Info.plist build warning

**Intent:** Eliminate build warning about unhandled Info.plist file

**Work:**
- Update Package.swift to declare Info.plist in resources array
- Change `resources: [.copy("Resources/AppIcon.icns")]` to include Info.plist
- Verify build completes with no warnings

**Done when:**
- Package.swift declares both AppIcon.icns and Info.plist in resources
- `swift build` produces no warnings
