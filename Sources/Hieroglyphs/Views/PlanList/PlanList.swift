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
                    ForEach(filteredPlans) { plan in
                        PlanListEntry(plan: plan)
                            .tag(plan)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onChange(of: viewModel.selectedProject, initial: true) { _, _ in
            viewModel.showDonePlans = false
            viewModel.loadPlans()
            viewModel.loadCards()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    viewModel.showDonePlans.toggle()
                } label: {
                    Label(
                        viewModel.showDonePlans ? "Hide Done" : "Show Done",
                        systemImage: viewModel.showDonePlans ? "eye" : "eye.slash"
                    )
                }
                .help(viewModel.showDonePlans ? "Hide done plans" : "Show done plans")
            }

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
            NewPlanSheet(sourceCard: .constant(nil))
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

    private var filteredPlans: [Plan] {
        if viewModel.showDonePlans {
            return viewModel.plans
        } else {
            return viewModel.plans.filter { $0.status != .done }
        }
    }
}
