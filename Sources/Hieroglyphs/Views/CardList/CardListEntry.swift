import SwiftUI

/// Individual card row showing title, type badge, priority indicator, and status.
struct CardListEntry: View {
    let card: Card

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: typeIcon)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.body)

                HStack(spacing: 8) {
                    Text(statusLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if priorityIndicatorIcon != nil {
                        Image(systemName: priorityIndicatorIcon!)
                            .font(.caption)
                            .foregroundStyle(priorityColor)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var typeIcon: String {
        switch card.type {
        case .task:
            return "checkmark.circle"
        case .bug:
            return "ladybug"
        case .feature:
            return "star"
        case .note:
            return "note.text"
        }
    }

    private var statusLabel: String {
        card.status.rawValue.replacingOccurrences(of: "-", with: " ")
    }

    private var priorityIndicatorIcon: String? {
        switch card.priority {
        case .critical, .high:
            return "exclamationmark.circle.fill"
        case .medium, .low:
            return nil
        }
    }

    private var priorityColor: Color {
        switch card.priority {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .secondary
        case .low:
            return .secondary
        }
    }
}
