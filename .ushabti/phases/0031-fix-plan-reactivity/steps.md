# Steps

## S001: Add refreshSelectedPlan helper

**Intent:** Create a private helper method that refreshes selectedPlan to point to the updated Plan in the plans array.

**Work:**
- Add private `refreshSelectedPlan()` method to HieroglyphsVM
- If `selectedPlan` is not nil, find the plan with matching slug in the `plans` array
- If found, set `selectedPlan` to the updated Plan object
- If not found (plan was deleted), leave `selectedPlan` as-is (will be nil'd by other logic)

**Done when:** Method exists, follows the pattern from `updateProject()`, and is documented.

## S002: Call refreshSelectedPlan in addCardToPlan

**Intent:** Ensure selectedPlan is refreshed after adding a card to a plan.

**Work:**
- In `addCardToPlan()`, after the `loadPlans()` call on line 473, add `refreshSelectedPlan()` call
- Verify the flow: mutate plan → reload plans → refresh selection

**Done when:** `addCardToPlan()` calls `refreshSelectedPlan()` after `loadPlans()`.

## S003: Call refreshSelectedPlan in removeCardFromPlan

**Intent:** Ensure selectedPlan is refreshed after removing a card from a plan.

**Work:**
- In `removeCardFromPlan()`, after the `loadPlans()` call on line 503, add `refreshSelectedPlan()` call
- Verify the flow: mutate plan → reload plans → refresh selection

**Done when:** `removeCardFromPlan()` calls `refreshSelectedPlan()` after `loadPlans()`.

## S004: Call refreshSelectedPlan in updatePlanStatus

**Intent:** Ensure selectedPlan is refreshed after changing plan status.

**Work:**
- In `updatePlanStatus()`, after the `loadPlans()` call on line 533, add `refreshSelectedPlan()` call
- This method also calls `loadCards()` (line 534) to refresh cascaded card status changes
- Refresh happens after both loads complete

**Done when:** `updatePlanStatus()` calls `refreshSelectedPlan()` after `loadPlans()`.

## S005: Test addCardToPlan refreshes selectedPlan

**Intent:** Verify that adding a card to a plan updates selectedPlan with fresh data.

**Work:**
- Add test to HieroglyphsVMTests
- Set up: create plan, select it, mock service to add card to plan
- Execute: call `addCardToPlan()`
- Verify: `selectedPlan?.linkedCardSlugs` contains the new card slug
- Verify the plan object identity changed (new instance from reload)

**Done when:** Test passes, confirms selectedPlan is refreshed.

## S006: Test removeCardFromPlan refreshes selectedPlan

**Intent:** Verify that removing a card from a plan updates selectedPlan with fresh data.

**Work:**
- Add test to HieroglyphsVMTests
- Set up: create plan with linked card, select it, mock service to remove card
- Execute: call `removeCardFromPlan()`
- Verify: `selectedPlan?.linkedCardSlugs` no longer contains the removed card slug
- Verify the plan object identity changed (new instance from reload)

**Done when:** Test passes, confirms selectedPlan is refreshed.

## S007: Test updatePlanStatus refreshes selectedPlan

**Intent:** Verify that changing plan status updates selectedPlan with fresh status.

**Work:**
- Add test to HieroglyphsVMTests
- Set up: create plan with status `.planning`, select it, mock service to change status
- Execute: call `updatePlanStatus(plan: plan, status: .ready)`
- Verify: `selectedPlan?.status` is `.ready`
- Verify the plan object identity changed (new instance from reload)

**Done when:** Test passes, confirms selectedPlan is refreshed.

## S008: Verify all tests and lint pass

**Intent:** Ensure no regressions and code quality standards met.

**Work:**
- Run `swift test` to verify all tests pass
- Run lint to verify no violations
- Verify no dead code (check for any workaround `.id()` modifiers or manual refreshes)

**Done when:** Tests pass, lint passes, no dead code found.

## S009: Update viewmodel.md documentation

**Intent:** Document the new refreshSelectedPlan helper and its usage.

**Work:**
- Add section documenting `refreshSelectedPlan()` method in `.ushabti/docs/viewmodel.md`
- Note that it's called after plan mutations to keep selectedPlan synchronized
- Reference L17 as rationale

**Done when:** Documentation updated with clear description of the helper method and its purpose.
