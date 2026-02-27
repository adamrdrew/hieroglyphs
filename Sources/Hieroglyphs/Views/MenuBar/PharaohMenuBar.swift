import SwiftUI

/// Menu bar extra displaying running Pharaoh plans.
///
/// Shows list of all plans with inProgress status across all projects.
/// When no plans are running, displays empty state message.
/// Polls projects every 3 seconds to keep running plans list current.
/// Detects status transitions (busy→done, busy→blocked) and sends
/// macOS notifications via NotificationService.
struct PharaohMenuBar: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.planService) private var planService
    @Environment(\.pharaohService) private var pharaohService
    @Environment(\.notificationService) private var notificationService

    @State private var runningPlans: [(project: Project, plan: Plan, turns: Int?, cost: Double?)] = []
    /// Tracks the previous Pharaoh status per source directory for transition detection.
    @State private var previousStatuses: [String: PharaohStatus] = [:]

    var body: some View {
        Group {
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
    /// Detects Pharaoh status transitions and sends notifications.
    /// Only assigns state when running plan count changes (prevents unnecessary redraws).
    private func loadRunningPlans() {
        guard let pharaohService else { return }

        var plans: [(project: Project, plan: Plan, turns: Int?, cost: Double?)] = []
        var visitedDirectories: Set<String> = []

        for project in viewModel.projects {
            guard let sourceDirectory = project.sourceDirectory,
                  let workspacePath = viewModel.workspacePath else {
                continue
            }

            let projectPath = "\(workspacePath)/\(project.slug)"

            guard let projectPlans = try? planService.loadPlans(projectPath: projectPath) else {
                continue
            }

            visitedDirectories.insert(sourceDirectory)
            let currentStatus = pharaohService.readStatus(from: sourceDirectory)
            let previous = previousStatuses[sourceDirectory]

            // Detect status transitions and send notifications
            checkForTransition(
                from: previous,
                to: currentStatus,
                project: project,
                sourceDirectory: sourceDirectory
            )

            previousStatuses[sourceDirectory] = currentStatus

            let inProgressPlans = projectPlans.filter { $0.status == .inProgress }

            // Try to enrich with Pharaoh stats
            for plan in inProgressPlans {
                var turns: Int? = nil
                var cost: Double? = nil

                if case .busy(_, let turnsElapsed, let runningCostUsd, _) = currentStatus {
                    turns = turnsElapsed
                    cost = runningCostUsd
                }

                plans.append((project: project, plan: plan, turns: turns, cost: cost))
            }
        }

        // Prune stale entries for removed projects
        for key in previousStatuses.keys where !visitedDirectories.contains(key) {
            previousStatuses.removeValue(forKey: key)
        }

        // Assign if content changed (count, plan IDs, turns, or cost)
        let changed = plans.count != runningPlans.count
            || zip(plans, runningPlans).contains { new, old in
                new.plan.id != old.plan.id
                    || new.turns != old.turns
                    || new.cost != old.cost
            }
        if changed {
            runningPlans = plans
        }
    }

    /// Checks for a meaningful Pharaoh status transition and fires a notification.
    ///
    /// Only fires on busy→done and busy→blocked transitions. All other transitions
    /// (idle→busy, notRunning→idle, etc.) are normal lifecycle events that don't
    /// warrant interrupting the user.
    private func checkForTransition(
        from previous: PharaohStatus?,
        to current: PharaohStatus,
        project: Project,
        sourceDirectory: String
    ) {
        guard let notificationService else { return }

        detectPharaohTransition(
            from: previous,
            to: current,
            projectName: project.title,
            notifier: notificationService
        )
    }
}
