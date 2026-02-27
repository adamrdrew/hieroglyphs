import SwiftUI

/// Environment key for NotificationDispatching service injection.
struct NotificationServiceEnvironmentKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any NotificationDispatching)? = nil
}

extension EnvironmentValues {
    var notificationService: (any NotificationDispatching)? {
        get { self[NotificationServiceEnvironmentKey.self] }
        set { self[NotificationServiceEnvironmentKey.self] = newValue }
    }
}
