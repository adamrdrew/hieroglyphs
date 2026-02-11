# Steps

## S001: Update PharaohProviding protocol

**Intent:** Change the `start(in:)` method signature to `start(in:model:)` to accept a model parameter.

**Work:**
- Open `Sources/Hieroglyphs/Services/PharaohProviding.swift`
- Update the `start(in:)` method signature to `start(in:model:)` with `model: String` parameter
- Update the method documentation to describe the model parameter

**Done when:** `PharaohProviding` protocol has `start(in:model:)` signature with documentation.

## S002: Update PharaohService implementation

**Intent:** Accept the model parameter and pass it to the Pharaoh process as `--model <value>`.

**Work:**
- Open `Sources/Hieroglyphs/Services/PharaohService.swift`
- Update `start(in:)` to `start(in:model:)` matching the protocol
- Update the process arguments from `"npx @adamrdrew/pharaoh serve"` to `"npx @adamrdrew/pharaoh serve --model \(model)"`

**Done when:** `PharaohService.start(in:model:)` includes `--model` flag in process arguments.

## S003: Move model picker to not-running state

**Intent:** Relocate the segmented picker from running/idle state to not-running state.

**Work:**
- Open `Sources/Hieroglyphs/Views/Pharaoh/PharaohView.swift`
- In `notRunningStateView`, add the model picker VStack (Text + Picker) after the description text and before the error display
- Remove the model picker block from `runningStateView` (lines 78-93: the `if status.isIdle { ... }` block containing the picker)

**Done when:** Picker appears in `notRunningStateView` and is removed from `runningStateView`.

## S004: Wire model selection through to service

**Intent:** Pass the selected model from HieroglyphsVM through to PharaohService.start().

**Work:**
- In `PharaohView.swift`, update `startPharaoh()` method
- Change `try service.start(in: sourceDirectory)` to `try service.start(in: sourceDirectory, model: viewModel.pharaohModel)`

**Done when:** `startPharaoh()` passes `viewModel.pharaohModel` to `service.start(in:model:)`.

## S005: Update PharaohService tests

**Intent:** Update existing tests to use the new `start(in:model:)` signature.

**Work:**
- Open `Tests/HieroglyphsTests/Services/PharaohServiceTests.swift`
- Update all calls to `start(in:)` to `start(in:model:)` with a model value (e.g., "opus")
- Add a new test `testStartWithModelFlag()` that verifies the model is included in process arguments

**Done when:** All PharaohService tests pass and include model parameter coverage.

## S006: Fix pre-existing test failures

**Intent:** Fix PhaseServiceTests and HieroglyphsVMTests that reference outdated PhaseStatus enum values.

**Work:**
- Update `Tests/HieroglyphsTests/PhaseServiceTests.swift` to use current PhaseStatus values (planned, building, review, complete)
- Update `Tests/HieroglyphsTests/HieroglyphsVMTests.swift` to use current PhaseStatus values (planned, building, review, complete)
- Replace `.active` with `.building`, `.green` with `.complete`, `.yellow` and `.red` with `.review`

**Done when:** All test files compile without PhaseStatus-related errors.

## S007: Run full test suite

**Intent:** Verify no regressions and all tests pass.

**Work:**
- Run `swift test` from project root
- Verify all tests pass
- Verify build succeeds with `swift build`

**Done when:** Test suite and build are GREEN.

## S008: Update pharaoh-integration.md to reflect model picker relocation and service signature change

**Intent:** Reconcile documentation with code changes made in this phase.

**Work:**
- Update line 44 in `.ushabti/docs/pharaoh-integration.md` from `start(in directory: String) throws` to `start(in directory: String, model: String) throws`
- Update line 167 to remove "visible only when idle" reference since picker is now in not-running state
- Update "Model Selection" section (lines 235-245) to reflect that the picker appears in the not-running state, not the idle state
- Update line 278 in "Starting Pharaoh" process description to include model parameter

**Done when:** All references to model picker location and `start` method signature are accurate in pharaoh-integration.md.
