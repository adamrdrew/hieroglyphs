/// Protocol defining notification dispatch capabilities for Pharaoh lifecycle events.
@MainActor
protocol NotificationDispatching {
    /// Sets up the notification service (delegate assignment, permission request).
    /// Call once at app startup.
    func setUp()

    /// Sends a notification that a Pharaoh phase completed successfully.
    nonisolated func notifyPhaseCompleted(
        projectName: String,
        phaseName: String,
        turns: Int,
        costUsd: Double
    )

    /// Sends a notification that a Pharaoh phase failed.
    nonisolated func notifyPhaseFailed(
        projectName: String,
        phaseName: String,
        error: String,
        turns: Int,
        costUsd: Double
    )
}
