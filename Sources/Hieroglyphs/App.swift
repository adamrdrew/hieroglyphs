import SwiftUI

@main
struct HieroglyphsApp: App {
    @State private var viewModel: HieroglyphsVM
    private let workspaceService: WorkspaceProviding

    init() {
        let service = WorkspaceService()
        self.workspaceService = service
        let vm = HieroglyphsVM(workspaceService: service)
        _viewModel = State(initialValue: vm)
    }

    var body: some Scene {
        Window("Hieroglyphs", id: "main") {
            MainWindow()
                .environment(viewModel)
                .environment(\.workspaceService, workspaceService)
                .onAppear {
                    viewModel.loadWorkspace()
                }
        }
    }
}
