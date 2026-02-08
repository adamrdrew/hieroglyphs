# Phase 0020: UX Improvements

## Intent

Implement five focused quality-of-life improvements to make Hieroglyphs usable for day-to-day project management. These enhancements address existing gaps in card list filtering, sorting, plan-card navigation, and status cascading. All components and backing logic already exist — the work consists primarily of wiring existing components into the UI and extending one existing service method.

## Scope

**In scope:**

1. **Filter Card List** — Wire `CardFilterBar` into `CardList` toolbar with show/hide toggle
2. **Sort Card List** — Wire `CardSortPopover` into `CardList` toolbar with popover presentation
3. **Card Management Buttons in Plan** — Add visible action buttons (view, remove) to linked card rows in `PlanDetail`
4. **Filter Card Selection for Plan** — Add search and filter capabilities to `AddCardToPlanSheet`
5. **Card Status Cascading** — Generalize status cascade from plan status changes to cover all plan statuses (not just `.done`)

**Out of scope:**

- Filter/sort state persistence to disk (in-memory only for this phase)
- Advanced filtering (e.g., date ranges, custom queries)
- Keyboard navigation improvements
- Card reordering within plans
- Plan templates or bulk operations

## Constraints

**Laws:**

- **L01 (Filesystem as Source of Truth):** Card status updates must write to disk immediately
- **L02 (Opinionated on Write, Laissez-Faire on Read):** Status mapping writes prescribed values but tolerates any status on read
- **L09 (Sandi Metz Principles):** Small methods, protocol-based services, dependency injection
- **L10 (Design Consistency with TakeNote):** Follow existing toolbar patterns, SF Symbols, popover anchoring
- **L11 (Test Coverage):** Public API methods require tests

**Style:**

- SOLID principles throughout
- Composition over inheritance
- Small, focused view components
- No regex (banned)
- Clarity over brevity in naming

**Existing Documentation:**

Consult `.ushabti/docs/viewmodel.md`, `.ushabti/docs/views-ui.md`, and `.ushabti/docs/plans-system.md` for current architecture and patterns.

## Acceptance Criteria

1. **Filter Toggle:** Clicking toolbar button in `CardList` shows/hides `CardFilterBar` inline. Button indicates active filter state visually.
2. **Sort Popover:** Clicking toolbar button in `CardList` presents `CardSortPopover` as popover anchored to button.
3. **Plan Card Buttons:** Each linked card row in `PlanDetail` shows "View Card" and "Remove from Plan" icon buttons with tooltips.
4. **Card Selection Filter:** `AddCardToPlanSheet` includes search field and status/type/priority filter menus that filter the displayed card list.
5. **Status Cascade:** Changing plan status updates all linked cards to corresponding card status (planning→backlog, ready→todo, done→done).
6. **Tests Pass:** All existing tests continue to pass. New public methods have test coverage.
7. **Lint Passes:** No new lint violations.
8. **Docs Updated:** If any documented system changes behavior, docs are reconciled.

## Risks / Notes

**Risk:** Filter/sort state is ephemeral (not persisted). User expectations may differ. This is acceptable for initial implementation — persistence can be added in future phase.

**Note:** Filter bar component already exists and is fully functional. This phase only wires it into the toolbar — no component logic changes needed.

**Note:** Status mapping is opinionated: plan status dictates card status on change. Manual card status edits remain possible and are not validated or reverted.

**Deferred:** Filter/sort persistence, advanced search, keyboard shortcuts for filter/sort toggles.
