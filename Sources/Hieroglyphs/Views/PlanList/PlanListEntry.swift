import SwiftUI

/// Individual plan row showing number, title, status, and card count.
struct PlanListEntry: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @State private var planPendingDeletion: Plan?

    let plan: Plan

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title.uppercased())
                    .font(.headline)

                if !plan.phasePrompt.isEmpty {
                    Text(strippedPhasePrompt)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Text("Plan \(String(format: "%04d", plan.number)) • \(plan.linkedCardSlugs.count) cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(role: .destructive) {
                planPendingDeletion = plan
            } label: {
                Label("Delete Plan", systemImage: "trash")
            }
        }
        .alert(
            "Delete Plan",
            isPresented: Binding(
                get: { planPendingDeletion != nil },
                set: { if !$0 { planPendingDeletion = nil } }
            ),
            presenting: planPendingDeletion
        ) { plan in
            Button("Cancel", role: .cancel) {
                planPendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.deletePlan(plan)
                planPendingDeletion = nil
            }
        } message: { plan in
            Text("Are you sure you want to delete '\(plan.title)'? This will move the plan to Trash.")
        }
    }

    private var strippedPhasePrompt: String {
        plan.phasePrompt
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
        switch plan.status {
        case .planning:
            return "circle"
        case .ready:
            return "circle.inset.filled"
        case .inProgress:
            return "circle.inset.filled"
        case .done:
            return "checkmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch plan.status {
        case .planning:
            return .secondary
        case .ready:
            return .blue
        case .inProgress:
            return .orange
        case .done:
            return .green
        }
    }
}
