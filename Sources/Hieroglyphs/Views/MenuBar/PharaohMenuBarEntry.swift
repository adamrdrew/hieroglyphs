import SwiftUI

/// Individual row view for a running plan in menu bar dropdown.
///
/// Displays project name, plan title, and enriched stats (turns, cost).
/// Clicking navigates to Pharaoh view for the plan's project.
struct PharaohMenuBarEntry: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let project: Project
    let plan: Plan
    let turns: Int?
    let cost: Double?

    var body: some View {
        Button {
            // Verify project still exists before navigating
            guard viewModel.projects.contains(where: { $0.id == project.id }) else {
                print("Warning: Cannot navigate to deleted project \(project.slug)")
                dismiss()
                return
            }

            viewModel.selectSection(.pharaoh(project))
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.headline)

                Text(project.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let turns = turns, let cost = cost {
                    Text("Turn \(turns) • $\(String(format: "%.4f", cost))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
