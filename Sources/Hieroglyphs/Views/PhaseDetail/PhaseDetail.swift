import SwiftUI
import MarkdownUI

/// Detail column view for displaying a selected phase.
///
/// Shows phase number, title, status, intent, steps checklist, and review notes.
/// This is a read-only view—phases are managed by Ushabti agents.
struct PhaseDetail: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    var body: some View {
        Group {
            if let phase = viewModel.selectedPhase {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        phaseHeader(phase)
                        intentSection(phase)
                        stepsSection(phase)
                        if !phase.reviewNotes.isEmpty {
                            reviewNotesSection(phase)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Phase \(String(format: "%04d", phase.number))")
            } else {
                ContentUnavailableView(
                    "No Phase Selected",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Select a phase from the list to view its details.")
                )
            }
        }
    }

    private func phaseHeader(_ phase: Phase) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(phase.title)
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                statusBadge(phase.status)
                Text("Phase \(String(format: "%04d", phase.number))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statusBadge(_ status: PhaseStatus) -> some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon(status))
                .font(.caption)
            Text(statusLabel(status))
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor(status).opacity(0.2))
        .foregroundStyle(statusColor(status))
        .clipShape(Capsule())
    }

    private func intentSection(_ phase: Phase) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intent")
                .font(.headline)
            Markdown(phase.intent)
                .padding(.leading, 8)
        }
    }

    private func stepsSection(_ phase: Phase) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Steps")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(phase.steps) { step in
                    stepRow(step)
                }
            }
            .padding(.leading, 8)
        }
    }

    private func stepRow(_ step: PhaseStep) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: stepIcon(step))
                .foregroundStyle(stepColor(step))
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.summary)
                    .font(.body)

                HStack(spacing: 4) {
                    Text(step.id)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if step.implemented {
                        Text("• Implemented")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    if step.reviewed {
                        Text("• Reviewed")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }

    private func reviewNotesSection(_ phase: Phase) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Review")
                .font(.headline)
            Markdown(phase.reviewNotes)
                .padding(.leading, 8)
        }
    }

    private func statusIcon(_ status: PhaseStatus) -> String {
        switch status {
        case .planned:
            return "circle"
        case .active:
            return "circle.inset.filled"
        case .green:
            return "checkmark.circle.fill"
        case .yellow:
            return "exclamationmark.triangle.fill"
        case .red:
            return "xmark.circle.fill"
        }
    }

    private func statusLabel(_ status: PhaseStatus) -> String {
        status.rawValue.capitalized
    }

    private func statusColor(_ status: PhaseStatus) -> Color {
        switch status {
        case .planned:
            return .secondary
        case .active:
            return .blue
        case .green:
            return .green
        case .yellow:
            return .yellow
        case .red:
            return .red
        }
    }

    private func stepIcon(_ step: PhaseStep) -> String {
        if step.reviewed {
            return "checkmark.circle.fill"
        } else if step.implemented {
            return "circle.inset.filled"
        } else {
            return "circle"
        }
    }

    private func stepColor(_ step: PhaseStep) -> Color {
        if step.reviewed {
            return .blue
        } else if step.implemented {
            return .green
        } else {
            return .secondary
        }
    }
}
