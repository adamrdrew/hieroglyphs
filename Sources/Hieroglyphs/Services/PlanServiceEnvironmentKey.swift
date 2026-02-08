import SwiftUI

/// Environment key for injecting PlanProviding service.
private struct PlanServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: PlanProviding = PlanService()
}

extension EnvironmentValues {
    /// Provides access to the plan service via environment.
    var planService: PlanProviding {
        get { self[PlanServiceKey.self] }
        set { self[PlanServiceKey.self] = newValue }
    }
}
