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

    func start(in directory: String, model: String) throws {
        let directoryURL = URL(fileURLWithPath: directory)
        guard FileManager.default.fileExists(atPath: directory) else {
            throw PharaohError.directoryNotFound(directory)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "npx @adamrdrew/pharaoh serve --model \(model)"]
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
            let turnsElapsed = json["turnsElapsed"] as? Int ?? 0
            let runningCostUsd = json["runningCostUsd"] as? Double ?? 0.0

            let phaseStarted: Date?
            if let phaseStartedString = json["phaseStarted"] as? String {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                phaseStarted = formatter.date(from: phaseStartedString)
            } else {
                phaseStarted = nil
            }

            return .busy(
                phase: phase,
                turnsElapsed: turnsElapsed,
                runningCostUsd: runningCostUsd,
                phaseStarted: phaseStarted
            )

        case "done":
            let phase = json["phase"] as? String ?? "unknown"
            let costUsd = json["costUsd"] as? Double ?? 0.0
            let turns = json["turns"] as? Int ?? 0
            return .done(phase: phase, costUsd: costUsd, turns: turns)

        case "blocked":
            let phase = json["phase"] as? String ?? "unknown"
            let error = json["error"] as? String ?? "Unknown error"
            let costUsd = json["costUsd"] as? Double ?? 0.0
            let turns = json["turns"] as? Int ?? 0
            return .blocked(phase: phase, error: error, costUsd: costUsd, turns: turns)

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

    func readEvents(from directory: String) -> [PharaohEvent] {
        let eventsPath = directory + "/.pharaoh/events.jsonl"

        guard FileManager.default.fileExists(atPath: eventsPath) else {
            return []
        }

        guard let content = try? String(contentsOf: URL(fileURLWithPath: eventsPath), encoding: .utf8) else {
            return []
        }

        return content
            .split(separator: "\n")
            .compactMap { PharaohEvent.parse(line: String($0)) }
    }

    func readServerInfo(from directory: String) -> PharaohServerInfo? {
        let serverInfoPath = directory + "/.pharaoh/pharaoh.json"
        let serverInfoURL = URL(fileURLWithPath: serverInfoPath)

        guard FileManager.default.fileExists(atPath: serverInfoPath) else {
            return nil
        }

        guard let data = try? Data(contentsOf: serverInfoURL) else {
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return PharaohServerInfo.parse(json: json)
    }

    @objc private func applicationWillTerminate() {
        stop()
    }
}
