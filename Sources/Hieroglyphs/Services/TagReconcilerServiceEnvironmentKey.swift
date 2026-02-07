import SwiftUI

private struct TagReconcilerServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: TagReconciling = TagReconcilerService()
}

extension EnvironmentValues {
    var tagReconciler: TagReconciling {
        get { self[TagReconcilerServiceKey.self] }
        set { self[TagReconcilerServiceKey.self] = newValue }
    }
}
