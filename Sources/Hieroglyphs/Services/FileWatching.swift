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
}
