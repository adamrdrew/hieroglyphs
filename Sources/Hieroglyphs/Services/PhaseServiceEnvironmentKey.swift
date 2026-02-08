import SwiftUI

/// Environment key for injecting PhaseProviding service.
private struct PhaseServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: PhaseProviding? = nil
}

extension EnvironmentValues {
    /// Provides access to the phase service via environment.
    var phaseService: PhaseProviding? {
        get { self[PhaseServiceKey.self] }
        set { self[PhaseServiceKey.self] = newValue }
    }
}
