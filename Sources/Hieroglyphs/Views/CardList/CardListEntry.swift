import SwiftUI

/// Individual card row showing title, type badge, priority indicator, and status.
struct CardListEntry: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    let card: Card

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: typeIcon)
                .foregroundStyle( typeColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.title.uppercased())
                    .font(.headline)

                if !card.body.isEmpty {
                    Text(strippedBody)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                HStack(spacing: 8) {
                    Text(statusLabel)
                        .font(.caption)
                        .foregroundStyle(statusColor)

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
        .contextMenu {
            Button {
                viewModel.showNewPlanSheetFromCard(card)
            } label: {
                Label("Create Plan", systemImage: "flowchart")
            }
        }
    }

    private var typeColor : Color {
        switch card.type {
        case .task:
            return .blue
        case .bug:
            return .red
        case .feature:
            return .yellow
        case .note:
            return .pink
        }
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

    private var strippedBody: String {
        card.body
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

    private var statusLabel: String {
        card.status.rawValue.replacingOccurrences(of: "-", with: " ")
    }

    private var statusColor: Color {
        switch card.status {
        case .backlog:
            return .gray
        case .triage:
            return .orange
        case .todo:
            return .blue
        case .inProgress:
            return .purple
        case .done:
            return .green
        case .archived:
            return .secondary
        }
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
