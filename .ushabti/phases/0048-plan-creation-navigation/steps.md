# Steps

## S001: Review current createPlan implementation

**Intent:** Understand the current flow and identify the exact insertion point for navigation logic.

**Work:**
- Read HieroglyphsVM.createPlan() method
- Identify where plan creation completes successfully
- Verify auto-selection logic for newly created plan
- Confirm selectedSection structure for plans view

**Done when:** Code review complete and insertion point identified.

## S002: Add navigation to createPlan method

**Intent:** Switch to plan view immediately after successful plan creation.

**Work:**
- Add `self.selectedSection = .plans(selectedProject)` after plan creation succeeds
- Position after `loadPlans()` call and before auto-selection logic
- Ensure navigation happens for both plan-from-card and plan-from-list creation paths
- Preserve existing error handling

**Done when:** Navigation code added to createPlan method.

## S003: Update HieroglyphsVMTests

**Intent:** Verify that createPlan sets selectedSection to plans view.

**Work:**
- Add test case: `testCreatePlanSwitchesToPlansView()`
- Mock successful plan creation
- Call createPlan with sourceCard
- Assert selectedSection is `.plans(project)`
- Add test case for plan creation without sourceCard
- Verify existing tests still pass

**Done when:** Tests added and all tests pass.

## S004: Verify build passes

**Intent:** Ensure code compiles successfully.

**Work:**
- Run `./Scripts/build-app.sh`
- Fix any compilation errors

**Done when:** Build script exits 0.

## S005: Manual testing

**Intent:** Verify the user experience matches acceptance criteria.

**Work:**
- Launch app
- Select a project
- Create a card
- Right-click card → "Create Plan"
- Verify: App switches to plan view immediately
- Verify: NewPlanSheet modal appears
- Enter plan title and save
- Verify: Plan view shows new plan selected
- Test toolbar "Create Plan" button from CardDetail
- Test creating plan from plan list toolbar button

**Done when:** All acceptance criteria verified manually.
