# Steps

## S001: Add isStarting state and starting UI

**Intent:** Introduce the `isStarting` state flag and the ProgressView loading UI that shows while the server is starting.

**Work:**
- Add `@State private var isStarting: Bool = false` to `PharaohView`
- In `notRunningStateView`, add a conditional: if `isStarting` is true, show a VStack with a ProgressView and Text("Starting Pharaoh…")
- If `isStarting` is false, show the existing VStack with description, model picker, error display, and Start button
- The ProgressView should use default circular style with the label below it

**Done when:** The view compiles and shows a ProgressView with "Starting Pharaoh…" when `isStarting` is true, and shows the normal Start UI when `isStarting` is false.

---

## S002: Set isStarting when Start button is clicked

**Intent:** Set the `isStarting` flag to true immediately when the user clicks the Start button, before calling `service.start()`.

**Work:**
- In `startPharaoh()`, add `isStarting = true` as the first line of the method (before the guard check)
- This ensures the ProgressView appears immediately when the user clicks Start

**Done when:** Clicking the Start button immediately shows the ProgressView and hides the Start button and model picker.

---

## S003: Clear isStarting when polling detects running state

**Intent:** Clear the `isStarting` flag when the polling loop detects that the server has successfully started (transitioned from `.notRunning` to any running state).

**Work:**
- In `updateStatus()`, after updating `status`, check if the new status is not `.notRunning` and `isStarting` is true
- If so, set `isStarting = false`
- This transitions the view from the loading state to the running state view

**Done when:** After clicking Start and waiting a few seconds, the ProgressView disappears and the running state view appears when the server starts.

---

## S004: Clear isStarting on error and show alert

**Intent:** Clear the `isStarting` flag when `start()` throws an error, and show a modal alert instead of the inline orange box.

**Work:**
- In `startPharaoh()`, in the `catch` block, set `isStarting = false`
- In the `catch` block, set `startError` to the error message (keep this for now, will remove in next step)
- Add a new `@State private var showStartErrorAlert: Bool = false` flag
- In the `catch` block, set `showStartErrorAlert = true`
- Add an `.alert()` modifier to the view with title "Failed to Start Pharaoh", message from `startError`, and an OK button that dismisses the alert
- The alert should be presented when `showStartErrorAlert` is true

**Done when:** When `start()` fails (e.g., invalid directory), the ProgressView disappears, an alert appears with the error message, and after dismissing the alert, the Start button and model picker are visible again.

---

## S005: Remove inline orange error box

**Intent:** Remove the subtle inline error display now that start errors are shown via alert.

**Work:**
- Remove the `if let error = startError` block from `notRunningStateView`
- Remove the `@State private var startError: String?` declaration (no longer needed — the alert presents the error)
- In `startPharaoh()`, instead of setting `startError`, set a new `@State private var startErrorMessage: String = ""` for the alert message
- Update the alert to use `startErrorMessage` instead of `startError`

**Done when:** The inline orange error box no longer appears. Start errors are shown only via the alert. The view compiles and runs correctly.

---

## S006: Test edge cases manually

**Intent:** Verify all edge cases and state transitions work correctly.

**Work:**
- **Test 1:** Click Start with valid source directory → ProgressView shows → server starts → running state view appears
- **Test 2:** Click Start with invalid source directory (simulate by temporarily removing sourceDirectory) → ProgressView shows → alert appears with error message → dismiss alert → Start button visible again
- **Test 3:** Click Start → immediately switch to a different project → verify the `.task` is cancelled and no stale state remains
- **Test 4:** Click Start → while ProgressView is showing, verify that the Start button is not visible (cannot double-start)
- **Test 5:** Start server successfully → stop server → verify Start button is visible again and `isStarting` is false

**Done when:** All five test cases pass. The loading state, error alert, and state transitions work correctly in all scenarios.

---

## S007: Update pharaoh-integration.md for new startup UX

**Intent:** Reconcile documentation with the new loading state and error presentation changes.

**Work:**
- Update `.ushabti/docs/pharaoh-integration.md` lines 220-226 (Not Running State section)
- Add bullet point describing loading state: "Loading state (while starting): ProgressView with 'Starting Pharaoh…' label, Start button and model picker hidden"
- Update error display bullet: "Start error alert shown via modal with title 'Failed to Start Pharaoh' and error message, dismissible with OK button"
- Remove reference to inline error display (no longer exists)

**Done when:** pharaoh-integration.md accurately describes the startup loading state, alert-based error presentation, and control visibility during startup.
