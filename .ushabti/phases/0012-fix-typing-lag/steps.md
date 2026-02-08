# Steps for Phase 0012

## S001: Investigate and Document Root Cause

**Intent:** Confirm the suspected cause of typing lag and document the exact call chain.

**Work:**
- Trace code path from keystroke in CardBodyEditor to disk write
- Document the call chain: CardBodyEditor.contentBinding → CardDetail.saveCard() → HieroglyphsVM.updateCard() → WorkspaceService.updateCard() → disk write → loadCards() → disk read
- Confirm that this happens synchronously on every keystroke
- Document findings in step notes

**Done when:** Step notes contain documented call chain proving synchronous disk write on every keystroke.

## S002: Add Debouncer Utility

**Intent:** Create a reusable debouncing mechanism following Sandi Metz principles.

**Work:**
- Create `Sources/Hieroglyphs/Utilities/Debouncer.swift`
- Implement debouncing using DispatchWorkItem or Task with delay
- Support configurable delay interval
- Support immediate flush on demand
- Support cancellation on deinit
- Ensure main-thread safety

**Done when:**
- Debouncer utility exists in Utilities/
- Public API includes: init(delay:), schedule(action:), flush(), cancel()
- Implementation uses Swift concurrency or DispatchQueue appropriately

## S003: Add Tests for Debouncer

**Intent:** Verify debouncing logic works correctly in isolation.

**Work:**
- Create `Tests/HieroglyphsTests/DebouncerTests.swift`
- Test scheduled action executes after delay
- Test multiple rapid schedules result in single execution
- Test flush executes action immediately
- Test cancel prevents execution

**Done when:**
- All debouncer tests exist and pass
- Test coverage includes delay, coalescing, flush, and cancel behaviors

## S004: Add Debounced Save to HieroglyphsVM

**Intent:** Add debouncing capability to ViewModel without breaking existing immediate-write use cases.

**Work:**
- Add private `Debouncer` instance to HieroglyphsVM (1.5 second delay)
- Add `updateCardDebounced(_:)` method that schedules debounced write
- Keep existing `updateCard(_:)` method for immediate writes (picker changes, tag operations)
- Add `flushPendingCardUpdates()` method that calls debouncer.flush()
- Store pending card update in private property to pass to debouncer action

**Done when:**
- HieroglyphsVM has both `updateCard(_:)` (immediate) and `updateCardDebounced(_:)` methods
- HieroglyphsVM has `flushPendingCardUpdates()` method
- Debouncer initialized with appropriate delay

## S005: Update CardBodyEditor to Use Debounced Saves

**Intent:** Stop writing to disk on every keystroke in body editor.

**Work:**
- Change CardDetail.saveCard() to accept optional `debounced: Bool` parameter (default false)
- Update CardBodyEditor to pass `debounced: true` when calling onUpdate
- Ensure CardBodyEditor.contentBinding calls debounced save path

**Done when:**
- CardBodyEditor uses debounced writes
- Typing in body editor no longer writes to disk on every keystroke
- Manual testing confirms responsive typing

## S006: Update CardMetadataEditor Title Field to Use Debounced Saves

**Intent:** Stop writing to disk on every keystroke in title field.

**Work:**
- Update CardMetadataEditor.titleBinding to call debounced save
- Ensure picker bindings (type, status, priority) continue using immediate save
- Ensure tag operations (add, remove) continue using immediate save

**Done when:**
- Title field uses debounced writes
- Pickers and tag operations use immediate writes
- Manual testing confirms responsive title typing and immediate picker updates

## S007: Flush Pending Writes on Card Deselection

**Intent:** Ensure edits are saved before switching to a different card.

**Work:**
- Update CardDetail.onChange(of: viewModel.selectedCard) to call viewModel.flushPendingCardUpdates() before updating editableCard
- Ensure flush completes synchronously before new card loads

**Done when:**
- Selecting different card flushes pending writes
- No edits lost when rapidly switching between cards

## S008: Flush Pending Writes on App Termination

**Intent:** Ensure edits are saved when user quits the app.

**Work:**
- Add `.onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification))` to MainWindow
- Call viewModel.flushPendingCardUpdates() in handler
- Test by quitting app after typing and verifying changes persisted

**Done when:**
- App termination handler exists in MainWindow or App.swift
- Pending writes flush before app quits
- Manual testing confirms edits saved on quit

## S009: Prevent File Watcher from Reloading Edited Card

**Intent:** Avoid disrupting user's work when debounced write triggers file watcher.

**Work:**
- Update HieroglyphsVM.handleFileChange to skip reloading selectedCard if it matches the changed card
- Track whether a card change originated from debounced write vs external change
- Consider adding `lastDebouncedWritePath` to distinguish self-writes from external writes

**Done when:**
- File watcher does not reload currently-edited card when debounced write occurs
- File watcher still reloads card if external tool makes changes
- Manual testing: type in card, wait for debounced write, verify card does not flicker or reload

## S010: Add Tests for Debounced Update Flow

**Intent:** Verify debounced update behavior in ViewModel.

**Work:**
- Add tests to HieroglyphsVMTests for updateCardDebounced
- Test that rapid calls result in single service write
- Test that flushPendingCardUpdates triggers immediate write
- Use mock WorkspaceService to verify write call count

**Done when:**
- Tests exist for updateCardDebounced behavior
- Tests verify coalescing and flush
- All tests pass

## S011: Update Documentation

**Intent:** Reconcile docs with new debouncing behavior.

**Work:**
- Update `.ushabti/docs/viewmodel.md` to document updateCardDebounced and flushPendingCardUpdates methods
- Update `.ushabti/docs/views-ui.md` to document CardDetail, CardBodyEditor, and CardMetadataEditor debouncing behavior
- Document the distinction between immediate writes (pickers, tags) and debounced writes (title, body)

**Done when:**
- ViewModel docs describe debouncing methods and behavior
- Views docs describe which UI interactions use debounced vs immediate writes
- Docs are accurate and complete

## S012: Manual Testing and Verification

**Intent:** Verify typing lag is eliminated and all edge cases work correctly.

**Work:**
- Test typing continuously in card body editor (no lag)
- Test typing continuously in card title field (no lag)
- Test changing picker values (immediate save, no lag)
- Test adding/removing tags (immediate save, no lag)
- Test switching cards rapidly (no lost edits)
- Test quitting app after typing (edits persisted)
- Test external file edit during debounce window (handled correctly)

**Done when:**
- All manual test scenarios pass
- No regressions observed
- Typing is responsive
- All edits reach disk
