import Foundation
import AppKit

/// Service responsible for managing the Pharaoh server process lifecycle.
final class PharaohService: PharaohProviding, @unchecked Sendable {
    private var process: Process?

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stop()
    }

    func start(in directory: String) throws {
        let directoryURL = URL(fileURLWithPath: directory)
        guard FileManager.default.fileExists(atPath: directory) else {
            throw PharaohError.directoryNotFound(directory)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "npx @adamrdrew/pharaoh serve"]
        process.currentDirectoryURL = directoryURL

        process.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                self?.process = nil
            }
        }

        do {
            try process.run()
            self.process = process
        } catch {
            throw PharaohError.processStartFailed(error.localizedDescription)
        }
    }

    func stop() {
        guard let process = process else { return }
        process.terminate()
        self.process = nil
    }

    func readStatus(from directory: String) -> PharaohStatus {
        let statusPath = directory + "/.pharaoh/pharaoh.json"
        let statusURL = URL(fileURLWithPath: statusPath)

        guard FileManager.default.fileExists(atPath: statusPath) else {
            return .notRunning
        }

        guard let data = try? Data(contentsOf: statusURL) else {
            return .notRunning
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .notRunning
        }

        guard let status = json["status"] as? String else {
            return .notRunning
        }

        switch status {
        case "idle":
            return .idle

        case "busy":
            let phase = json["phase"] as? String ?? "unknown"
            return .busy(phase: phase)

        case "done":
            let phase = json["phase"] as? String ?? "unknown"
            let cost = json["cost"] as? Double ?? 0.0
            let turns = json["turns"] as? Int ?? 0
            return .done(phase: phase, cost: cost, turns: turns)

        case "blocked":
            let phase = json["phase"] as? String ?? "unknown"
            let error = json["error"] as? String ?? "Unknown error"
            return .blocked(phase: phase, error: error)

        default:
            return .notRunning
        }
    }

    func readLogs(from directory: String, count: Int) -> [String] {
        let logPath = directory + "/.pharaoh/pharaoh.log"
        let logURL = URL(fileURLWithPath: logPath)

        guard FileManager.default.fileExists(atPath: logPath) else {
            return []
        }

        guard let content = try? String(contentsOf: logURL, encoding: .utf8) else {
            return []
        }

        let lines = content.split(separator: "\n").map(String.init)
        let startIndex = max(0, lines.count - count)
        return Array(lines[startIndex...])
    }

    @objc private func applicationWillTerminate() {
        stop()
    }
}
