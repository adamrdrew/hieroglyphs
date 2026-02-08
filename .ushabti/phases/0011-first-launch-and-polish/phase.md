# Phase 11: First Launch and Polish

## Intent

Implement first-launch onboarding and production-ready polish. When the app launches without a workspace config, present a welcome screen with directory picker to initialize the workspace. Add menu bar commands with keyboard shortcuts for common actions (new project, new card, delete, search). Ensure empty states are visible and helpful. Harden error handling to gracefully handle malformed files without crashing. Add an app icon for visual identity.

This phase makes the app ready for first-time users and production use.

## Scope

**In scope:**
- **First-launch flow:**
  - Check for config on app launch
  - WelcomeView with directory picker (NSOpenPanel)
  - Write config.yaml on workspace selection
  - Call `initializeWorkspaceFiles` to generate CLAUDE.md and AGENT.md
  - Transition to main window after setup
- **Menu bar commands:**
  - File > New Project (Cmd+Shift+N)
  - File > New Card (Cmd+N)
  - Edit > Delete (Cmd+Delete)
  - Edit > Find (Cmd+F) — focuses search field
  - Integrate `.commands()` modifier in App.swift
- **Empty state views:**
  - Sidebar: No projects empty state
  - CardList: No project selected empty state (already exists)
  - CardList: No cards empty state (already exists)
  - CardDetail: No card selected empty state (already exists)
- **Malformed file handling:**
  - Review WorkspaceService error handling (already logs and skips bad files)
  - Add ViewModel-level error logging for user visibility (console logging acceptable for v1)
  - Ensure app never crashes on bad YAML or missing fields
- **App icon:**
  - Design simple icon (hieroglyphic glyph or stylized markdown symbol)
  - Create AppIcon.icns (1024x1024 source image scaled to macOS icon sizes)
  - Add to Resources/ and reference in Package.swift

**Out of scope:**
- Welcome screen customization (workspace name, initial projects) — user can add after setup
- Error UI alerts (console logging sufficient for v1; future: non-modal error banner)
- Advanced menu commands (preferences, export, etc.) — future enhancement
- Custom icon design tooling (use manual design or template)
- macOS menu bar integration beyond basic commands (future: Edit menu, View menu, etc.)

## Constraints

**Laws:**
- **L01 (Filesystem as Truth):** Config check reads from disk on every launch
- **L02 (Laissez-Faire on Read):** Malformed files are skipped with logging, unknown fields preserved on successful parse
- **L06 (Platform Leverage):** Use NSOpenPanel for directory picker, SwiftUI `.commands()` for menu bar
- **L09 (Sandi Metz Principles):** Small views, protocol-based services
- **L11 (Test Coverage):** All public methods tested (note: views not unit tested, but logic tested via ViewModel)
- **L13-L16 (Docs):** Update docs if systems change (likely minimal; new views, no architecture changes)

**Style:**
- Small, focused views (WelcomeView ~50 lines)
- Form-based input where applicable
- ContentUnavailableView for empty states
- Error handling: log to console, don't crash, show what we can
- Menu commands follow macOS conventions (Cmd+N for new item, Cmd+Delete for delete, Cmd+F for search)

## Acceptance Criteria

1. **First launch works:** Delete `~/.hieroglyphs/config.yaml`, launch app, see WelcomeView with directory picker
2. **Workspace setup completes:** Select directory in picker, app writes `config.yaml`, generates `CLAUDE.md` and `AGENT.md`, loads workspace, shows main window
3. **Config exists path works:** With config present, app skips welcome and loads workspace directly
4. **Menu commands present:** File menu has "New Project" and "New Card", Edit menu has "Delete" and "Find"
5. **Keyboard shortcuts work:** Cmd+Shift+N creates project, Cmd+N creates card, Cmd+Delete deletes selected item, Cmd+F focuses search field
6. **Empty state: No projects:** Sidebar shows ContentUnavailableView when no projects exist
7. **Empty state: No cards:** CardList shows appropriate empty state (already implemented; verify works)
8. **Empty state: No card selected:** CardDetail shows empty state (already implemented; verify works)
9. **Malformed file handling:** Create project with invalid YAML frontmatter, app logs error and skips project without crashing
10. **App icon displays:** Icon appears in Dock and window title bar
11. **Tests pass:** All existing tests pass (new views are not unit tested)
12. **Lint passes:** Build succeeds with no warnings

## Risks / Notes

- **NSOpenPanel integration:** Directory picker requires `NSOpenPanel` (AppKit). SwiftUI has no native file picker for directories. Use `NSOpenPanel.runModal()` from Button action.
- **Menu command state:** Delete command should be disabled when no item selected. Menu commands use `.disabled()` based on ViewModel selection state.
- **Icon design:** Simple design acceptable for v1 (hieroglyphic glyph or stylized "H"). Future: custom branding.
- **CLAUDE.md and AGENT.md content:** WorkspaceService already has `initializeWorkspaceFiles` method (per workspace-service.md). Verify content is appropriate for first-time users.
- **Welcome screen dismissal:** After setup, welcome view is replaced by main window. Use conditional view in App.swift based on ViewModel state (e.g., `workspacePath == nil`).
