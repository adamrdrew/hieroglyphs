/// Detects meaningful Pharaoh status transitions and dispatches notifications.
///
/// Only fires on busy-to-done and busy-to-blocked transitions. All other
/// transitions (idle-to-busy, notRunning-to-idle, etc.) are normal lifecycle
/// events that do not warrant interrupting the user.
///
/// - Parameters:
///   - previous: The previous Pharaoh status (nil if first observation).
///   - current: The current Pharaoh status.
///   - projectName: Display name of the project for notification content.
///   - notifier: The notification dispatcher to send notifications through.
func detectPharaohTransition(
    from previous: PharaohStatus?,
    to current: PharaohStatus,
    projectName: String,
    notifier: any NotificationDispatching
) {
    guard let previous, case .busy = previous else { return }

    switch current {
    case .done(let phase, let costUsd, let turns):
        notifier.notifyPhaseCompleted(
            projectName: projectName,
            phaseName: phase,
            turns: turns,
            costUsd: costUsd
        )

    case .blocked(let phase, let error, let costUsd, let turns):
        notifier.notifyPhaseFailed(
            projectName: projectName,
            phaseName: phase,
            error: error,
            turns: turns,
            costUsd: costUsd
        )

    default:
        break
    }
}
