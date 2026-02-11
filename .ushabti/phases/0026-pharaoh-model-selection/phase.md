# Phase 0026: Pharaoh Model Selection at Start

## Intent

Move the model picker from the running/idle state to the not-running state in PharaohView, and pass the selected model through to the Pharaoh process invocation. The model picker is currently useless in the idle state because the model is fixed at server startup and cannot be changed mid-session. The user must select a model before starting Pharaoh.

## Scope

**In scope:**
- Move segmented model Picker from `runningStateView` to `notRunningStateView`
- Update `PharaohProviding` protocol: `start(in:)` → `start(in:model:)`
- Update `PharaohService.start(in:model:)` to include `--model <value>` in process arguments
- Update `PharaohView.startPharaoh()` to pass `viewModel.pharaohModel` to service
- Update tests for protocol and service changes

**Out of scope:**
- Changing model values (opus/sonnet/haiku)
- Adding new models to picker
- Changing status polling or lifecycle behavior
- Modifying HieroglyphsVM.pharaohModel property

## Constraints

- **L09 (Sandi Metz Principles)**: Protocol-based services with focused responsibilities
- **L11 (Test Coverage)**: All public methods must have tests
- **Style**: Protocol changes require corresponding test updates

## Acceptance criteria

- [ ] Model picker appears in `notRunningStateView` between description text and Start button
- [ ] Model picker does NOT appear in `runningStateView` (lines 78-93 removed)
- [ ] `PharaohProviding.start(in:model:)` signature updated with `model` parameter
- [ ] `PharaohService.start(in:model:)` passes `--model <model>` to Pharaoh process
- [ ] `PharaohView.startPharaoh()` passes `viewModel.pharaohModel` to `service.start(in:model:)`
- [ ] All existing tests pass
- [ ] New tests cover model parameter passing

## Risks / notes

None identified. This is a straightforward UI relocation and parameter addition.
