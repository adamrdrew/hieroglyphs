import Foundation

/// Protocol defining file system monitoring capabilities.
///
/// Monitors a directory tree for file changes using FSEvents.
/// When files are created, modified, or deleted, the onChange closure
/// is invoked with the changed file URL. Implementations use the
/// FSEventStream API for efficient, system-level file monitoring.
protocol FileWatching {
    /// Begins monitoring a directory path recursively.
    ///
    /// Uses FSEvents to detect file creation, modification, and deletion.
    /// The onChange closure is called on the main thread when changes occur.
    ///
    /// - Parameters:
    ///   - path: Absolute path to directory to monitor
    ///   - onChange: Closure called with changed file URL
    func startWatching(path: String, onChange: @escaping (URL) -> Void)

    /// Stops monitoring and cleans up resources.
    ///
    /// Safe to call multiple times. After calling stopWatching,
    /// startWatching may be called again to resume monitoring.
    func stopWatching()

    /// Begins monitoring a phases directory path recursively.
    ///
    /// Similar to startWatching but for a separate phases directory.
    /// Both workspace and phases directories can be watched simultaneously.
    /// Uses a separate FSEventStream to avoid conflicts.
    ///
    /// - Parameters:
    ///   - path: Absolute path to phases directory to monitor
    ///   - onChange: Closure called with changed file URL
    func startWatchingPhases(path: String, onChange: @escaping (URL) -> Void)

    /// Stops phases monitoring and cleans up resources.
    ///
    /// Safe to call multiple times. After calling stopWatchingPhases,
    /// startWatchingPhases may be called again to resume monitoring.
    func stopWatchingPhases()

    /// Begins monitoring a pharaoh directory path recursively.
    ///
    /// Similar to startWatching but for a separate pharaoh directory.
    /// Both workspace and pharaoh directories can be watched simultaneously.
    /// Uses a separate FSEventStream to avoid conflicts.
    ///
    /// - Parameters:
    ///   - path: Absolute path to pharaoh directory to monitor
    ///   - onChange: Closure called with changed file URL
    func startWatchingPharaoh(path: String, onChange: @escaping (URL) -> Void)

    /// Stops pharaoh monitoring and cleans up resources.
    ///
    /// Safe to call multiple times. After calling stopWatchingPharaoh,
    /// startWatchingPharaoh may be called again to resume monitoring.
    func stopWatchingPharaoh()
}
