# Phase 0049 — Notification Service Compliance

## Intent

Bring the `NotificationService` (introduced on the `notifications-on-complete-job` branch) into full compliance with the project's laws and style conventions. The service currently works but violates L09 (dependency inversion), L11 (test coverage), and multiple style rules (protocol pattern, singleton access, deprecated API). This Phase remediates every identified deficiency so the feature can pass Overseer review.

## Scope

### In scope

- Define a `NotificationDispatching` protocol for the notification service
- Replace the `NotificationService.shared` singleton with protocol-based dependency injection via `@Environment`
- Register the service in `App.swift` following the established pattern (EnvironmentKey, EnvironmentValues extension, injection in body)
- Inject the protocol into `PharaohMenuBar` and remove the direct `NotificationService.shared` reference
- Extract transition-detection logic from `PharaohMenuBar` into a testable unit (either on the protocol or a small helper) so `checkForTransition` can be tested against a mock
- Replace the deprecated `NSApplication.shared.activate(ignoringOtherApps: true)` call with `NSApplication.shared.activate()`
- Add pruning of `previousStatuses` entries when their source directory no longer appears in the project list
- Write tests for all public API methods on the notification service protocol, including:
  - `setUp()` (verifiable via mock delegate assignment or permission request tracking)
  - `notifyPhaseCompleted(projectName:phaseName:turns:costUsd:)` (verify correct content/identifier via mock)
  - `notifyPhaseFailed(projectName:phaseName:error:turns:costUsd:)` (verify correct content/identifier via mock)
  - Transition detection: verify that busy-to-done fires `notifyPhaseCompleted`, busy-to-blocked fires `notifyPhaseFailed`, and all other transitions fire nothing
- Update `.ushabti/docs/pharaoh-integration.md` to document the notification service, its protocol, environment injection, and transition detection

### Out of scope

- Extracting `loadRunningPlans` or polling logic from `PharaohMenuBar` into the ViewModel (noted as a future concern, not yet warranted by size)
- Adding new notification types beyond phase-completed and phase-failed
- Persisting notification permission state or providing in-app notification preferences
- Refactoring `PharaohMenuBar` below its current line count (it is within acceptable Sandi Metz spirit at 142 lines)

## Constraints

- **L09:** Services must be protocol-based. Dependencies must be injected as protocols, not concretions. No singleton access from views.
- **L11:** Every public API method must have tests. Tests must pass.
- **L12:** No dead code. If the singleton pattern is removed, remove `static let shared` and the private init override.
- **L19:** Build must pass via `./Scripts/build-app.sh`.
- **Style (protocol pattern):** Every service has a protocol defining its public interface, a concrete implementation, an EnvironmentKey, and an EnvironmentValues extension. See `PharaohProviding` / `PharaohServiceEnvironmentKey` for the canonical example.
- **Style (Sandi Metz):** Small classes, short methods, composition over inheritance.
- **Style (no regex):** Not expected to be relevant here, but noted.
- **Style (naming):** Protocol name describes capability: `NotificationDispatching`. File for protocol: `NotificationDispatching.swift`. Environment key file: `NotificationServiceEnvironmentKey.swift`.

## Acceptance Criteria

1. A `NotificationDispatching` protocol exists in `Sources/Hieroglyphs/Services/NotificationDispatching.swift` with methods matching the current public API (`setUp`, `notifyPhaseCompleted`, `notifyPhaseFailed`).
2. `NotificationService` conforms to `NotificationDispatching` and no longer exposes `static let shared`.
3. An `EnvironmentKey` and `EnvironmentValues` extension exist in `NotificationServiceEnvironmentKey.swift`, following the `PharaohServiceEnvironmentKey` pattern.
4. `App.swift` creates, stores, and injects the notification service via `.environment(\.notificationService, ...)`.
5. `PharaohMenuBar` accesses the notification service via `@Environment(\.notificationService)` instead of `NotificationService.shared`.
6. The deprecated `activate(ignoringOtherApps:)` call is replaced with `activate()`.
7. `previousStatuses` entries for source directories no longer present in the project list are pruned during `loadRunningPlans()`.
8. Tests exist in `Tests/HieroglyphsTests/NotificationServiceTests.swift` covering all public API methods on the protocol and the transition-detection logic.
9. All tests pass (`swift test`).
10. Build passes (`./Scripts/build-app.sh`).
11. `.ushabti/docs/pharaoh-integration.md` is updated to document the notification service integration.

## Risks / Notes

- **UNUserNotificationCenter delegate:** The `NotificationService` conforms to `UNUserNotificationCenterDelegate`. This is an implementation detail that does not need to appear on the protocol. The protocol defines the dispatch interface; the delegate conformance stays on the concrete class.
- **Testing UNUserNotificationCenter:** Directly testing `UNUserNotificationCenter.add()` calls in unit tests is impractical (system API, requires entitlements). Tests should verify that the correct content is constructed and the correct method is called, likely by making the notification center injectable or by testing the transition-detection logic against a mock `NotificationDispatching`.
- **`checkForTransition` ownership:** Currently lives in `PharaohMenuBar` as a private method. For testability, the transition-detection logic should be extracted to a location where it can be tested with a mock `NotificationDispatching`. Options include: a free function, a small struct, or a method on a helper type that takes a `NotificationDispatching` dependency. The Builder should choose the simplest approach that enables testing.
- **`previousStatuses` pruning:** The pruning is a minor cleanup. It should happen at the end of `loadRunningPlans()` after the new set of source directories is known. Compare keys in `previousStatuses` against the current set and remove stale ones.
