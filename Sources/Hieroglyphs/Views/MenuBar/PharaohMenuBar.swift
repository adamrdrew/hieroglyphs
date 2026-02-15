import SwiftUI

/// Menu bar extra displaying running Pharaoh plans.
///
/// Shows list of all plans with inProgress status across all projects.
/// When no plans are running, displays empty state message.
/// Polls projects every 3 seconds to keep running plans list current.
struct PharaohMenuBar: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.planService) private var planService
    @Environment(\.pharaohService) private var pharaohService

    @State private var runningPlans: [(project: Project, plan: Plan, turns: Int?, cost: Double?)] = []

    var body: some View {
        if runningPlans.isEmpty {
            Text("No Devel Jobs Running")
                .foregroundStyle(.secondary)
        } else {
            ForEach(runningPlans, id: \.plan.id) { item in
                PharaohMenuBarEntry(
                    project: item.project,
                    plan: item.plan,
                    turns: item.turns,
                    cost: item.cost
                )
            }
        }
        .onAppear {
            loadRunningPlans()
        }
        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in
            loadRunningPlans()
        }
    }

    /// Loads all running plans across all projects.
    ///
    /// Iterates projects, calls planService.loadPlans for each with sourceDirectory,
    /// filters to inProgress plans, enriches with Pharaoh stats if available.
    /// Only assigns state when running plan count changes (prevents unnecessary redraws).
    private func loadRunningPlans() {
        guard let planService, let pharaohService else { return }

        var plans: [(project: Project, plan: Plan, turns: Int?, cost: Double?)] = []

        for project in viewModel.projects {
            guard let sourceDirectory = project.sourceDirectory,
                  let workspacePath = viewModel.workspacePath else {
                continue
            }

            let projectPath = "\(workspacePath)/\(project.slug)"

            guard let projectPlans = try? planService.loadPlans(projectPath: projectPath) else {
                continue
            }

            let inProgressPlans = projectPlans.filter { $0.status == .inProgress }

            // Try to enrich with Pharaoh stats
            for plan in inProgressPlans {
                let status = pharaohService.readStatus(from: sourceDirectory)

                var turns: Int? = nil
                var cost: Double? = nil

                if case .busy(_, let turnsElapsed, let runningCostUsd, _) = status {
                    turns = turnsElapsed
                    cost = runningCostUsd
                }

                plans.append((project: project, plan: plan, turns: turns, cost: cost))
            }
        }

        // Only assign if count changed (polling pattern)
        if plans.count != runningPlans.count {
            runningPlans = plans
        }
    }
}
