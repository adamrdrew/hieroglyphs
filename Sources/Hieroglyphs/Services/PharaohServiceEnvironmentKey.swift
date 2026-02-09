import SwiftUI

/// Environment key for PharaohProviding service injection.
struct PharaohServiceEnvironmentKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: PharaohProviding? = nil
}

extension EnvironmentValues {
    var pharaohService: PharaohProviding? {
        get { self[PharaohServiceEnvironmentKey.self] }
        set { self[PharaohServiceEnvironmentKey.self] = newValue }
    }
}
