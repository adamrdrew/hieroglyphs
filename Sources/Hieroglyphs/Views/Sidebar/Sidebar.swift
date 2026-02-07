import SwiftUI

/// Displays the project list in the sidebar with selection support.
///
/// Shows all projects from the workspace with card count summaries.
/// Supports project selection and provides a New Project button.
struct Sidebar: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.workspaceService) private var workspaceService

    @State private var showingNewProjectSheet = false

    var body: some View {
        @Bindable var bindableViewModel = viewModel

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewProjectSheet = true
                } label: {
                    Label("New Project", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheet()
        }
    }
}
