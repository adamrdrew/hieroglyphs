import Foundation

/// Represents server metadata from pharaoh.json.
struct PharaohServerInfo: Equatable {
    let status: String
    let pid: Int
    let started: Date
    let pharaohVersion: String
    let ushabtiVersion: String
    let model: String
    let cwd: String
    let phasesCompleted: Int

    /// Parse server metadata from a JSON dictionary.
    /// Returns nil if required fields are missing or malformed.
    static func parse(json: [String: Any]) -> PharaohServerInfo? {
        guard let status = json["status"] as? String,
              let pid = json["pid"] as? Int,
              let startedString = json["started"] as? String,
              let pharaohVersion = json["pharaohVersion"] as? String,
              let ushabtiVersion = json["ushabtiVersion"] as? String,
              let model = json["model"] as? String,
              let cwd = json["cwd"] as? String,
              let phasesCompleted = json["phasesCompleted"] as? Int else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let started = formatter.date(from: startedString) else {
            return nil
        }

        return PharaohServerInfo(
            status: status,
            pid: pid,
            started: started,
            pharaohVersion: pharaohVersion,
            ushabtiVersion: ushabtiVersion,
            model: model,
            cwd: cwd,
            phasesCompleted: phasesCompleted
        )
    }
}
