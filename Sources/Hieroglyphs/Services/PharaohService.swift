import Foundation
import AppKit

/// Service responsible for managing the Pharaoh server process lifecycle.
final class PharaohService: PharaohProviding, @unchecked Sendable {
    private var processes: [String: Process] = [:]

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
        guard processes[directory]?.isRunning != true else {
            throw PharaohError.processAlreadyRunning
        }

        let cleanupResult = cleanupStaleProcess(in: directory)
        if case .cleanedStaleProcess(let pid) = cleanupResult {
            print("[PharaohService] Cleaned up stale process with PID \(pid)")
        }

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
                self?.processes[directory] = nil
            }
        }

        do {
            try process.run()
            let pid = process.processIdentifier
            setpgid(pid, pid)
            self.processes[directory] = process
        } catch {
            throw PharaohError.processStartFailed(error.localizedDescription)
        }
    }

    func stop() {
        for (_, process) in processes {
            let pgid = process.processIdentifier
            kill(-pgid, SIGTERM)
            process.waitUntilExit()
        }
        processes.removeAll()
    }

    func stop(in directory: String) {
        guard let process = processes[directory] else { return }
        let pgid = process.processIdentifier
        kill(-pgid, SIGTERM)
        process.waitUntilExit()
        processes[directory] = nil
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
            .enumerated()
            .compactMap { index, line in
                PharaohEvent.parse(line: String(line), index: index)
            }
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

    func cleanupStaleProcess(in directory: String) -> StaleProcessResult {
        if processes[directory]?.isRunning == true {
            return .noStaleProcess
        }

        let statusPath = directory + "/.pharaoh/pharaoh.json"
        let statusURL = URL(fileURLWithPath: statusPath)

        guard FileManager.default.fileExists(atPath: statusPath) else {
            return .noStaleProcess
        }

        guard let data = try? Data(contentsOf: statusURL) else {
            return .noStaleProcess
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .noStaleProcess
        }

        guard let pid = json["pid"] as? Int else {
            return .noStaleProcess
        }

        if let currentProcess = processes[directory], currentProcess.processIdentifier == Int32(pid) {
            return .noStaleProcess
        }

        let processExists = kill(pid_t(pid), 0) == 0

        if processExists {
            kill(-pid_t(pid), SIGTERM)
            return .cleanedStaleProcess(pid: pid)
        } else {
            return .staleFileOnly
        }
    }

    @objc private func applicationWillTerminate() {
        stop()
    }
}
