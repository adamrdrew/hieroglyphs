import SwiftUI

/// Individual phase row showing number, title, and status indicator.
struct PhaseListEntry: View {
    let phase: Phase

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(phase.title.uppercased())
                    .font(.headline)

                if !phase.intent.isEmpty {
                    Text(strippedIntent)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Text("Phase \(String(format: "%04d", phase.number))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var strippedIntent: String {
        phase.intent
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "> ", with: "")
            .replacingOccurrences(of: "- ", with: "")
            .split(separator: " ")
            .joined(separator: " ")
    }

    private var statusIcon: String {
        switch phase.status {
        case .planned:
            return "circle"
        case .building:
            return "circle.inset.filled"
        case .complete:
            return "checkmark.circle.fill"
        case .review:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch phase.status {
        case .planned:
            return .secondary
        case .building:
            return .blue
        case .complete:
            return .green
        case .review:
            return .yellow
        }
    }
}
