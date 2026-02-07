import SwiftUI

/// Environment key for injecting WorkspaceProviding service.
private struct WorkspaceServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: WorkspaceProviding = WorkspaceService()
}

extension EnvironmentValues {
    /// Provides access to the workspace service via environment.
    var workspaceService: WorkspaceProviding {
        get { self[WorkspaceServiceKey.self] }
        set { self[WorkspaceServiceKey.self] = newValue }
    }
}
