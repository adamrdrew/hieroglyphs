import Foundation

/// Represents the current status of a Pharaoh process.
enum PharaohStatus: Equatable {
    case notRunning
    case idle
    case busy(phase: String, turnsElapsed: Int, runningCostUsd: Double, phaseStarted: Date?)
    case done(phase: String, costUsd: Double, turns: Int)
    case blocked(phase: String, error: String, costUsd: Double, turns: Int)

    /// Returns true if Pharaoh is running in any state (not notRunning).
    var isRunning: Bool {
        switch self {
        case .notRunning:
            return false
        case .idle, .busy, .done, .blocked:
            return true
        }
    }

    /// Returns true if Pharaoh is actively executing a phase.
    var isBusy: Bool {
        if case .busy = self {
            return true
        }
        return false
    }

    /// Returns true if Pharaoh is idle and ready to accept work.
    var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
    }
}
