import Foundation
import SwiftUI

/// Result of command execution.
struct CommandResult {
    let exitCode: Int
    let output: String
    let error: String
}

/// Protocol defining command execution capability.
protocol CommandExecutionProviding {
    /// Executes a shell command in the specified working directory.
    ///
    /// - Parameters:
    ///   - command: The shell command to execute
    ///   - workingDirectory: The directory in which to run the command
    /// - Returns: CommandResult containing exit code, stdout, and stderr
    /// - Throws: If the process fails to launch or times out
    func executeCommand(
        command: String,
        workingDirectory: String
    ) async throws -> CommandResult
}

/// Service for executing shell commands via Foundation.Process.
final class CommandExecutionService: CommandExecutionProviding {
    enum CommandError: Error {
        case processLaunchFailed
        case timeout
        case nonZeroExit(Int, String)
    }

    private let timeout: TimeInterval

    init(timeout: TimeInterval = 300.0) {
        self.timeout = timeout
    }

    func executeCommand(
        command: String,
        workingDirectory: String
    ) async throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw CommandError.processLaunchFailed
        }

        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            if process.isRunning {
                process.terminate()
            }
        }

        await withCheckedContinuation { continuation in
            process.terminationHandler = { _ in
                timeoutTask.cancel()
                continuation.resume()
            }
        }

        if timeoutTask.isCancelled == false {
            timeoutTask.cancel()
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        let exitCode = Int(process.terminationStatus)

        if exitCode != 0 {
            throw CommandError.nonZeroExit(exitCode, errorOutput.isEmpty ? output : errorOutput)
        }

        return CommandResult(
            exitCode: exitCode,
            output: output,
            error: errorOutput
        )
    }
}

// MARK: - Environment Key

private struct CommandExecutionServiceKey: EnvironmentKey {
    static let defaultValue: CommandExecutionProviding = CommandExecutionService()
}

extension EnvironmentValues {
    var commandExecutionService: CommandExecutionProviding {
        get { self[CommandExecutionServiceKey.self] }
        set { self[CommandExecutionServiceKey.self] = newValue }
    }
}
