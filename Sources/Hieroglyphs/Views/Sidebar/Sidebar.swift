import SwiftUI

/// Displays the project list in the sidebar with selection support.
///
/// Shows all projects from the workspace with card count summaries.
/// Supports project selection and provides a New Project button.
struct Sidebar: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.workspaceService) private var workspaceService

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
                List(selection: $bindableViewModel.selectedProject) {
                    ForEach(viewModel.projects) { project in
                        if let workspacePath = viewModel.workspacePath {
                            SidebarProjectEntry(
                                project: project,
                                workspacePath: workspacePath,
                                workspaceService: workspaceService
                            )
                            .tag(project)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .toolbar {
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
    }
}
