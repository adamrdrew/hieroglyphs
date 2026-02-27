import AppKit
import UserNotifications

/// Provides macOS push notifications for Pharaoh lifecycle events.
///
/// Requests notification permission on first use, then delivers
/// banners when Pharaoh phases complete or fail.
@MainActor
final class NotificationService: NSObject, NotificationDispatching, UNUserNotificationCenterDelegate {
    private var hasRequestedPermission = false

    /// Sets up this service as the notification centre delegate and requests
    /// permission if not already done. Call once at app startup.
    func setUp() {
        let centre = UNUserNotificationCenter.current()
        centre.delegate = self

        guard !hasRequestedPermission else { return }
        hasRequestedPermission = true

        centre.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("[Notifications] Permission error: \(error.localizedDescription)")
            } else if !granted {
                print("[Notifications] Permission denied by user")
            }
        }
    }

    /// Sends a notification that a Pharaoh phase completed successfully.
    nonisolated func notifyPhaseCompleted(
        projectName: String,
        phaseName: String,
        turns: Int,
        costUsd: Double
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Phase Complete"
        content.subtitle = "\(phaseName) — \(projectName)"
        content.body = "Finished in \(turns) turn\(turns == 1 ? "" : "s") ($\(String(format: "%.4f", costUsd)))"
        content.sound = .default
        content.categoryIdentifier = "PHARAOH_COMPLETE"

        let request = UNNotificationRequest(
            identifier: "pharaoh-done-\(phaseName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Notifications] Failed to deliver completion notification: \(error.localizedDescription)")
            }
        }
    }

    /// Sends a notification that a Pharaoh phase failed.
    nonisolated func notifyPhaseFailed(
        projectName: String,
        phaseName: String,
        error: String,
        turns: Int,
        costUsd: Double
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Phase Failed"
        content.subtitle = "\(phaseName) — \(projectName)"
        let truncatedError = error.count > 120 ? String(error.prefix(117)) + "..." : error
        content.body = "\(truncatedError)\n\(turns) turn\(turns == 1 ? "" : "s"), $\(String(format: "%.4f", costUsd))"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "PHARAOH_FAILED"

        let request = UNNotificationRequest(
            identifier: "pharaoh-blocked-\(phaseName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Notifications] Failed to deliver failure notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Presents notifications even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Handles notification click — brings the app to front.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            NSApplication.shared.activate()
        }
        completionHandler()
    }
}
