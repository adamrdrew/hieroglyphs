import SwiftUI

/// Middle column view displaying phases from a project's source directory.
struct PhaseList: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            if viewModel.selectedProject?.sourceDirectory == nil {
                noSourceDirectoryState
            } else if viewModel.phases.isEmpty {
                noPhasesState
            } else {
                List(selection: $bindableViewModel.selectedPhase) {
                    ForEach(viewModel.phases) { phase in
                        PhaseListEntry(phase: phase)
                            .tag(phase)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onChange(of: viewModel.selectedProject, initial: true) { _, _ in
            viewModel.loadPhases()
        }
    }

    private var noSourceDirectoryState: some View {
        ContentUnavailableView(
            "No Source Directory Configured",
            systemImage: "folder.badge.questionmark",
            description: Text("Configure a source directory to view Ushabti phases.")
        )
    }

    private var noPhasesState: some View {
        ContentUnavailableView(
            "No Ushabti Phases Found",
            systemImage: "list.bullet.rectangle",
            description: Text("No phases exist in the .ushabti/phases/ directory.")
        )
    }
}
