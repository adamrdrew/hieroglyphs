# Steps — Phase 0049: Notification Service Compliance

## S001: Define NotificationDispatching protocol

**Intent:** Establish the abstraction that all consumers depend on, enabling dependency injection and testability (L09).

**Work:**
- Create `Sources/Hieroglyphs/Services/NotificationDispatching.swift`
- Define protocol `NotificationDispatching` with methods:
  - `func setUp()`
  - `func notifyPhaseCompleted(projectName: String, phaseName: String, turns: Int, costUsd: Double)`
  - `func notifyPhaseFailed(projectName: String, phaseName: String, error: String, turns: Int, costUsd: Double)`
- Mark methods with appropriate isolation annotations to match the current `nonisolated` pattern on the concrete methods

**Done when:** Protocol file exists with all three method signatures. Builds cleanly.

---

## S002: Conform NotificationService to NotificationDispatching

**Intent:** Make the existing concrete service implement the new protocol without changing its behavior.

**Work:**
- Add `: NotificationDispatching` conformance to `NotificationService`
- Remove `static let shared` singleton
- Remove the `override private init()` — make init internal (or keep private if environment key factory handles creation)
- Replace `NSApplication.shared.activate(ignoringOtherApps: true)` with `NSApplication.shared.activate()` (deprecated API fix)
- Verify the class remains `@MainActor` and conforms to `UNUserNotificationCenterDelegate` (implementation detail, not on protocol)

**Done when:** `NotificationService` conforms to `NotificationDispatching`. No `static let shared` exists. Deprecated API call is replaced. Builds cleanly.

---

## S003: Create EnvironmentKey for notification service

**Intent:** Enable SwiftUI environment injection following the project's established pattern.

**Work:**
- Create `Sources/Hieroglyphs/Services/NotificationServiceEnvironmentKey.swift`
- Define `NotificationServiceEnvironmentKey: EnvironmentKey` with `defaultValue: NotificationDispatching? = nil`
- Add `EnvironmentValues` extension with `notificationService` computed property
- Follow the exact pattern used in `PharaohServiceEnvironmentKey.swift`

**Done when:** Environment key file exists. Builds cleanly.

---

## S004: Inject notification service in App.swift

**Intent:** Wire the concrete service into the SwiftUI environment so all views can access it via protocol.

**Work:**
- In `App.swift`, create a `NotificationService()` instance alongside the other services
- Store it as `private let notificationService: NotificationDispatching`
- Call `notificationService.setUp()` in init (replacing `NotificationService.shared.setUp()`)
- Add `.environment(\.notificationService, notificationService)` to the view hierarchy
- Add `.environment(\.notificationService, notificationService)` to the MenuBarExtra as well

**Done when:** `App.swift` creates, stores, and injects the notification service. No reference to `NotificationService.shared` remains anywhere in the file. Builds cleanly.

---

## S005: Update PharaohMenuBar to use injected service

**Intent:** Remove the direct singleton access and use the environment-injected protocol instead (L09 compliance).

**Work:**
- Add `@Environment(\.notificationService) private var notificationService` to `PharaohMenuBar`
- Update `checkForTransition` to use the injected service instead of `NotificationService.shared`
- Guard against nil notification service (same pattern as `guard let pharaohService` on line 50)

**Done when:** `PharaohMenuBar` no longer references `NotificationService.shared`. All notification dispatch goes through the injected protocol. Builds cleanly.

---

## S006: Extract transition detection for testability

**Intent:** Make the transition-detection logic testable without requiring a live `PharaohMenuBar` view.

**Work:**
- Extract `checkForTransition(from:to:project:sourceDirectory:)` logic into a testable location. Recommended approach: a small struct or free function in a utility or service file that takes a `NotificationDispatching` parameter.
- The signature should be something like: `func detectPharaohTransition(from previous: PharaohStatus?, to current: PharaohStatus, projectName: String, phaseName: String?, notifier: NotificationDispatching)`
- Alternatively, a `PharaohTransitionDetector` struct with the notification service injected.
- `PharaohMenuBar.checkForTransition` should delegate to this extracted logic.
- The extracted function/type must be internal (not private) so tests can access it.

**Done when:** Transition-detection logic is callable from tests with a mock `NotificationDispatching`. `PharaohMenuBar` delegates to the extracted logic. Builds cleanly.

---

## S007: Add previousStatuses pruning

**Intent:** Prevent unbounded growth of `previousStatuses` dictionary when projects are removed from the workspace.

**Work:**
- At the end of `loadRunningPlans()`, after iterating all projects, collect the set of source directories that were visited.
- Remove any key from `previousStatuses` that is not in the visited set.
- This is a simple set-difference operation on dictionary keys.

**Done when:** `previousStatuses` entries for removed projects are pruned on each poll cycle. Builds cleanly.

---

## S008: Write tests for NotificationDispatching

**Intent:** Satisfy L11 — every public API method must have tests.

**Work:**
- Create `Tests/HieroglyphsTests/NotificationServiceTests.swift`
- Create a `MockNotificationService` conforming to `NotificationDispatching` that records calls (method name, arguments) without touching `UNUserNotificationCenter`
- Test the extracted transition-detection logic:
  - busy -> done calls `notifyPhaseCompleted` with correct project name, phase name, turns, cost
  - busy -> blocked calls `notifyPhaseFailed` with correct project name, phase name, error, turns, cost
  - busy -> idle calls nothing
  - idle -> busy calls nothing
  - nil -> busy calls nothing (first observation, no transition)
  - busy -> busy calls nothing (no transition)
- Test that `MockNotificationService.setUp()` records the call
- Test that `MockNotificationService.notifyPhaseCompleted(...)` records arguments correctly
- Test that `MockNotificationService.notifyPhaseFailed(...)` records arguments correctly

**Done when:** Tests exist and pass. All transition cases are covered. All public protocol methods are tested via mock. `swift test` passes.

---

## S009: Verify no dead code (L12)

**Intent:** Ensure the refactoring did not leave unused symbols, imports, or commented-out code.

**Work:**
- Verify `NotificationService.shared` is gone and no references to it remain anywhere in the codebase
- Verify no unused imports were introduced
- Verify no commented-out code blocks exist in modified files
- Verify the old `override private init()` pattern is removed
- Search for any remaining references to the singleton pattern

**Done when:** No dead code related to the old singleton pattern exists. No unused imports. No commented-out code.

---

## S010: Build and test verification

**Intent:** Confirm the full build and test suite pass (L19, L11).

**Work:**
- Run `./Scripts/build-app.sh` and verify exit code 0
- Run `swift test` and verify all tests pass
- Fix any compilation errors or test failures before proceeding

**Done when:** `./Scripts/build-app.sh` exits 0. `swift test` exits 0 with no failures.

---

## S011: Update documentation

**Intent:** Satisfy L14/L16 — docs must be reconciled with code changes.

**Work:**
- Update `.ushabti/docs/pharaoh-integration.md` to add a section documenting:
  - `NotificationDispatching` protocol and its methods
  - `NotificationService` concrete implementation (UNUserNotificationCenter delegate, permission request)
  - Environment key injection pattern (`NotificationServiceEnvironmentKey`)
  - Transition detection: where it lives, how it works, what transitions trigger notifications
  - How `PharaohMenuBar` uses the injected service
  - `previousStatuses` pruning behavior
- Ensure the documentation section is placed logically near the existing PharaohMenuBar documentation

**Done when:** `pharaoh-integration.md` documents the notification service architecture, injection, transition detection, and pruning. Documentation is accurate and complete.
