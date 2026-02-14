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
    case processAlreadyRunning

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
        case .processAlreadyRunning:
            return "Pharaoh process is already running"
        }
    }
}

/// Result of stale process detection and cleanup.
enum StaleProcessResult: Equatable {
    /// No stale process was found. Safe to start a new process.
    case noStaleProcess
    /// A stale process was found and killed.
    case cleanedStaleProcess(pid: Int)
    /// A stale pharaoh.json file was found but the process no longer exists.
    case staleFileOnly
}

/// Protocol defining Pharaoh process management and status reading capabilities.
protocol PharaohProviding {
    /// Starts the Pharaoh server process in the specified directory with the specified model.
    ///
    /// Creates a new process group for the spawned process to enable killing the entire
    /// process tree (both npm parent and node child). Performs stale process cleanup
    /// before starting to prevent orphaned processes from accumulating.
    ///
    /// - Parameters:
    ///   - directory: Absolute path to the source directory containing .pharaoh/
    ///   - model: The Claude model to use (e.g., "opus", "sonnet", "haiku")
    /// - Throws: PharaohError.processStartFailed if the process fails to start
    /// - Throws: PharaohError.directoryNotFound if the directory does not exist
    /// - Throws: PharaohError.processAlreadyRunning if a process is already running
    func start(in directory: String, model: String) throws

    /// Stops the currently running Pharaoh server process.
    ///
    /// Sends SIGTERM to the entire process group (both npm parent and node child)
    /// and waits for termination to complete. Has no effect if no process is running.
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

    /// Reads and parses events from the Pharaoh event stream.
    ///
    /// - Parameter directory: Absolute path to the source directory containing .pharaoh/
    /// - Returns: Array of PharaohEvent objects, or empty array if file does not exist
    func readEvents(from directory: String) -> [PharaohEvent]

    /// Reads server metadata from pharaoh.json.
    ///
    /// - Parameter directory: Absolute path to the source directory containing .pharaoh/
    /// - Returns: PharaohServerInfo if file exists and is valid, nil otherwise
    func readServerInfo(from directory: String) -> PharaohServerInfo?

    /// Detects and cleans up stale Pharaoh processes from previous sessions.
    ///
    /// Reads `.pharaoh/pharaoh.json` to extract the PID, tests if the process still exists,
    /// and kills it if found. This prevents orphaned processes from accumulating.
    ///
    /// - Parameter directory: Absolute path to the source directory containing .pharaoh/
    /// - Returns: Result indicating whether a stale process was found and cleaned
    func cleanupStaleProcess(in directory: String) -> StaleProcessResult
}
