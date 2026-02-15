import SwiftUI

/// Displays a "Cards" section item with card count summary.
///
/// Loads cards for the project and displays count grouped by status.
struct SidebarCardsItem: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    let project: Project
    let workspacePath: String
    let workspaceService: WorkspaceProviding

    @State private var onAppearCardCounts: [CardStatus: Int] = [:]

    var body: some View {
        VStack(alignment: .leading) {
            Label("Cards", systemImage: "lanyardcard")

            if !cardCountSummary.isEmpty {
                Text(cardCountSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            loadCardCounts()
        }
    }

    private var cardCounts: [CardStatus: Int] {
        if let selectedProject = viewModel.selectedProject,
           selectedProject.id == project.id {
            var counts: [CardStatus: Int] = [:]
            for card in viewModel.cards {
                counts[card.status, default: 0] += 1
            }
            return counts
        } else {
            return onAppearCardCounts
        }
    }

    private var cardCountSummary: String {
        let nonZeroCounts = cardCounts
            .filter { $0.value > 0 }
            .sorted { first, second in
                statusOrder(first.key) < statusOrder(second.key)
            }

        return nonZeroCounts
            .map { status, count in
                let label = formatStatusLabel(status)
                return "\(count) \(label)"
            }
            .joined(separator: " • ")
    }

    private func loadCardCounts() {
        do {
            let projectPath = "\(workspacePath)/\(project.slug)"
            let cards = try workspaceService.loadCards(
                from: projectPath,
                for: project
            )

            var counts: [CardStatus: Int] = [:]
            for card in cards {
                counts[card.status, default: 0] += 1
            }

            onAppearCardCounts = counts
        } catch {
            print("Failed to load cards for project \(project.slug): \(error)")
        }
    }

    private func formatStatusLabel(_ status: CardStatus) -> String {
        return status.rawValue.replacingOccurrences(of: "-", with: " ")
    }

    private func statusOrder(_ status: CardStatus) -> Int {
        switch status {
        case .backlog: return 0
        case .triage: return 1
        case .todo: return 2
        case .inProgress: return 3
        case .done: return 4
        case .archived: return 5
        }
    }
}

/// Displays the project list in the sidebar with selection support.
///
/// Shows all projects from the workspace with card count summaries.
/// Supports project selection and provides a New Project button.
struct Sidebar: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.workspaceService) private var workspaceService
    @State private var projectPendingDeletion: Project?

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            if viewModel.projects.isEmpty {
                ContentUnavailableView(
                    "No Projects",
                    systemImage: "folder",
                    description: Text("Create a project to get started.")
                )
            } else {
                List(selection: $bindableViewModel.selectedSection) {
                    ForEach(viewModel.projects) { project in
                        if let workspacePath = viewModel.workspacePath {
                            DisclosureGroup {
                                Label("Overview", systemImage: "folder.badge.gearshape")
                                    .tag(SidebarSection.overview(project))

                                SidebarCardsItem(
                                    project: project,
                                    workspacePath: workspacePath,
                                    workspaceService: workspaceService
                                )
                                .tag(SidebarSection.cards(project))

                                Label("Plans", systemImage: "flowchart")
                                    .tag(SidebarSection.plans(project))

                                Label("Phases", systemImage: "list.number")
                                    .tag(SidebarSection.phases(project))

                                if project.sourceDirectory != nil {
                                    SidebarPharaohItem(project: project)
                                }
                            } label: {
                                SidebarProjectEntry(
                                    project: project,
                                    workspacePath: workspacePath,
                                    workspaceService: workspaceService
                                )
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .toolbar {
            if let selectedProject = viewModel.selectedProject {
                ToolbarItem(placement: .automatic) {
                    Button(role: .destructive) {
                        projectPendingDeletion = selectedProject
                    } label: {
                        Label("Delete Project", systemImage: "trash")
                    }
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showNewProjectSheet()
                } label: {
                    Label("New Project", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $bindableViewModel.showingNewProjectSheet) {
            NewProjectSheet()
        }
        .alert(
            "Delete Project",
            isPresented: Binding(
                get: { projectPendingDeletion != nil },
                set: { if !$0 { projectPendingDeletion = nil } }
            ),
            presenting: projectPendingDeletion
        ) { project in
            Button("Cancel", role: .cancel) {
                projectPendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.deleteProject(project)
                projectPendingDeletion = nil
            }
        } message: { project in
            Text("Are you sure you want to delete '\(project.title)'? This will move the project and all its cards to Trash.")
        }
    }
}
