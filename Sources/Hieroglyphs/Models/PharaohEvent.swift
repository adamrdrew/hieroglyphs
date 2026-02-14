import Foundation

/// Represents a single event from the Pharaoh event stream.
struct PharaohEvent: Identifiable, Equatable {
    let id: Int
    let timestamp: Date
    let type: PharaohEventType
    let summary: String
    let detailJson: String?

    init(
        id: Int,
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

    /// Returns true if this event has detail data.
    var hasDetail: Bool {
        detailJson != nil
    }

    /// Extract tool name from detail JSON for tool_call events.
    var toolName: String? {
        parseDetailField(key: "tool_name")
    }

    /// Extract tool input from detail JSON for tool_call events.
    var toolInput: String? {
        parseDetailField(key: "input")
    }

    /// Extract turn number from detail JSON for turn events.
    var turnNumber: Int? {
        parseDetailField(key: "turn")
    }

    /// Extract input token count from detail JSON for turn events.
    var inputTokens: Int? {
        parseDetailField(key: "input_tokens")
    }

    /// Extract output token count from detail JSON for turn events.
    var outputTokens: Int? {
        parseDetailField(key: "output_tokens")
    }

    /// Extract full text from detail JSON for text events.
    var fullText: String? {
        parseDetailField(key: "full_text")
    }

    /// Extract total turns from detail JSON for result events.
    var resultTurns: Int? {
        parseDetailField(key: "turns")
    }

    /// Extract total cost from detail JSON for result events.
    var resultCostUsd: Double? {
        parseDetailField(key: "cost_usd")
    }

    /// Parse a field from the detail JSON.
    private func parseDetailField<T>(key: String) -> T? {
        guard let detailJson = detailJson,
              let data = detailJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let value = json[key] as? T else {
            return nil
        }
        return value
    }

    /// Parse a JSON Lines string into a PharaohEvent.
    /// Returns nil if the line is malformed or cannot be parsed.
    static func parse(line: String, index: Int) -> PharaohEvent? {
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
            id: index,
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
