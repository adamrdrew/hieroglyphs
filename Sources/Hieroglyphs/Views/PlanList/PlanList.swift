import SwiftUI

/// Middle column view displaying plans for a project.
struct PlanList: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @State private var showingNewPlanSheet: Bool = false

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            if viewModel.selectedProject == nil {
                noProjectState
            } else if viewModel.plans.isEmpty {
                noPlanState
            } else {
                List(selection: $bindableViewModel.selectedPlan) {
                    ForEach(viewModel.plans) { plan in
                        PlanListEntry(plan: plan)
                            .tag(plan)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onChange(of: viewModel.selectedProject, initial: true) { _, _ in
            viewModel.loadPlans()
            viewModel.loadCards()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewPlanSheet = true
                } label: {
                    Label("New Plan", systemImage: "plus")
                }
                .disabled(viewModel.selectedProject == nil)
            }
        }
        .sheet(isPresented: $showingNewPlanSheet) {
            NewPlanSheet()
        }
    }

    private var noProjectState: some View {
        ContentUnavailableView(
            "No Project Selected",
            systemImage: "folder",
            description: Text("Select a project from the sidebar to view its plans.")
        )
    }

    private var noPlanState: some View {
        ContentUnavailableView(
            "No Plans",
            systemImage: "list.bullet.clipboard",
            description: Text("Create a plan to group cards into a bounded unit of work.")
        )
    }
}
