# Implementation Steps

## Step 1: Copy MarkdownConfiguration from TakeNote

**Intent:** Provide markdown syntax highlighting for CodeEditor by copying the MarkdownConfiguration extension from TakeNote.

**Work:**
- Create `Sources/Hieroglyphs/Utilities/MarkdownConfiguration.swift`
- Copy the entire MarkdownConfiguration extension from `/Users/adam/Library/Mobile Documents/com~apple~CloudDocs/Xcode Projects/TakeNote/TakeNote/Library/MarkdownConfiguration.swift`
- Verify imports are correct (Foundation, RegexBuilder, LanguageSupport)
- Update file header comment to reference Hieroglyphs

**Done when:**
- MarkdownConfiguration.swift exists in Utilities directory
- File compiles without errors
- Extension provides `.markdown()` static method returning LanguageConfiguration

## Step 2: Add updateCard method to ViewModel

**Intent:** Provide ViewModel coordination for updating cards via WorkspaceService.

**Work:**
- Add `updateCard(_:)` method to HieroglyphsVM
- Method signature: `func updateCard(_ card: Card)`
- Guard check workspacePath and selectedProject are not nil
- Construct projectPath from workspacePath and selectedProject.slug
- Call `workspaceService.updateCard(card, projectPath: projectPath)`
- Call `loadCards()` to reload card list after update
- Wrap in do-catch and log errors to console

**Done when:**
- HieroglyphsVM has `updateCard(_:)` method
- Method calls WorkspaceService.updateCard() with correct parameters
- Method reloads cards after successful update
- Errors are caught and logged

## Step 3: Write tests for ViewModel updateCard

**Intent:** Verify ViewModel.updateCard() coordinates correctly with WorkspaceService.

**Work:**
- Add test method to HieroglyphsVMTests: `testUpdateCardSuccess`
- Configure mock service to succeed on updateCard
- Set ViewModel workspacePath and selectedProject
- Create test card and call `viewModel.updateCard(card)`
- Verify mock service's updateCard was called with correct card and projectPath
- Verify loadCards was called to reload list
- Add test method: `testUpdateCardWithNilWorkspacePath`
- Verify operation fails gracefully (logs error, does not crash)
- Add test method: `testUpdateCardWithNilSelectedProject`
- Verify operation fails gracefully

**Done when:**
- Three test methods added to HieroglyphsVMTests
- Tests pass
- All execution paths through updateCard are tested

## Step 4: Implement TagChipView component

**Intent:** Display and edit tags as chips with delete buttons.

**Work:**
- Create `Sources/Hieroglyphs/Views/Shared/TagChipView.swift`
- Component displays a tag string as a pill/chip with SF Symbol delete button
- Parameters: `tag: String`, `onDelete: () -> Void`
- Visual style: rounded rectangle background, secondary color, small font
- Delete button: `xmark.circle.fill` SF Symbol, triggers onDelete callback
- Keep component small and focused (follows Sandi Metz principles)

**Done when:**
- TagChipView.swift exists
- View renders tag string with delete button
- Tapping delete button triggers onDelete callback
- Visual style matches TakeNote patterns (rounded, secondary color)

## Step 5: Implement CardMetadataEditor component

**Intent:** Display and edit card frontmatter fields (title, type, status, priority, tags).

**Work:**
- Create `Sources/Hieroglyphs/Views/CardDetail/CardMetadataEditor.swift`
- Component takes bindings: `card: Binding<Card>`, `onUpdate: () -> Void`
- Layout: Form or VStack with sections for fields
- Title: TextField bound to card.title
- Type: Picker with all CardType cases, bound to card.type
- Status: Picker with all CardStatus cases, bound to card.status
- Priority: Picker with all Priority cases, bound to card.priority
- Tags: HStack of TagChipView chips + TextField and Add button for new tags
- All pickers use `.pickerStyle(.menu)` for compact dropdown style
- Add `.onChange(of:)` handlers on each field to call onUpdate callback
- Format enum labels for display (replace hyphens with spaces, capitalize)

**Done when:**
- CardMetadataEditor.swift exists
- All fields are editable and bound to card properties
- onChange handlers call onUpdate callback when fields change
- Pickers display all enum cases with formatted labels
- Tags display as chips with add/remove functionality

## Step 6: Implement CardBodyEditor component

**Intent:** Display and edit card markdown body using click-to-edit pattern from TakeNote.

**Work:**
- Create `Sources/Hieroglyphs/Views/CardDetail/CardBodyEditor.swift`
- Component takes bindings: `body: Binding<String>`, `onUpdate: () -> Void`
- Add `@State private var showPreview: Bool = true` for mode toggle
- Layout: ZStack with two modes (following TakeNote NoteEditor lines 224-296)
- Preview mode: ScrollView with `Markdown(body)` view
  - Add `.onTapGesture { showPreview.toggle() }` to enter edit mode
- Edit mode: `CodeEditor(text: body, language: .markdown())`
  - Configure with `layout: CodeEditor.LayoutConfiguration(showMinimap: false, wrapText: true)`
  - Add `.onExitCommand { showPreview.toggle() }` for Escape key (macOS only)
- Add `.onChange(of: body.wrappedValue)` to call onUpdate callback when content changes
- Use GeometryReader to fill available space
- Import CodeEditorView, LanguageSupport, MarkdownUI

**Done when:**
- CardBodyEditor.swift exists
- ZStack with showPreview toggle works
- Markdown preview displays rendered content
- Tapping preview switches to CodeEditor
- CodeEditor uses .markdown() language configuration
- Escape key returns to preview mode
- onChange handler calls onUpdate callback

## Step 7: Implement CardDetail view

**Intent:** Compose CardMetadataEditor and CardBodyEditor into the detail column view.

**Work:**
- Create `Sources/Hieroglyphs/Views/CardDetail/CardDetail.swift`
- Access ViewModel via `@Environment(HieroglyphsVM.self)`
- Guard check `viewModel.selectedCard` is not nil
  - If nil, show ContentUnavailableView with "No Card Selected" message
- Create `@State private var editableCard: Card?` copy of selectedCard for local edits
- Sync editableCard with selectedCard via `.onChange(of: viewModel.selectedCard)`
- Layout: VStack with two sections:
  1. CardMetadataEditor at top (non-scrollable, fixed height)
  2. CardBodyEditor below (fills remaining space)
- Pass bindings to editableCard fields
- onUpdate callback: call `viewModel.updateCard(editableCard)`
- Use `.navigationTitle(editableCard?.title ?? "Card")` for detail column title

**Done when:**
- CardDetail.swift exists
- Empty state shows when no card selected
- CardMetadataEditor displays at top with all frontmatter fields
- CardBodyEditor displays below with markdown content
- Edits to any field call viewModel.updateCard()
- Navigation title shows card title

## Step 8: Integrate CardDetail into MainWindow

**Intent:** Replace placeholder detail column with CardDetail view.

**Work:**
- Open `Sources/Hieroglyphs/Views/MainWindow.swift`
- Replace `Text("Detail")` placeholder with `CardDetail()`
- Verify NavigationSplitView detail column now shows CardDetail

**Done when:**
- MainWindow.swift detail column renders CardDetail
- App compiles and runs
- Selecting a card in CardList displays CardDetail in detail column
- No card selected shows "No Card Selected" placeholder

## Step 9: Manual testing and refinement

**Intent:** Verify end-to-end card editing workflow and fix any issues.

**Work:**
- Run app with `swift run` or via build-app.sh
- Select a project, select a card
- Verify CardDetail displays all frontmatter fields correctly
- Edit title, type, status, priority fields and verify changes save to disk
- Add and remove tags, verify changes save
- Tap markdown preview to enter edit mode
- Type markdown content in CodeEditor
- Verify syntax highlighting works (headings, emphasis, code, lists)
- Press Escape to return to preview
- Verify markdown renders correctly
- Verify changes persist by quitting app and reopening
- Fix any bugs discovered during testing

**Done when:**
- All frontmatter fields are editable and save correctly
- Click-to-edit markdown pattern works smoothly
- Syntax highlighting displays correctly
- Changes persist to disk
- No crashes or console errors during normal editing workflow

## Step 10: Update documentation

**Intent:** Document CardDetail view and markdown editing in project docs.

**Work:**
- Open `.ushabti/docs/views-ui.md`
- Add new section: "CardDetail" after CardList section
- Document CardDetail view structure and behavior
- Document CardMetadataEditor component
- Document CardBodyEditor component and click-to-edit pattern
- Document TagChipView component
- Reference TakeNote's NoteEditor as source of click-to-edit pattern
- Update "Future View Components" section to remove CardDetail (now complete)
- Verify `.ushabti/docs/index.md` links are still accurate

**Done when:**
- views-ui.md contains comprehensive CardDetail documentation
- Documentation includes code examples and behavior descriptions
- Links in index.md are verified and updated if needed
