# Phase 0032: Multi-Select Add Cards to Plan

card: multi-select-for-add-card-to-plan

## Intent

Enable selecting multiple cards at once when adding cards to a plan, eliminating the need to open the AddCardToPlanSheet repeatedly. The Add button will clearly communicate how many cards will be added, and a batch addition method will reduce filesystem I/O overhead by reloading plans once at the end instead of once per card.

## Scope

**In scope:**
- Change `AddCardToPlanSheet.swift` from single-select to Set-based multi-select
- Update Add button label to show count of selected cards
- Add `addCardsToPlan(cardSlugs:planSlug:)` batch method to `HieroglyphsVM`
- Call `loadPlans()` once at the end of batch addition, not once per card
- Write tests for batch addition method

**Out of scope:**
- Changes to PlanDetail view
- Changes to card list views or other modals
- Filtering logic (already correct — operates on card array, not selection)
- Visual treatment of already-linked cards (already filtered out by `availableCards`)

## Constraints

- **L09 (Sandi Metz):** Keep batch method focused on single responsibility (loop through slugs, call service, reload once)
- **L11 (Test Coverage):** Test the batch add method
- **L18 (Design Is How It Works):** Add button communicates how many cards will be added. Disabled when selection is empty.
- **Style: Controls and Affordances** — Clear labeling, disabled when nothing selected

## Acceptance Criteria

1. `AddCardToPlanSheet` uses `Set<Card.ID>` for selection binding
2. Add button label shows count when multiple cards selected (e.g., "Add 3 Cards" or "Add (3)")
3. Add button is disabled when `selectedCards.isEmpty`
4. Clicking Add calls batch method that adds all selected cards then dismisses sheet
5. `HieroglyphsVM.addCardsToPlan(cardSlugs:planSlug:)` method exists and calls service N times, then calls `loadPlans()` once
6. Tests verify batch addition method calls service correct number of times
7. Already-linked cards remain filtered out by existing `availableCards` computed property

## Risks / Notes

- SwiftUI List multi-select on macOS requires `Set<Card.ID>`, not `Set<Card>` (Card is not Hashable by ID alone)
- Existing search and filter logic is unaffected — it operates on `filteredCards` array, not on selection
- Button label wording can be "Add (N)" for brevity or "Add N Cards" for clarity — prefer clarity
