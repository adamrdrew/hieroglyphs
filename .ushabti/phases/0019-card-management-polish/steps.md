# Phase 0019 — Steps

## S001: Add removeCardSymlinksFromPlans to PlanProviding protocol

**Intent:** Define the contract for cleaning up plan symlinks when a card is deleted, keeping the protocol as the single source of truth for plan operations.

**Work:**
- Add `func removeCardSymlinksFromPlans(cardSlug: String, projectPath: String) throws` to `PlanProviding` protocol
- This method scans all plan directories under `{projectPath}/plans/` and removes any symlink matching `cardSlug`

**Done when:** `PlanProviding.swift` contains the new method signature with doc comment. Project does not compile yet (implementation missing) — that is expected.

## S002: Implement removeCardSymlinksFromPlans in PlanService

**Intent:** Implement the symlink cleanup logic so that when a card is deleted, all plan references to it are removed from disk.

**Work:**
- In `PlanService`, implement `removeCardSymlinksFromPlans(cardSlug:projectPath:)`
- Enumerate all subdirectories of `{projectPath}/plans/`
- In each plan directory, check if a symlink named `cardSlug` exists
- If it exists, remove it via `FileManager.removeItem(at:)`
- If `plans/` directory does not exist, return silently (no plans to clean up)
- Log warnings for individual removal failures but do not throw — best-effort cleanup

**Done when:** `PlanService` compiles with the new method. Method handles missing `plans/` directory, missing symlinks, and removal errors gracefully.

## S003: Add mock implementation for removeCardSymlinksFromPlans

**Intent:** Ensure the mock service used in tests conforms to the updated protocol.

**Work:**
- In `HieroglyphsVMTests.swift` (or wherever `MockWorkspaceService` / mock plan service lives), add the new method to the mock
- Track calls for test assertions (e.g., `removedCardSlugs: [String]`)

**Done when:** Mock conforms to updated `PlanProviding` protocol. `swift build` succeeds for the test target.

## S004: Test removeCardSymlinksFromPlans

**Intent:** Verify symlink cleanup works correctly across all edge cases.

**Work:**
- In `PlanServiceTests.swift`, add tests:
  - Card symlink exists in one plan: symlink removed
  - Card symlink exists in multiple plans: all symlinks removed
  - Card slug not found in any plan: no error, no-op
  - Plans directory does not exist: no error, no-op
  - Non-symlink files with matching name are not removed (safety check — though this shouldn't happen in practice, skip if implementation uses symlink check)

**Done when:** All tests pass. `swift test` succeeds.

## S005: Wire card deletion in HieroglyphsVM to clean up symlinks

**Intent:** Orchestrate the deletion flow in the VM: remove symlinks first, then trash the card. The VM coordinates between PlanService and WorkspaceService without coupling them.

**Work:**
- In `HieroglyphsVM.deleteSelectedItem()`, before calling `workspaceService.deleteCard()`:
  - Call `planService?.removeCardSymlinksFromPlans(cardSlug:projectPath:)`
  - Catch and log errors from symlink cleanup (do not block deletion if cleanup fails)
- After deletion, also call `loadPlans()` to refresh plan state (symlinks removed)

**Done when:** `deleteSelectedItem()` calls symlink cleanup before card deletion. Compilation succeeds.

## S006: Test VM deletion with symlink cleanup

**Intent:** Verify the VM orchestrates deletion correctly with symlink cleanup.

**Work:**
- In `HieroglyphsVMTests.swift`, add/update tests for `deleteSelectedItem()`:
  - Verify mock plan service's `removeCardSymlinksFromPlans` is called with correct slug and path before `deleteCard`
  - Verify deletion still succeeds if plan service is nil (optional)
  - Verify deletion still succeeds if symlink cleanup throws

**Done when:** Tests pass. Deletion flow is verified end-to-end through mocks.

## S007: Add context menu with delete action to CardListEntry

**Intent:** Give users a right-click affordance to delete a card from the card list.

**Work:**
- In `CardList.swift` (where `CardListEntry` is used in the `ForEach`), add a `.contextMenu` modifier to the `CardListEntry` row
- Context menu contains a single `Button` with:
  - Label: "Delete" with SF Symbol `trash`
  - Role: `.destructive` (renders red)
  - Action: sets a `@State` property to track which card is pending deletion (e.g., `cardPendingDeletion: Card?`)
- The context menu is on the `CardListEntry` row in `CardList`, not inside `CardListEntry` itself (keeps CardListEntry a pure display component)

**Done when:** Right-clicking a card in the list shows a "Delete" context menu item. No deletion happens yet (just sets state).

## S008: Add confirmation alert for card deletion

**Intent:** Prevent accidental deletion by requiring user confirmation before trashing a card.

**Work:**
- In `CardList.swift`, add an `.alert` modifier bound to `cardPendingDeletion`
- Alert title: "Delete Card"
- Alert message: "Are you sure you want to delete '[card title]'? This will move the card to Trash."
- Primary button: "Delete" with `.destructive` role — calls deletion
- Secondary button: "Cancel" — clears `cardPendingDeletion`
- On confirm: set `viewModel.selectedCard` to the pending card, call `viewModel.deleteSelectedItem()`, clear `cardPendingDeletion`

**Done when:** Clicking "Delete" in context menu shows alert. Confirming deletes the card. Cancelling dismisses the alert. Card list refreshes after deletion.

## S009: Fix SidebarCardsItem card count reactivity

**Intent:** Make card counts in the sidebar update when cards change, without requiring app relaunch or project re-selection.

**Work:**
- In `SidebarCardsItem`, add `@Environment(HieroglyphsVM.self) private var viewModel`
- Replace the `@State private var cardCounts` with a computed property that derives counts from `viewModel.cards` when the project matches the selected project
- For the selected project: compute counts from `viewModel.cards` (already loaded and reactive)
- For non-selected projects: keep the existing `onAppear` load behavior (counts update when the project is next selected)
- This approach requires checking if `project` matches `viewModel.selectedProject`

**Done when:** Card counts update immediately when a card is created, deleted, or changes status for the currently selected project. Non-selected project counts load on appearance as before.

## S010: Verify build and all tests pass

**Intent:** Ensure the phase compiles and all tests pass before handoff to Overseer.

**Work:**
- Run `swift build` — must succeed with no errors
- Run `swift test` — all tests must pass
- Manually verify no dead code introduced (L12)

**Done when:** `swift build` and `swift test` both succeed. No compilation warnings related to phase changes.

## S011: Update documentation

**Intent:** Keep `.ushabti/docs/` synchronized with code changes per L14.

**Work:**
- Update `plans-system.md`: document that card deletion now removes plan symlinks, add note about `removeCardSymlinksFromPlans` method
- Update `workspace-service.md`: note that card deletion flow now includes symlink cleanup (orchestrated by VM)
- Update `viewmodel.md`: document the updated `deleteSelectedItem()` flow
- Update `views-ui.md`: document the context menu on card list and confirmation dialog

**Done when:** All affected docs reflect the new behavior. No stale documentation about card deletion or card counts.
