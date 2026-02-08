# Phase 0019 — Card Management Polish

## Intent

Add card deletion UI and fix card count reactivity. Two concrete improvements: (1) Users need a way to delete cards from the UI — the service-layer method exists (`WorkspaceService.deleteCard`) but there is no context menu or confirmation dialog to trigger it. (2) Card counts in the sidebar (`SidebarCardsItem`) only compute on `onAppear` and never update when cards are added, deleted, or change status.

A critical secondary concern: when a card is deleted, any plans that reference it via symlinks become dangling. The deletion flow must clean up plan symlinks before trashing the card directory to prevent data model corruption.

## Scope

### In Scope

- Context menu on `CardListEntry` with a "Delete" option (destructive role)
- Confirmation alert before deletion ("Delete [title]? This will move the card to Trash.")
- On confirm, delete the card via `WorkspaceService.deleteCard` and reload the card list
- Symlink cleanup: before trashing the card, scan `plans/*/` for symlinks matching the card slug and remove them
- Update `WorkspaceService.deleteCard` (or add a new method) to handle symlink cleanup
- Add `removeCardSymlinksFromPlans` to `PlanProviding` protocol and `PlanService`
- Wire the VM's `deleteSelectedItem()` to use the new cleanup flow
- Fix `SidebarCardsItem` card count reactivity so counts update when `viewModel.cards` changes
- Tests for symlink cleanup logic
- Tests for the updated deletion flow in WorkspaceService

### Out of Scope

- Project deletion UI (separate concern)
- Card archiving (different from deletion)
- Plan deletion or plan management changes beyond symlink cleanup
- File watcher changes (the existing watcher already detects card directory removal)
- Any changes to card creation or editing flows

## Constraints

- **L01:** Filesystem is source of truth — deletion uses `trashItem` (already implemented)
- **L06:** Platform leverage — use macOS Trash API, not permanent deletion
- **L09:** Protocol-based services — any new methods must be added to protocols first
- **L11:** Test coverage for all new public APIs
- **L12:** No dead code
- **S-Metz:** Small methods, single responsibility — symlink cleanup is a separate method from card trashing

## Acceptance Criteria

1. Right-clicking a card in `CardList` shows a context menu with "Delete" (SF Symbol: `trash`, destructive role)
2. Selecting "Delete" shows a confirmation alert with the card title
3. Confirming deletion removes all symlinks to the card from `plans/*/` directories
4. Confirming deletion moves the card directory to Trash via `trashItem`
5. Card list updates immediately after deletion (existing `loadCards()` call)
6. Card counts in sidebar update reactively when cards are added, deleted, or change status — without app relaunch
7. All new public methods have tests
8. `swift build` and `swift test` pass

## Risks / Notes

- **Symlink cleanup ordering matters.** Symlinks must be removed before the card directory is trashed. If trashing happens first, the symlinks become dangling (harmless but messy). The implementation should remove symlinks first, then trash.
- **PlanService dependency in deletion flow.** `WorkspaceService.deleteCard` currently has no knowledge of plans. Rather than coupling WorkspaceService to PlanService, the VM should orchestrate: clean up symlinks via PlanService, then trash via WorkspaceService. This keeps services single-responsibility.
- **Card count approach.** The simplest fix is to have `SidebarCardsItem` observe `viewModel.cards` via `.onChange`. This only updates counts for the currently selected project, which is the only project whose cards are loaded. Counts for non-selected projects remain stale until selected — this is acceptable and avoids loading all projects' cards eagerly.
- **Dangling symlinks are already tolerated.** Per plans-system.md, PlanService's `enumerateLinkedCards` already handles dangling symlinks gracefully ("Missing: card-slug" in UI). The cleanup here is a best-effort improvement, not a hard invariant.
