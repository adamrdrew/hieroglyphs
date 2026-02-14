# Steps

## S001: Change AddCardToPlanSheet to Set-based selection

**Intent:** Replace single selection binding with Set-based multi-select to enable selecting multiple cards at once.

**Work:**
- In `AddCardToPlanSheet.swift`, replace `@State private var selectedCard: Card?` with `@State private var selectedCards: Set<Card.ID> = []`
- Update `List` selection binding from `$selectedCard` to `$selectedCards`
- Do NOT change the List row view — SwiftUI handles multi-select automatically with Set binding

**Done when:** `AddCardToPlanSheet` has a `selectedCards` Set property and List is bound to it. Build succeeds.

## S002: Update Add button label and disabled state

**Intent:** Communicate how many cards will be added and disable when selection is empty.

**Work:**
- Update Add button label to show count:
  - If `selectedCards.count == 1`: "Add Card"
  - If `selectedCards.count > 1`: "Add \(selectedCards.count) Cards"
  - If `selectedCards.isEmpty`: "Add" (will be disabled)
- Update Add button `.disabled()` modifier to check `selectedCards.isEmpty` instead of `selectedCard == nil`

**Done when:** Add button label reflects selection count. Button is disabled when no cards selected. Build succeeds.

## S003: Add batch addition method to HieroglyphsVM

**Intent:** Reduce filesystem I/O by adding all cards to the plan in a single transaction, reloading plans only once at the end.

**Work:**
- Add `addCardsToPlan(cardSlugs: [String], planSlug: String)` method to `HieroglyphsVM`
- Method iterates through `cardSlugs`, calling `planService?.addCardToPlan(cardSlug:planSlug:projectPath:)` for each
- Call `loadPlans()` once after all additions complete
- Call `refreshSelectedPlan()` once after all additions complete
- Keep method under 10 lines (iterate, add, reload)

**Done when:** `HieroglyphsVM.addCardsToPlan(cardSlugs:planSlug:)` exists and follows the pattern. Build succeeds.

## S004: Update AddCardToPlanSheet to call batch method

**Intent:** Wire the multi-select UI to the batch addition method.

**Work:**
- Replace `addCard()` method implementation in `AddCardToPlanSheet`
- Instead of calling `viewModel.addCardToPlan(cardSlug:planSlug:)` for single card, build array of slugs from `selectedCards`
- Call `viewModel.addCardsToPlan(cardSlugs:planSlug:)` with array of slugs
- Map `selectedCards` Set to slugs by filtering `filteredCards` for matching IDs and extracting `.slug`
- Dismiss sheet after batch add completes

**Done when:** Clicking Add with multiple cards selected adds all of them and dismisses sheet. Manual testing shows all selected cards appear in plan.

## S005: Write tests for batch addition method

**Intent:** Verify batch addition calls service correct number of times and reloads plans once.

**Work:**
- Add test case to `HieroglyphsVMTests.swift`: `test_addCardsToPlan_callsServiceForEachCard`
- Create mock `PlanProviding` that tracks call count for `addCardToPlan(cardSlug:planSlug:projectPath:)`
- Call `addCardsToPlan(cardSlugs:planSlug:)` with 3 card slugs
- Assert service was called 3 times
- Assert `loadPlans()` was called once (verify via plans array change or mock service call count)

**Done when:** Test exists and passes. `swift test` succeeds.

## S006: Manual testing and verification

**Intent:** Verify the feature works end-to-end in the running app.

**Work:**
- Run the app via `swift run`
- Create a plan, open AddCardToPlanSheet
- Select multiple cards (cmd-click or shift-click)
- Verify Add button shows correct count
- Click Add and verify all selected cards appear in PlanDetail
- Verify already-linked cards do not appear in the sheet (existing behavior preserved)

**Done when:** Multi-select works as expected. All selected cards are added to plan in a single action.
