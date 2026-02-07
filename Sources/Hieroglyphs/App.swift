import SwiftUI

@main
struct HieroglyphsApp: App {
    @State private var viewModel: HieroglyphsVM
    private let workspaceService: WorkspaceProviding
    private let fileWatcher: FileWatching

    init() {
        let service = WorkspaceService()
        let watcher = FileWatcherService()
        self.workspaceService = service
        self.fileWatcher = watcher
        let vm = HieroglyphsVM(workspaceService: service, fileWatcher: watcher)
        _viewModel = State(initialValue: vm)
    }

    var body: some Scene {
        Window("Hieroglyphs", id: "main") {
            MainWindow()
                .environment(viewModel)
                .environment(\.workspaceService, workspaceService)
                .environment(\.fileWatcher, fileWatcher)
                .onAppear {
                    viewModel.loadWorkspace()
                }
        }
    }
}
