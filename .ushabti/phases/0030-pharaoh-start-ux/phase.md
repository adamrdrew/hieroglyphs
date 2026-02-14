# Phase 0030: Pharaoh Start UX Improvements

card: visual-feedback-when-starting-pharaoh
card: show-error-if-pharaoh-fails-to-start

## Intent

Provide clear visual feedback during Pharaoh server startup and surface start failures prominently. Currently, clicking Start leaves the UI unchanged until the polling loop detects the running server (several seconds later), and start errors are shown subtly in an inline orange box. Users need to know: (1) something is happening when they click Start, (2) when the operation completes, and (3) if it failed.

This phase introduces an `isStarting` loading state, replaces the subtle error box with a modal alert, and prevents double-starts by hiding the Start button and model picker while starting.

## Scope

**In scope:**
- Add `isStarting` state flag to `PharaohView`
- Show `ProgressView` with "Starting Pharaoh…" label when `isStarting` is true
- Hide Start button and model picker while `isStarting` is true
- Clear `isStarting` when polling detects a running state (any status except `.notRunning`)
- Clear `isStarting` when `startPharaoh()` throws an error
- Replace inline orange box error display with `.alert()` on start failure
- Keep Start button and model picker visible after dismissing error alert (user can retry)
- Preserve existing polling, auto-completion, and error detection logic

**Out of scope:**
- Changes to `PharaohService` or `PharaohProviding` protocol
- Changes to `PharaohActivityStreamView` or other Pharaoh views
- Changes to the running state view
- Changes to polling interval
- Changes to server info display or enriched status metrics

## Constraints

**Laws:**
- **L17 (UI State Correctness):** Async operations must provide visual feedback and surface errors visibly.
- **L18 (Design Is How It Works):** Every interactive element communicates its state. If it cannot be activated, disable or hide it. If an operation is in progress, tell the user. If it failed, tell the user.
- **L09 (Sandi Metz):** Small methods, single responsibility. Keep the starting state logic clean and focused.
- **L11 (Test Coverage):** Test any new public methods. No new service methods are added, so no new tests required for this phase.

**Style:**
- **Async Operation Feedback:** Model as explicit state (.idle, .loading, .loaded, .failed). While loading: show ProgressView, disable triggering control.
- **Controls and Affordances:** Disabled states, destructive action confirmation, loading states.
- **Platform Nativeness:** Use system controls (ProgressView, Alert), system colors, system fonts.

## Acceptance Criteria

1. When the user clicks "Start Pharaoh":
   - The Start button and model picker immediately disappear
   - A ProgressView with label "Starting Pharaoh…" appears in their place
   - The UI remains in this state until either the server starts successfully or the start operation throws an error

2. When the polling loop detects a running state (`.idle`, `.busy`, `.done`, or `.blocked`):
   - `isStarting` is cleared
   - The view transitions to `runningStateView` as normal

3. When `start()` throws an error:
   - `isStarting` is cleared
   - An alert with title "Failed to Start Pharaoh" and the error message appears
   - After dismissing the alert, the Start button and model picker are visible again (user can retry)

4. No double-starts are possible:
   - While `isStarting` is true, the Start button is not visible
   - The user cannot trigger multiple process spawns

5. The existing inline orange error box is removed (replaced by alert)

6. All existing functionality is preserved:
   - Status polling continues to work
   - Auto-completion of plans works
   - Error detection for busy → blocked works
   - Server info display works
   - Stop button works

## Risks / Notes

**Loading state timing:** The ProgressView will show for several seconds (npm resolution + Node.js startup time). This is expected and communicates accurately to the user that the operation is in progress.

**Error presentation:** Using an alert for start failures is appropriate — the user initiated the action and should receive clear modal feedback. This is more prominent than the current inline orange box.

**State synchronization:** `isStarting` must be cleared in two places: (1) when `updateStatus()` detects a running state, and (2) when `startPharaoh()` catches an error. Both paths are required to prevent the ProgressView from showing indefinitely.

**No changes to service layer:** The `PharaohService.start()` method already handles process spawning correctly. This phase is purely a UI layer change.
