import Foundation

/// Errors that can occur during Pharaoh operations.
enum PharaohError: Error, LocalizedError {
    case processStartFailed(String)
    case directoryNotFound(String)
    case statusFileNotFound
    case statusFileReadFailed(Error)
    case statusFileDecodeFailed(Error)
    case logFileNotFound
    case logFileReadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .processStartFailed(let message):
            return "Failed to start Pharaoh process: \(message)"
        case .directoryNotFound(let path):
            return "Source directory not found: \(path)"
        case .statusFileNotFound:
            return "Pharaoh status file not found (.pharaoh/pharaoh.json)"
        case .statusFileReadFailed(let error):
            return "Failed to read Pharaoh status file: \(error.localizedDescription)"
        case .statusFileDecodeFailed(let error):
            return "Failed to decode Pharaoh status: \(error.localizedDescription)"
        case .logFileNotFound:
            return "Pharaoh log file not found (.pharaoh/pharaoh.log)"
        case .logFileReadFailed(let error):
            return "Failed to read Pharaoh log file: \(error.localizedDescription)"
        }
    }
}

/// Protocol defining Pharaoh process management and status reading capabilities.
protocol PharaohProviding {
    /// Starts the Pharaoh server process in the specified directory.
    ///
    /// - Parameter directory: Absolute path to the source directory containing .pharaoh/
    /// - Throws: PharaohError.processStartFailed if the process fails to start
    /// - Throws: PharaohError.directoryNotFound if the directory does not exist
    func start(in directory: String) throws

    /// Stops the currently running Pharaoh server process.
    ///
    /// Has no effect if no process is running.
    func stop()

    /// Reads the current Pharaoh status from the status file.
    ///
    /// - Parameter directory: Absolute path to the source directory containing .pharaoh/
    /// - Returns: Current PharaohStatus, or .notRunning if status file does not exist
    func readStatus(from directory: String) -> PharaohStatus

    /// Reads the most recent log lines from the Pharaoh log file.
    ///
    /// - Parameters:
    ///   - directory: Absolute path to the source directory containing .pharaoh/
    ///   - count: Maximum number of lines to return (from end of file)
    /// - Returns: Array of log line strings, or empty array if log file does not exist
    func readLogs(from directory: String, count: Int) -> [String]
}
