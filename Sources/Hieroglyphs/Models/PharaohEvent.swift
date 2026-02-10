import Foundation

/// Represents a single event from the Pharaoh event stream.
struct PharaohEvent: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let type: PharaohEventType
    let summary: String
    let detailJson: String?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        type: PharaohEventType,
        summary: String,
        detailJson: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.summary = summary
        self.detailJson = detailJson
    }

    /// Parse a JSON Lines string into a PharaohEvent.
    /// Returns nil if the line is malformed or cannot be parsed.
    static func parse(line: String) -> PharaohEvent? {
        guard let data = line.data(using: .utf8) else {
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        guard let timestampString = json["timestamp"] as? String,
              let typeString = json["type"] as? String,
              let summary = json["summary"] as? String else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let timestamp = formatter.date(from: timestampString) else {
            return nil
        }

        guard let type = PharaohEventType(rawValue: typeString) else {
            return nil
        }

        let detailJson: String?
        if let detail = json["detail"] {
            let detailData = try? JSONSerialization.data(
                withJSONObject: detail,
                options: []
            )
            detailJson = detailData.flatMap { String(data: $0, encoding: .utf8) }
        } else {
            detailJson = nil
        }

        return PharaohEvent(
            timestamp: timestamp,
            type: type,
            summary: summary,
            detailJson: detailJson
        )
    }
}

/// Types of events in the Pharaoh event stream.
enum PharaohEventType: String, Equatable {
    case toolCall = "tool_call"
    case toolProgress = "tool_progress"
    case toolSummary = "tool_summary"
    case text
    case turn
    case status
    case result
    case error
}
