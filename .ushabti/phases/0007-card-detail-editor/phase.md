# Phase 7: Card Detail and Markdown Editing

## Intent

Implement the detail column of the three-column NavigationSplitView to display and edit card metadata and markdown body. The CardDetail view provides editable frontmatter fields (title, type, status, priority, tags) and a click-to-edit markdown editor using the TakeNote pattern: rendered Markdown preview by default, tap to switch to CodeEditor with syntax highlighting, Escape to return to preview. All changes write back to disk immediately via WorkspaceService, maintaining L01 (Filesystem as Source of Truth) and L02 (Preserve Unknown Fields). This completes the core CRUD workflow for cards.

## Scope

**In scope:**
- `CardDetail` view displaying selected card with editable frontmatter and markdown body
- Frontmatter field editors:
  - Title: TextField
  - Type: Picker/Menu with predefined options (task, bug, feature, note) but displays raw frontmatter value
  - Status: Picker/Menu with predefined options (backlog, todo, in-progress, done, archived) but displays raw value
  - Priority: Picker/Menu with predefined options (low, medium, high, critical) but displays raw value
  - Tags: Custom chip UI with add/remove buttons
- Click-to-edit markdown pattern from TakeNote:
  - ZStack with `showPreview` state toggle
  - Preview mode: `Markdown()` view with `.onTapGesture` to enter edit mode
  - Edit mode: `CodeEditor()` with `.markdown()` language configuration
  - Escape key (`.onExitCommand`) returns to preview mode
- `MarkdownConfiguration` extension copied from TakeNote for syntax highlighting
- ViewModel extension: `updateCard(_:)` method to save card changes
- WorkspaceService integration: `updateCard(_:projectPath:)` already exists (Phase 4)
- Empty state: "No Card Selected" placeholder when `selectedCard` is nil
- Tests for ViewModel `updateCard(_:)` method
- Documentation updates for CardDetail and markdown editing

**Out of scope:**
- Card deletion (future)
- Card archiving shortcut (future)
- Markdown toolbar with formatting buttons (future)
- Live preview split-view mode (future, if needed)
- Undo/redo (relies on SwiftUI TextEditor undo, acceptable for v1)
- Spell check toggle (system provides this)
- Attachment/image handling (future)
- Backlinks display (future)
- AI assistant integration (future)
- Full-screen editor mode (future)

## Constraints

**Laws:**
- L01 (Filesystem as Source of Truth): All edits write to disk via WorkspaceService immediately
- L02 (Opinionated on Write, Laissez-Faire on Read): UI offers predefined enum values but displays whatever exists in frontmatter
- L05 (External Changes First-Class): Not implemented in this phase (file watching deferred), but editor should not block external writes
- L09 (Sandi Metz): Small, focused view components; ViewModel coordinates; service performs I/O
- L10 (Design Consistency with TakeNote): Copy click-to-edit pattern, MarkdownConfiguration, and visual layout from TakeNote's NoteEditor
- L11 (Test Coverage): ViewModel `updateCard(_:)` must have tests

**Style:**
- Small views: CardDetail, CardMetadataEditor (frontmatter fields), CardBodyEditor (markdown editor), TagChipView
- Click-to-edit ZStack pattern from TakeNote (lines 224-296 of NoteEditor.swift)
- MarkdownConfiguration copied directly from TakeNote (MarkdownConfiguration.swift)
- `.onExitCommand` for Escape key behavior on macOS
- Immediate writes: onChange handlers call ViewModel.updateCard() when fields change
- No debouncing: simple immediate writes (future optimization if needed)

## Acceptance Criteria

1. **CardDetail renders for selected card**: When a card is selected in CardList, CardDetail displays card metadata fields and markdown body
2. **Title field is editable**: TextField bound to card title; changes write to disk via ViewModel.updateCard()
3. **Type picker works**: Picker/Menu shows predefined options (task, bug, feature, note); displays raw frontmatter value; writes enum raw value on change
4. **Status picker works**: Picker/Menu shows predefined options (backlog, todo, in-progress, done, archived); displays raw value; writes enum raw value on change
5. **Priority picker works**: Picker/Menu shows predefined options (low, medium, high, critical); displays raw value; writes enum raw value on change
6. **Tag chips display and edit**: Tags shown as chips; user can add new tags via TextField + button; user can remove tags via chip delete button; changes write to disk
7. **Markdown preview displays**: Rendered Markdown() view shows card body by default
8. **Click to edit works**: Tapping markdown preview switches to CodeEditor with syntax highlighting
9. **Escape returns to preview**: Pressing Escape in edit mode switches back to Markdown preview
10. **Syntax highlighting works**: CodeEditor uses MarkdownConfiguration for markdown syntax highlighting (headings, emphasis, code, lists, links)
11. **Empty state handled**: When no card selected, show "No Card Selected" placeholder
12. **ViewModel updateCard works**: ViewModel.updateCard() calls WorkspaceService.updateCard() and reloads cards
13. **Tests pass**: ViewModel tests for updateCard() with mock service
14. **Docs updated**: views-ui.md updated with CardDetail section; index.md links updated if needed

## Risks / Notes

- **Write frequency**: Immediate writes on every field change may cause performance issues with very large cards or slow disks. Acceptable for v1; future optimization may add debouncing.
- **Concurrent writes**: If user edits multiple fields rapidly, multiple writes may occur in sequence. WorkspaceService uses atomic writes, so this is safe but inefficient. Future optimization may batch writes.
- **Unknown field preservation**: WorkspaceService.updateCard() already preserves unknown frontmatter fields per L02. CardDetail does not need special handling.
- **Escape key conflict**: `.onExitCommand` is macOS-only. On iOS (not in scope per L07), we'd need a toolbar button to exit edit mode. Since we're macOS-only, this is fine.
- **Tag input UX**: Simple TextField + button for adding tags is minimal but functional. Future enhancement may add autocomplete picker from existing tags across workspace.
- **Card body length**: CodeEditor and Markdown views handle long content well. No pagination needed for v1.
