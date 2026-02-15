# Steps

## S001: Wrap conditional view in Group

**Intent:** Enable view modifiers to attach to a concrete view type rather than the abstract result of an if/else block.

**Work:**
- Wrap lines 16-28 (the `if runningPlans.isEmpty { } else { }` block) in a `Group { }` container
- Preserve all existing view structure and content unchanged
- The `.onAppear` and `.onReceive` modifiers (lines 29-34) will then attach to the Group

**Done when:** The view body has `Group { if runningPlans.isEmpty { ... } else { ... } }` with modifiers on the Group.

## S002: Remove planService from guard-let

**Intent:** Eliminate invalid optional binding of a non-Optional environment value.

**Work:**
- Change line 43 from `guard let planService, let pharaohService else { return }` to `guard let pharaohService else { return }`
- `planService` has a non-Optional default value from `PlanServiceKey` and does not require optional binding
- Only `pharaohService` (Optional default `nil`) requires the guard

**Done when:** Line 43 reads `guard let pharaohService else { return }` with no reference to `planService`.

## S003: Verify build succeeds

**Intent:** Confirm that both fixes resolve the compilation errors and the app builds cleanly.

**Work:**
- Run `./Scripts/build-app.sh` from the repository root
- Verify exit code 0 and no compilation errors in output
- Confirm `App.swift` scene body no longer produces diagnostic errors

**Done when:** `./Scripts/build-app.sh` exits 0 with clean build output.

## S004: Update pharaoh-integration.md to reflect MenuBarExtra visibility

**Intent:** Reconcile documentation with code changes - MenuBarExtra is now always present, not conditionally shown.

**Work:**
- Update `.ushabti/docs/pharaoh-integration.md` line 215
- Change from "Only shown when workspace is loaded (`viewModel.workspacePath != nil`)" to "Always present in menu bar"
- Add clarification that PharaohMenuBar handles empty state internally when no workspace is loaded or no plans are running
- Update any other references to conditional MenuBarExtra visibility if found

**Done when:** Documentation accurately reflects that MenuBarExtra is always present and PharaohMenuBar manages empty state display.
