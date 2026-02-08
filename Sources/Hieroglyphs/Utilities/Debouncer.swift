import Foundation

/// Debounces rapid actions into a single delayed execution.
///
/// Schedules an action to run after a delay. If scheduled again before the delay
/// expires, cancels the previous schedule and starts a new delay. Useful for
/// batching rapid updates (e.g., keystroke events) into a single operation.
@MainActor
final class Debouncer {
    private let delay: TimeInterval
    private var workItem: Task<Void, Never>?
    private var pendingAction: (() -> Void)?

    /// Creates a debouncer with the specified delay.
    ///
    /// - Parameter delay: Time interval to wait before executing scheduled action
    init(delay: TimeInterval) {
        self.delay = delay
    }

    /// Schedules an action to execute after the delay.
    ///
    /// Cancels any previously scheduled action. If called repeatedly, only the
    /// most recent action will execute after the delay expires.
    ///
    /// - Parameter action: Closure to execute after delay
    func schedule(action: @escaping @MainActor () -> Void) {
        cancel()
        pendingAction = action

        workItem = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            pendingAction?()
            pendingAction = nil
        }
    }

    /// Executes the scheduled action immediately, bypassing the delay.
    ///
    /// Cancels the pending delayed execution and runs the action synchronously.
    /// Does nothing if no action is scheduled.
    func flush() {
        workItem?.cancel()
        workItem = nil

        if let action = pendingAction {
            pendingAction = nil
            action()
        }
    }

    /// Cancels the scheduled action without executing it.
    func cancel() {
        workItem?.cancel()
        workItem = nil
        pendingAction = nil
    }

    nonisolated deinit {
        workItem?.cancel()
    }
}
